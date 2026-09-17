"""
TuyaManager — local-first / cloud-fallback command & status orchestration
for Tuya devices, sitting on top of the existing LAN (tinytuya.Device) and
Cloud (tinytuya.Cloud) primitives already in routers/tuya.py. This module
owns *which* driver to use and when; routers/tuya.py's blocking helpers
still own the actual protocol calls — nothing here talks to tinytuya
directly.

Connection modes (per device, stored in devices.config.connection_mode,
default "local_first" when absent — see routers/tuya.py's
/connection-mode/{id} endpoints):
  local_first  - try local, fall back to cloud on failure (default)
  cloud_first  - try cloud, fall back to local on failure
  local_only   - local only, never fall back
  cloud_only   - cloud only, never fall back

Retry policy for the local attempt: a short, configurable backoff sequence
(RETRY_DELAYS_MS) before giving up — a single flaky UDP round-trip on the
LAN shouldn't force a cloud round-trip when a quick retry would have
worked. Cloud isn't retried the same way (HTTP over the internet doesn't
have the same "just resend the UDP packet" failure mode, and retrying an
already-slow cloud call just compounds the latency) — it either fails and
the mode's fallback rule takes over, or it doesn't.
"""
import asyncio
import os
from typing import Optional

from secret_store import decrypt_field

LOCAL_COMMAND_TIMEOUT_MS = 2500
LOCAL_STATUS_TIMEOUT_MS = 2500
CLOUD_TIMEOUT_MS = 8000
RETRY_DELAYS_MS = [100, 300]  # 2 retries after the first attempt = 3 tries total

VALID_MODES = {"local_first", "cloud_first", "local_only", "cloud_only"}

# ── Background polling (below) ──────────────────────────────────────────────
POLL_INTERVAL_SECONDS = int(os.getenv("TUYA_POLL_INTERVAL_SECONDS", "30"))
POLL_STAGGER_SECONDS = 0.5  # gap between devices within one cycle, so a LAN
                             # with several Tuya devices isn't hit with a
                             # burst of simultaneous UDP round-trips


def normalize_mode(mode: Optional[str]) -> str:
    return mode if mode in VALID_MODES else "local_first"


async def resolve_cloud_creds() -> Optional[dict]:
    """Decrypted, in-memory-only — never returned from an endpoint as-is.
    The single shared place that turns the persisted (encrypted) Tuya Cloud
    credentials into what execute_command()/get_status() need; both
    routers/tuya.py's REST endpoints and handle_device_cmd() (the MQTT
    path, below) go through this instead of each keeping their own copy."""
    from database import get_tuya_cloud_creds
    creds = await get_tuya_cloud_creds()
    if not creds:
        return None
    return {
        "region": creds["region"],
        "access_id": creds["access_id"],
        "access_secret": decrypt_field(creds["access_secret"]),
    }


class TuyaResult:
    """Uniform result shape for control/status/test — always says which
    driver actually served the request, so callers (and the UI) can show
    "🟠 Local" vs "☁ Cloud" instead of just success/failure."""

    def __init__(self, ok: bool, via: str, data: Optional[dict] = None, error: Optional[str] = None):
        self.ok = ok
        self.via = via  # "local" | "cloud" | "none"
        self.data = data or {}
        self.error = error

    def to_dict(self) -> dict:
        d = {"ok": self.ok, "via": self.via, **self.data}
        if self.error:
            d["error"] = self.error
        return d


def _device_local_args(device: dict):
    config = device.get("config") or {}
    ip = config.get("tuya_ip", "")
    device_id = config.get("tuya_device_id", "")
    local_key = decrypt_field(config.get("tuya_local_key", ""))
    version = config.get("tuya_version", 3.3)
    return ip, device_id, local_key, version


async def _run_with_timeout(loop, fn, args, timeout_ms: int):
    return await asyncio.wait_for(
        loop.run_in_executor(None, fn, *args),
        timeout=timeout_ms / 1000,
    )


