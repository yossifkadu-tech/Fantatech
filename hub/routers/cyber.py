"""
Cyber Security Router — network & device vulnerability assessment.
Endpoints:
  GET /api/cyber/scan          → full security scan (score, threats, recommendations)
  GET /api/cyber/devices-audit → per-device vulnerability check
"""
import asyncio
import socket
import platform
import subprocess
import re
from fastapi import APIRouter

router = APIRouter()

# ── helpers ──────────────────────────────────────────────────────────────────

async def _tcp_open(ip: str, port: int, timeout: float = 0.6) -> bool:
    try:
        _, writer = await asyncio.wait_for(
            asyncio.open_connection(ip, port), timeout=timeout
        )
        try:
            writer.close()
            await writer.wait_closed()
        except Exception:
            pass
        return True
    except Exception:
        return False


async def _http_get(url: str, timeout: float = 2.0) -> tuple[int, str]:
    """Return (status_code, body_snippet). Returns (0, '') on error."""
    try:
        import aiohttp
        async with aiohttp.ClientSession(
            timeout=aiohttp.ClientTimeout(total=timeout),
            connector=aiohttp.TCPConnector(ssl=False),
        ) as sess:
            async with sess.get(url) as r:
                text = await r.text(errors="replace")
                return r.status, text[:2000]
    except ImportError:
        # aiohttp not available – try httpx
        try:
            import httpx
            async with httpx.AsyncClient(timeout=timeout, verify=False) as client:
                r = await client.get(url)
                return r.status_code, r.text[:2000]
        except Exception:
            return 0, ""
    except Exception:
        return 0, ""


def _get_gateway() -> str | None:
    try:
        if platform.system() == "Windows":
            result = subprocess.run(
                ["route", "print", "0.0.0.0"],
                capture_output=True, text=True, timeout=4,
            )
            m = re.search(r"0\.0\.0\.0\s+0\.0\.0\.0\s+([\d.]+)", result.stdout)
            if m:
                return m.group(1)
        else:
            result = subprocess.run(
                ["ip", "route"], capture_output=True, text=True, timeout=4,
            )
            m = re.search(r"default via ([\d.]+)", result.stdout)
            if m:
                return m.group(1)
    except Exception:
        pass
    # Fallback – probe via UDP
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        parts = ip.split(".")
        return ".".join(parts[:3]) + ".1"
    except Exception:
        return None


# ── /scan ─────────────────────────────────────────────────────────────────────