async def _local_control(loop, device: dict, payload: dict) -> TuyaResult:
    from routers.tuya import _control_device_blocking  # local import: avoids a circular import at module load
    ip, device_id, local_key, version = _device_local_args(device)
    if not (ip and device_id and local_key):
        return TuyaResult(False, "local", error="device is missing ip/device_id/local_key")

    last_error = "unknown local error"
    for delay_ms in [0] + RETRY_DELAYS_MS:
        if delay_ms:
            await asyncio.sleep(delay_ms / 1000)
        try:
            result = await _run_with_timeout(
                loop, _control_device_blocking, (ip, device_id, local_key, payload, version),
                timeout_ms=LOCAL_COMMAND_TIMEOUT_MS,
            )
            if result.get("ok"):
                return TuyaResult(True, "local")
            last_error = result.get("error", last_error)
        except asyncio.TimeoutError:
            last_error = f"local command timed out after {LOCAL_COMMAND_TIMEOUT_MS}ms"
        except Exception as e:
            last_error = str(e)
    return TuyaResult(False, "local", error=last_error)


async def _local_status(loop, device: dict) -> TuyaResult:
    from routers.tuya import _get_status_blocking
    ip, device_id, local_key, _ = _device_local_args(device)
    if not (ip and device_id and local_key):
        return TuyaResult(False, "local", error="device is missing ip/device_id/local_key")
    try:
        status = await _run_with_timeout(
            loop, _get_status_blocking, (ip, device_id, local_key),
            timeout_ms=LOCAL_STATUS_TIMEOUT_MS,
        )
        if "error" in status and not status.get("dps"):
            return TuyaResult(False, "local", error=status["error"])
        return TuyaResult(True, "local", data=status)
    except asyncio.TimeoutError:
        return TuyaResult(False, "local", error=f"local status read timed out after {LOCAL_STATUS_TIMEOUT_MS}ms")
    except Exception as e:
        return TuyaResult(False, "local", error=str(e))


async def _cloud_control(loop, device: dict, payload: dict, cloud_creds: Optional[dict]) -> TuyaResult:
    from routers.tuya import _cloud_control_blocking
    if not cloud_creds:
        return TuyaResult(False, "cloud", error="no Tuya Cloud credentials configured (see /api/tuya/cloud-credentials)")
    device_id = (device.get("config") or {}).get("tuya_device_id", "")
    if not device_id:
        return TuyaResult(False, "cloud", error="device is missing tuya_device_id")
    try:
        result = await _run_with_timeout(
            loop, _cloud_control_blocking,
            (cloud_creds["region"], cloud_creds["access_id"], cloud_creds["access_secret"], device_id, payload),
            timeout_ms=CLOUD_TIMEOUT_MS,
        )
        if result.get("ok"):
            return TuyaResult(True, "cloud")
        return TuyaResult(False, "cloud", error=result.get("error", "unknown cloud error"))
    except asyncio.TimeoutError:
        return TuyaResult(False, "cloud", error=f"cloud command timed out after {CLOUD_TIMEOUT_MS}ms")
    except Exception as e:
        return TuyaResult(False, "cloud", error=str(e))


async def _cloud_status(loop, device: dict, cloud_creds: Optional[dict]) -> TuyaResult:
    from routers.tuya import _cloud_status_blocking
    if not cloud_creds:
        return TuyaResult(False, "cloud", error="no Tuya Cloud credentials configured (see /api/tuya/cloud-credentials)")
    device_id = (device.get("config") or {}).get("tuya_device_id", "")
    if not device_id:
        return TuyaResult(False, "cloud", error="device is missing tuya_device_id")
    try:
        status = await _run_with_timeout(
            loop, _cloud_status_blocking,
            (cloud_creds["region"], cloud_creds["access_id"], cloud_creds["access_secret"], device_id),
            timeout_ms=CLOUD_TIMEOUT_MS,
        )
        if "error" in status:
            return TuyaResult(False, "cloud", error=status["error"])
        return TuyaResult(True, "cloud", data=status)
    except asyncio.TimeoutError:
        return TuyaResult(False, "cloud", error=f"cloud status read timed out after {CLOUD_TIMEOUT_MS}ms")
    except Exception as e:
        return TuyaResult(False, "cloud", error=str(e))


async def execute_command(device: dict, payload: dict, cloud_creds: Optional[dict] = None) -> TuyaResult:
    """device: a hub device dict (database.get_device()'s shape), whose
    config carries tuya_device_id/tuya_ip/tuya_local_key(encrypted)/
    tuya_version/connection_mode. cloud_creds: {"region", "access_id",
    "access_secret"} (plaintext access_secret — decrypt before calling
    this), or None if no Tuya Cloud account is configured on this hub."""
    mode = normalize_mode((device.get("config") or {}).get("connection_mode"))
    loop = asyncio.get_running_loop()

    if mode == "local_only":
        return await _local_control(loop, device, payload)
    if mode == "cloud_only":
        return await _cloud_control(loop, device, payload, cloud_creds)
    if mode == "cloud_first":
        result = await _cloud_control(loop, device, payload, cloud_creds)
        return result if result.ok else await _local_control(loop, device, payload)
    # local_first (default)
    result = await _local_control(loop, device, payload)
    return result if result.ok else await _cloud_control(loop, device, payload, cloud_creds)


async def get_status(device: dict, cloud_creds: Optional[dict] = None) -> TuyaResult:
    mode = normalize_mode((device.get("config") or {}).get("connection_mode"))
    loop = asyncio.get_running_loop()

    if mode == "local_only":
        return await _local_status(loop, device)
    if mode == "cloud_only":
        return await _cloud_status(loop, device, cloud_creds)
    if mode == "cloud_first":
        result = await _cloud_status(loop, device, cloud_creds)
        return result if result.ok else await _local_status(loop, device)
    # local_first (default)
    result = await _local_status(loop, device)
    return result if result.ok else await _cloud_status(loop, device, cloud_creds)


async def get_connection_status(device: dict, cloud_creds: Optional[dict] = None) -> str:
    """One of: online_local | online_cloud | offline | unsupported.
    ("connecting"/"unknown" are UI-transient states the hub has no reason
    to report from a point-in-time check — they belong to whatever is
    polling this, not to a single request/response.)"""
    config = device.get("config") or {}
    if not config.get("tuya_device_id"):
        return "unsupported"
    result = await get_status(device, cloud_creds)
    if not result.ok:
        return "offline"
    return "online_local" if result.via == "local" else "online_cloud"


async def get_diagnostics(device: dict, cloud_creds: Optional[dict] = None) -> dict:
    """Never includes secrets, even masked — there's nothing secret-shaped
    in this response to begin with.

    commandTest deliberately does NOT send a real state-changing command —
    flipping a switch just to answer "can I control this?" would be a
    surprising side effect of what's supposed to be a read-only diagnostics
    check. It reuses the same signal as stateRead (a successful local
    round-trip proves the device accepts authenticated local requests,
    which is what actually gates control) instead.
    """
    import socket
    config = device.get("config") or {}
    ip = config.get("tuya_ip", "")
    ip_reachable = False
    if ip:
        try:
            with socket.create_connection((ip, 6668), timeout=1.5):
                ip_reachable = True
        except OSError:
            ip_reachable = False

    local_result = await get_status(
        {**device, "config": {**config, "connection_mode": "local_only"}}
    )
    cloud_result = (
        await get_status({**device, "config": {**config, "connection_mode": "cloud_only"}}, cloud_creds)
        if cloud_creds else TuyaResult(False, "cloud", error="not configured")
    )

    return {
        "network": ip_reachable or cloud_result.ok,
        "ipReachable": ip_reachable,
        "protocolDetected": bool(config.get("tuya_version")),
        "authentication": local_result.ok or cloud_result.ok,
        "localConnection": local_result.ok,
        "stateRead": local_result.ok or cloud_result.ok,
        "commandTest": local_result.ok,
        "cloudConnection": cloud_result.ok,
    }


# In-memory only — this is a live/transient signal (what actually served
# the last request), not history, so it doesn't need to survive a hub
# restart. Shared between handle_device_cmd() and the poll loop so neither
# re-broadcasts a connection status the other one already reported.
_last_connection: dict = {}


def _connection_from_result(result: TuyaResult) -> str:
    if not result.ok:
        return "offline"
    return "online_local" if result.via == "local" else "online_cloud"


async def _broadcast_connection_if_changed(device_id: str, connection: str, ok: bool):
    if _last_connection.get(device_id) == connection:
        return
    _last_connection[device_id] = connection
    from ws_manager import manager
    await manager.broadcast("device_connection", {
        "id": device_id, "connection": connection, "ok": ok,
    })