@router.get("/scan")
async def cyber_scan():
    """
    Full security scan.
    Returns: { score, threats, recommendations, devices_checked, gateway }
    """
    from database import get_all_devices

    threats: list[dict] = []
    checks_passed = 0
    checks_total  = 0

    gateway = _get_gateway()

    # ── Check 1: Telnet on router ──────────────────────────────────────────
    checks_total += 1
    if gateway and await _tcp_open(gateway, 23, 0.8):
        threats.append({
            "level": "high",
            "icon":  "⚠️",
            "title": f"Telnet open on router ({gateway})",
            "detail": "Telnet transmits data in plain text. Disable it in your router's admin panel → Advanced → Remote Access.",
        })
    else:
        checks_passed += 1

    # ── Check 2: FTP on router ────────────────────────────────────────────
    checks_total += 1
    if gateway and await _tcp_open(gateway, 21, 0.8):
        threats.append({
            "level": "medium",
            "icon":  "📂",
            "title": f"FTP open on router ({gateway})",
            "detail": "FTP is unencrypted. Disable FTP server in router admin → File Sharing.",
        })
    else:
        checks_passed += 1

    # ── Check 3: UPnP / SSDP (port 1900) ─────────────────────────────────
    checks_total += 1
    if gateway and await _tcp_open(gateway, 1900, 0.8):
        threats.append({
            "level": "medium",
            "icon":  "📡",
            "title": f"UPnP enabled on router ({gateway})",
            "detail": "UPnP allows devices to open router ports automatically. Disable it under router WAN settings unless needed.",
        })
    else:
        checks_passed += 1

    # ── Check 4: WiFi devices with no auth ────────────────────────────────
    devices = get_all_devices()
    wifi_devs = [
        d for d in devices
        if d.get("protocol") == "wifi" and d.get("config", {}).get("ip")
    ]

    sem = asyncio.Semaphore(6)

    async def _audit_device(dev: dict) -> dict | None:
        ip = dev["config"]["ip"]
        async with sem:
            status, body = await _http_get(f"http://{ip}/", timeout=1.5)
            if status == 200:
                bl = body.lower()
                if "tasmota" in bl:
                    # Tasmota without password → /cm endpoint returns JSON freely
                    s2, b2 = await _http_get(f"http://{ip}/cm?cmnd=Status", 1.0)
                    if s2 == 200 and "status" in b2.lower():
                        return {
                            "level": "medium",
                            "icon":  "🔓",
                            "title": f"Device '{dev['name']}' has no password (Tasmota)",
                            "detail": f"IP {ip} — set a web password under Tasmota Configuration → Configure Other → Web Admin Password.",
                        }
                elif "shelly" in bl:
                    s2, b2 = await _http_get(f"http://{ip}/shelly", 1.0)
                    if s2 == 200:
                        return {
                            "level": "medium",
                            "icon":  "🔓",
                            "title": f"Device '{dev['name']}' has no password (Shelly)",
                            "detail": f"IP {ip} — enable authentication under Shelly Settings → Authentication.",
                        }
                elif "esphome" in bl:
                    return {
                        "level": "low",
                        "icon":  "ℹ️",
                        "title": f"Device '{dev['name']}' ESPHome dashboard open",
                        "detail": f"IP {ip} — consider enabling the dashboard_auth option in ESPHome YAML.",
                    }
        return None

    audit_tasks = [_audit_device(d) for d in wifi_devs[:12]]
    audit_results = await asyncio.gather(*audit_tasks, return_exceptions=True)

    for res in audit_results:
        checks_total += 1
        if isinstance(res, dict):
            threats.append(res)
        else:
            checks_passed += 1

    # ── Check 5: Hub runs over HTTP (informational) ────────────────────────
    checks_total += 1
    checks_passed += 1   # not a failure — it's a local-only hub
    threats.append({
        "level": "info",
        "icon":  "🏠",
        "title": "Hub uses HTTP (local network only)",
        "detail": "This is expected for a home hub. Ensure your network is password-protected.",
    })

    # ── Score ──────────────────────────────────────────────────────────────
    real_threats = [th for th in threats if th["level"] in ("high", "medium")]
    score = max(0, 100 - len([t for t in real_threats if t["level"] == "high"]) * 25
                     - len([t for t in real_threats if t["level"] == "medium"]) * 10)

    # ── Recommendations ────────────────────────────────────────────────────
    recommendations: list[str] = []
    if any(t["level"] == "high" for t in threats):
        recommendations.append("🔴 Disable Telnet on your router immediately (router admin → remote access)")
    if any("password" in t["title"].lower() or "auth" in t["title"].lower() for t in threats):
        recommendations.append("🔑 Enable web password on all Tasmota / Shelly / ESPHome devices")
    if any("upnp" in t["title"].lower() for t in threats):
        recommendations.append("📡 Disable UPnP in router WAN settings")
    recommendations += [
        "🏠 Put IoT devices on a separate VLAN or guest Wi-Fi network",
        "🔄 Keep device firmware up to date",
        "🛡️ Enable firewall on your router",
        "🔒 Use a strong Wi-Fi password (WPA3 if supported)",
    ]

    return {
        "score":            score,
        "threats":          threats,
        "recommendations":  recommendations,
        "devices_checked":  len(wifi_devs),
        "gateway":          gateway,
    }


# ── /devices-audit ────────────────────────────────────────────────────────────

@router.get("/devices-audit")
async def devices_audit():
    """Quick per-device audit. Returns list of devices with issue flags."""
    from database import get_all_devices

    devices = get_all_devices()
    sem = asyncio.Semaphore(8)

    async def _check(dev: dict) -> dict:
        ip = dev.get("config", {}).get("ip")
        issues: list[str] = []
        status = "ok"

        if dev.get("protocol") == "wifi" and ip:
            async with sem:
                code, body = await _http_get(f"http://{ip}/", timeout=1.5)
                if code == 200:
                    bl = body.lower()
                    if "tasmota" in bl:
                        c2, b2 = await _http_get(f"http://{ip}/cm?cmnd=Status", 1.0)
                        if c2 == 200 and "status" in b2.lower():
                            issues.append("No password (Tasmota)")
                            status = "warning"
                    elif "shelly" in bl:
                        issues.append("Check Shelly auth settings")
                        status = "info"
                elif code == 0:
                    status = "offline"

        return {
            "id":     dev["id"],
            "name":   dev["name"],
            "status": status,
            "issues": issues,
            "ip":     ip,
            "type":   dev.get("type", ""),
        }

    results = await asyncio.gather(*[_check(d) for d in devices], return_exceptions=True)
    clean = [r for r in results if isinstance(r, dict)]

    return {"devices": clean}