async def handle_device_cmd(device_id: str, payload: dict) -> Optional[TuyaResult]:
    """Entry point for the generic devices/{id}/cmd MQTT topic (see
    main.py's on_mqtt_message) — the same topic rule_engine.py's
    automations already publish to by default, and the same topic
    /api/devices/{id}/cmd and /toggle publish to. Before this, nothing
    subscribed to that topic on Tuya devices' behalf, so an automation or
    the generic toggle endpoint silently did nothing for them; wifi/zigbee
    devices are unaffected — their own bridge processes already own this
    topic for their devices independently, MQTT allows multiple
    subscribers.

    Returns None (not "this device, but it failed") when device_id isn't a
    Tuya-protocol device at all, so main.py knows this wasn't its topic to
    handle.
    """
    from database import get_device
    from mqtt_client import publish

    device = await get_device(device_id)
    if not device or device.get("protocol") != "tuya":
        return None

    cloud_creds = await resolve_cloud_creds()
    result = await execute_command(device, payload, cloud_creds)
    if result.ok:
        # Republish as the generic devices/{id}/state topic so the existing
        # state-update handler (DB write + WebSocket broadcast) picks it up
        # exactly like it would for a real bridge-reported state change —
        # no separate DB/broadcast code needed here.
        publish(f"devices/{device_id}/state", payload)
    else:
        print(f"[TuyaManager] Command failed for {device_id} via {result.via}: {result.error}")
    await _broadcast_connection_if_changed(device_id, _connection_from_result(result), result.ok)
    return result


# Poll-to-poll comparison baseline, kept separate from devices.state.
# get_status()'s local path returns raw {"dps": {"1": true, ...}} (DP
# number -> value); handle_device_cmd() writes devices.state as the
# command's own payload shape instead (e.g. {"state": "ON"}), since there's
# no DatapointMapper yet to translate between the two vocabularies (see the
# tuya skill's DatapointMapper note). Diffing a poll result against
# devices.state would therefore look "changed" on every single poll after
# the first command a device ever received — comparing against the
# previous poll's own raw dps instead avoids that false-positive entirely.
_last_poll_state: dict = {}


async def _poll_once():
    """One pass over every Tuya device: read status (respecting each
    device's own connection_mode) and broadcast/persist only what actually
    changed. Never raises — a single device's failure is logged and
    skipped so it can't take the whole loop down."""
    from database import get_all_devices, update_device_state

    cloud_creds = await resolve_cloud_creds()
    devices = [d for d in await get_all_devices() if d.get("protocol") == "tuya"]

    for device in devices:
        device_id = device.get("id", "")
        try:
            config = device.get("config") or {}
            if not config.get("tuya_device_id"):
                continue  # nothing to poll — no local or cloud identity at all

            result = await get_status(device, cloud_creds)
            was_online = bool(device.get("online"))
            state_changed = result.ok and result.data and result.data != _last_poll_state.get(device_id)

            if result.ok != was_online or state_changed:
                new_state = result.data if (result.ok and result.data) else (device.get("state") or {})
                await update_device_state(device_id, new_state, online=result.ok)
                from ws_manager import manager
                await manager.broadcast("device_state", {
                    "id": device_id, "state": new_state, "online": result.ok,
                })
            if result.ok and result.data:
                _last_poll_state[device_id] = result.data

            await _broadcast_connection_if_changed(
                device_id, _connection_from_result(result), result.ok
            )
        except Exception as e:
            print(f"[TuyaManager] Poll failed for {device_id}: {e}")

        await asyncio.sleep(POLL_STAGGER_SECONDS)


async def poll_loop(interval_seconds: int = POLL_INTERVAL_SECONDS):
    """Runs until cancelled — start with asyncio.create_task() at hub
    startup (see main.py's startup()/shutdown()). Sleeps interval_seconds
    *after* each full pass rather than on a fixed wall-clock schedule, so a
    slow cycle (many devices, several offline and timing out) can never
    overlap with the next one instead of piling up concurrent polls."""
    print(f"[TuyaManager] Background poll loop started (every {interval_seconds}s)")
    while True:
        try:
            await _poll_once()
        except asyncio.CancelledError:
            raise
        except Exception as e:
            print(f"[TuyaManager] Poll cycle error: {e}")
        await asyncio.sleep(interval_seconds)
