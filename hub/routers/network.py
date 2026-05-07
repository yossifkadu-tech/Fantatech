import os
import re
import asyncio
import socket
import struct
import subprocess
import platform
import tempfile
import threading
import urllib.parse
import httpx
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from database import (
    get_wifi_profiles, save_wifi_profile, delete_wifi_profile, upsert_device,
    update_wifi_priority, update_wifi_auto_connect,
)

router = APIRouter()
IS_WIN = platform.system() == "Windows"


# ── Helpers ───────────────────────────────────────────────────────────────────

def _get_local_ip() -> str:
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "192.168.1.1"


def _arp_hosts(subnet: str) -> list[str]:
    """Return IPs already in the OS ARP table for this subnet (instant)."""
    try:
        cmd = ["arp", "-a"] if IS_WIN else ["arp", "-n"]
        r = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8",
                           errors="ignore", timeout=4)
        found = re.findall(r"\b(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\b", r.stdout)
        return [ip for ip in found
                if ip.startswith(subnet)
                and not ip.endswith(".255")
                and not ip.startswith("224.")]
    except Exception:
        return []


def _ping_sync(ip: str) -> bool:
    """Synchronous ping — safe on all Windows asyncio loop types."""
    args = ["ping", "-n", "1", "-w", "300", ip] if IS_WIN else ["ping", "-c", "1", "-W", "1", ip]
    try:
        r = subprocess.run(args, capture_output=True, timeout=2)
        return r.returncode == 0
    except Exception:
        return False


async def _tcp_alive_async(ip: str) -> bool:
    """Pure async TCP check — works on SelectorEventLoop (no threads needed).
    Tries common smart-home ports; returns True if any is open."""
    for port in (80, 8080, 443, 1883, 8123, 554):
        try:
            reader, writer = await asyncio.wait_for(
                asyncio.open_connection(ip, port), timeout=0.25
            )
            writer.close()
            try:
                await asyncio.wait_for(writer.wait_closed(), timeout=0.1)
            except Exception:
                pass
            return True
        except Exception:
            continue
    return False


async def _ping_one(ip: str, sem=None) -> bool:
    """Async ping via thread executor — avoids asyncio.create_subprocess_exec
    which fails on Windows SelectorEventLoop (uvicorn default)."""
    loop = asyncio.get_running_loop()
    if sem:
        async with sem:
            return await loop.run_in_executor(None, _ping_sync, ip)
    return await loop.run_in_executor(None, _ping_sync, ip)


async def _probe(client: httpx.AsyncClient, ip: str, hub_ip: str) -> dict | None:
    """Probe a single IP, identify device type, return info."""

    # ── Tasmota ──────────────────────────────────────────────────────────────
    try:
        r = await client.get(f"http://{ip}/cm?cmnd=Status%200", timeout=0.8)
        if r.status_code == 200:
            d   = r.json()
            st  = d.get("Status", {})
            mqt = d.get("StatusMQT", {})
            fwr = d.get("StatusFWR", {})
            already = mqt.get("MqttHost", "") == hub_ip
            return {
                "ip": ip,
                "name":        st.get("DeviceName") or st.get("FriendlyName", [ip])[0] or ip,
                "hostname":    st.get("Hostname", ip),
                "device_type": "tasmota",
                "protocol":    "wifi",
                "auto_pair":   True,
                "already_paired": already,
                "info": {
                    "firmware":    fwr.get("Version", ""),
                    "mqtt_host":   mqt.get("MqttHost", ""),
                    "mqtt_client": mqt.get("MqttClient", ""),
                },
            }
    except Exception:
        pass

    # ── Shelly ────────────────────────────────────────────────────────────────
    try:
        r = await client.get(f"http://{ip}/shelly", timeout=0.8)
        if r.status_code == 200:
            d = r.json()
            already = False
            try:
                r2 = await client.get(f"http://{ip}/settings/mqtt", timeout=0.6)
                if r2.status_code == 200:
                    already = r2.json().get("mqtt_server", "").startswith(hub_ip)
            except Exception:
                pass
            return {
                "ip": ip,
                "name":        d.get("name") or f"Shelly {d.get('type', ip.split('.')[-1])}",
                "hostname":    ip,
                "device_type": "shelly",
                "protocol":    "wifi",
                "auto_pair":   True,
                "already_paired": already,
                "info": {"type": d.get("type", ""), "mac": d.get("mac", "")},
            }
    except Exception:
        pass

    # ── ESPHome ───────────────────────────────────────────────────────────────
    try:
        r = await client.get(f"http://{ip}/", timeout=0.7)
        if r.status_code == 200 and "esphome" in r.text.lower():
            title = re.search(r"<title>(.*?)</title>", r.text, re.I)
            return {
                "ip": ip,
                "name":        title.group(1).strip() if title else ip,
                "hostname":    ip,
                "device_type": "esphome",
                "protocol":    "wifi",
                "auto_pair":   False,
                "already_paired": False,
                "info": {},
            }
    except Exception:
        pass

    # ── Generic HTTP ─────────────────────────────────────────────────────────
    try:
        r = await client.get(f"http://{ip}/", timeout=0.5)
        if r.status_code == 200:
            title = re.search(r"<title>(.*?)</title>", r.text, re.I)
            return {
                "ip": ip,
                "name":        title.group(1).strip()[:40] if title else ip,
                "hostname":    ip,
                "device_type": "http",
                "protocol":    "wifi",
                "auto_pair":   False,
                "already_paired": False,
                "info": {},
            }
    except Exception:
        pass

    return None


# ── mDNS discovery ────────────────────────────────────────────────────────────

def _scan_mdns(timeout: float = 1.5) -> list[dict]:
    """Discover devices via mDNS/Bonjour (zeroconf)."""
    found: dict[str, dict] = {}
    try:
        from zeroconf import Zeroconf, ServiceBrowser

        SERVICE_TYPES = [
            "_http._tcp.local.",
            "_https._tcp.local.",
            "_hap._tcp.local.",       # HomeKit
            "_esphome._tcp.local.",
            "_mqtt._tcp.local.",
            "_googlecast._tcp.local.", # Chromecast / Google Home
            "_smarthome._tcp.local.",
        ]

        class Listener:
            def add_service(self, zc, type_, name):
                info = zc.get_service_info(type_, name)
                if info and info.addresses:
                    ip = socket.inet_ntoa(info.addresses[0])
                    if ip not in found:
                        found[ip] = {
                            "ip": ip,
                            "name": info.server.rstrip(".") if info.server else name.split(".")[0],
                            "hostname": info.server.rstrip(".") if info.server else ip,
                            "device_type": "mdns",
                            "protocol": "wifi",
                            "auto_pair": False,
                            "already_paired": False,
                            "mdns_type": type_.rstrip("."),
                            "info": {"port": info.port, "mdns_name": name},
                        }
            def remove_service(self, *_): pass
            def update_service(self, *_): pass

        zc = Zeroconf()
        listener = Listener()
        browsers = [ServiceBrowser(zc, t, listener) for t in SERVICE_TYPES]
        threading.Event().wait(timeout)
        zc.close()
    except Exception:
        pass
    return list(found.values())


# ── SSDP / UPnP discovery ─────────────────────────────────────────────────────

def _scan_ssdp(timeout: float = 2.0) -> list[dict]:
    """Discover UPnP/SSDP devices (routers, smart TVs, Hue bridges…)."""
    SSDP_ADDR, SSDP_PORT = "239.255.255.250", 1900
    msg = (
        "M-SEARCH * HTTP/1.1\r\n"
        f"HOST: {SSDP_ADDR}:{SSDP_PORT}\r\n"
        'MAN: "ssdp:discover"\r\n'
        "MX: 2\r\nST: ssdp:all\r\n\r\n"
    ).encode()

    found: dict[str, dict] = {}
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
        sock.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_TTL, 2)
        sock.settimeout(timeout)
        sock.sendto(msg, (SSDP_ADDR, SSDP_PORT))
        while True:
            try:
                data, addr = sock.recvfrom(2048)
                ip = addr[0]
                if ip in found:
                    continue
                text = data.decode(errors="ignore")
                server  = re.search(r"SERVER:\s*(.+)", text, re.I)
                loc     = re.search(r"LOCATION:\s*(.+)", text, re.I)
                usn     = re.search(r"USN:\s*(.+)", text, re.I)
                st      = re.search(r"ST:\s*(.+)", text, re.I)
                name = (server.group(1).strip() if server else
                        usn.group(1).split("::")[0].split(":")[-1] if usn else ip)
                dev_type = "router"
                if st:
                    st_val = st.group(1).lower()
                    if "mediarenderer" in st_val or "tv" in st_val:
                        dev_type = "media"
                    elif "light" in st_val or "hue" in st_val:
                        dev_type = "light"
                found[ip] = {
                    "ip": ip,
                    "name": name[:40],
                    "hostname": ip,
                    "device_type": "ssdp",
                    "protocol": "wifi",
                    "auto_pair": False,
                    "already_paired": False,
                    "info": {
                        "ssdp_server": server.group(1).strip() if server else "",
                        "ssdp_location": loc.group(1).strip() if loc else "",
                        "ssdp_type": dev_type,
                    },
                }
            except socket.timeout:
                break
        sock.close()
    except Exception:
        pass
    return list(found.values())


# ── Default gateway detection ─────────────────────────────────────────────────

def _get_gateway() -> str | None:
    """Return the default gateway IP — tries multiple methods for reliability."""
    if IS_WIN:
        # Method 1: route print
        try:
            r = subprocess.run(["route", "print", "0.0.0.0"],
                               capture_output=True, text=True, timeout=5,
                               encoding="utf-8", errors="ignore")
            m = re.search(r"0\.0\.0\.0\s+0\.0\.0\.0\s+(\d+\.\d+\.\d+\.\d+)", r.stdout)
            if m:
                return m.group(1)
        except Exception:
            pass

        # Method 2: ipconfig (always available, works even when route fails)
        try:
            r2 = subprocess.run(["ipconfig"],
                                capture_output=True, text=True, timeout=5,
                                encoding="utf-8", errors="ignore")
            # Match "Default Gateway . . . . . . . . : 192.168.1.1"
            # Also Hebrew: "שער ברירת מחדל"
            m2 = re.search(
                r"(?:Default Gateway|שער ברירת מחדל)[.\s:]+(\d+\.\d+\.\d+\.\d+)",
                r2.stdout, re.IGNORECASE
            )
            if m2 and not m2.group(1).startswith("0."):
                return m2.group(1)
        except Exception:
            pass

        # Method 3: derive from local IP (assume .1 is gateway — common)
        try:
            local = _get_local_ip()
            parts = local.split(".")
            if len(parts) == 4:
                return f"{parts[0]}.{parts[1]}.{parts[2]}.1"
        except Exception:
            pass

    else:
        try:
            r = subprocess.run(["ip", "route", "show", "default"],
                               capture_output=True, text=True, timeout=4)
            m = re.search(r"default via (\d+\.\d+\.\d+\.\d+)", r.stdout)
            if m:
                return m.group(1)
        except Exception:
            pass
        try:
            r2 = subprocess.run(["netstat", "-rn"], capture_output=True, text=True, timeout=4)
            m2 = re.search(r"0\.0\.0\.0\s+(\d+\.\d+\.\d+\.\d+)", r2.stdout)
            if m2:
                return m2.group(1)
        except Exception:
            pass
        # Fallback: assume .1
        try:
            local = _get_local_ip()
            parts = local.split(".")
            if len(parts) == 4:
                return f"{parts[0]}.{parts[1]}.{parts[2]}.1"
        except Exception:
            pass

    return None


# ── Scan endpoint ─────────────────────────────────────────────────────────────

@router.get("/scan-devices")
async def scan_devices():
    hub_ip = _get_local_ip()
    subnet = ".".join(hub_ip.split(".")[:3])

    # Run mDNS + SSDP concurrently with the rest
    loop = asyncio.get_running_loop()
    mdns_task  = loop.run_in_executor(None, _scan_mdns, 1.5)
    ssdp_task  = loop.run_in_executor(None, _scan_ssdp, 1.5)

    # 1 — fast: IPs already in ARP table (instant)
    known = set(_arp_hosts(subnet))

    # 2 — TCP probe + Ping sweep run CONCURRENTLY (not sequentially)
    all_ips = [f"{subnet}.{i}" for i in range(1, 255)]

    sem_tcp = asyncio.Semaphore(150)   # 150 parallel async TCP checks

    async def _tcp_check(ip):
        async with sem_tcp:
            alive = await _tcp_alive_async(ip)
            return ip, alive

    sem_ping = asyncio.Semaphore(50)   # 50 parallel pings

    async def _run_tcp():
        try:
            results = await asyncio.wait_for(
                asyncio.gather(*[_tcp_check(ip) for ip in all_ips], return_exceptions=True),
                timeout=7.0,
            )
            for res in results:
                if isinstance(res, tuple) and res[1]:
                    known.add(res[0])
        except asyncio.TimeoutError:
            pass

    async def _run_ping():
        try:
            await asyncio.wait_for(
                asyncio.gather(*[_ping_one(ip, sem_ping) for ip in all_ips], return_exceptions=True),
                timeout=6.0,
            )
        except asyncio.TimeoutError:
            pass

    # Run TCP + Ping in parallel — total wait = max(7s, 6s) = 7s instead of 14+16=30s
    await asyncio.gather(_run_tcp(), _run_ping(), return_exceptions=True)

    # 3 — collect results
    mdns_devices  = await mdns_task
    ssdp_devices  = await ssdp_task
    gateway_ip    = await loop.run_in_executor(None, _get_gateway)

    live = set(_arp_hosts(subnet)) | known
    live.discard(hub_ip)

    # Add IPs seen in mDNS/SSDP even if not in ARP
    for d in mdns_devices + ssdp_devices:
        if d["ip"] != hub_ip:
            live.add(d["ip"])

    # Always add the gateway
    if gateway_ip:
        live.add(gateway_ip)

    # If still nothing found (completely isolated network), skip HTTP probe
    # Don't fall back to all 254 — that would hang for minutes
    if not live:
        mdns_devices_list = mdns_devices
        ssdp_devices_list = ssdp_devices
        all_devices = mdns_devices_list + ssdp_devices_list
        if gateway_ip:
            all_devices.append({
                "ip": gateway_ip, "name": "🌐 Router (Gateway)",
                "hostname": gateway_ip, "device_type": "router",
                "protocol": "wifi", "auto_pair": False,
                "already_paired": False, "is_gateway": True, "info": {},
            })
        return all_devices

    # 4 — parallel HTTP probe on live IPs only (not all 254)
    limits = httpx.Limits(max_connections=50, max_keepalive_connections=0)
    async with httpx.AsyncClient(limits=limits) as client:
        tasks  = [_probe(client, ip, hub_ip) for ip in sorted(live)]
        probed = await asyncio.gather(*tasks, return_exceptions=True)

    # 5 — merge: HTTP probe wins; mDNS/SSDP fill in unknowns
    http_map = {r["ip"]: r for r in probed if isinstance(r, dict)}
    extra: list[dict] = []

    for d in mdns_devices + ssdp_devices:
        ip = d["ip"]
        if ip == hub_ip:
            continue
        if ip not in http_map:
            extra.append(d)

    # Tag the gateway
    if gateway_ip and gateway_ip in http_map:
        http_map[gateway_ip]["is_gateway"] = True
        http_map[gateway_ip]["name"] = f"🌐 Router ({http_map[gateway_ip]['name']})"
    elif gateway_ip:
        gw = next((d for d in extra if d["ip"] == gateway_ip), None)
        if gw:
            gw["is_gateway"] = True
            gw["name"] = f"🌐 Router ({gw['name']})"
        else:
            extra.append({
                "ip": gateway_ip, "name": "🌐 Router (Gateway)",
                "hostname": gateway_ip, "device_type": "router",
                "protocol": "wifi", "auto_pair": False,
                "already_paired": False, "is_gateway": True, "info": {},
            })

    all_devices = list(http_map.values()) + extra
    all_devices.sort(key=lambda d: (
        not d.get("is_gateway", False),          # gateway first
        d["device_type"] in ("http", "unknown", "ssdp", "mdns"),
        d["already_paired"],
        d["ip"],
    ))
    return all_devices


# ── Quick network info (no scanning) ─────────────────────────────────────────

@router.get("/info")
async def network_info():
    """Return instant basic network info — no scanning, always fast."""
    loop = asyncio.get_running_loop()
    hub_ip    = _get_local_ip()
    gateway   = await loop.run_in_executor(None, _get_gateway)
    arp_hosts = _arp_hosts(".".join(hub_ip.split(".")[:3]))
    return {
        "hub_ip":   hub_ip,
        "gateway":  gateway,
        "subnet":   ".".join(hub_ip.split(".")[:3]) + ".0/24",
        "arp_count": len(arp_hosts),
        "arp_hosts": arp_hosts[:20],   # first 20 only
    }


# ── Connectivity diagnostic ───────────────────────────────────────────────────

@router.get("/diagnose")
async def diagnose():
    """
    Full connectivity diagnostic for AC1200 / dual-band routers.
    Returns a list of checks with pass/fail/warn + actionable fix hints.
    """
    import time
    loop = asyncio.get_running_loop()

    hub_ip  = _get_local_ip()
    gateway = await loop.run_in_executor(None, _get_gateway)
    subnet  = ".".join(hub_ip.split(".")[:3])
    checks  = []

    # ── 1. Hub IP valid ───────────────────────────────────────────────────────
    valid_ip = (hub_ip != "127.0.0.1" and not hub_ip.startswith("169.254"))
    checks.append({
        "name":   "כתובת IP של Hub",
        "status": "ok" if valid_ip else "fail",
        "value":  hub_ip,
        "fix":    "חבר את המחשב לרשת WiFi או כבל LAN" if not valid_ip else None,
    })

    # ── 2. Gateway reachable ──────────────────────────────────────────────────
    gw_ok = False
    if gateway:
        gw_ok = await loop.run_in_executor(None, _ping_sync, gateway)
    checks.append({
        "name":   "ראוטר נגיש",
        "status": "ok" if gw_ok else "fail",
        "value":  gateway or "לא זוהה",
        "fix":    ("ראוטר לא מגיב לפינג. בדוק: 1) כבל/WiFi מחובר "
                   "2) ראוטר דולק 3) IP נכון") if not gw_ok else None,
    })

    # ── 3. Port 8080 open locally ─────────────────────────────────────────────
    port_ok = False
    try:
        reader, writer = await asyncio.wait_for(
            asyncio.open_connection("127.0.0.1", 8080), timeout=1.0)
        writer.close()
        port_ok = True
    except Exception:
        pass
    checks.append({
        "name":   "Hub API פורט 8080",
        "status": "ok" if port_ok else "warn",
        "value":  f"http://{hub_ip}:8080",
        "fix":    None,  # Hub is the one answering this request so 8080 is obviously open
    })

    # ── 4. MQTT port 1883 ─────────────────────────────────────────────────────
    mqtt_ok = False
    try:
        reader2, writer2 = await asyncio.wait_for(
            asyncio.open_connection("127.0.0.1", 1883), timeout=1.5)
        writer2.close()
        mqtt_ok = True
    except Exception:
        pass
    checks.append({
        "name":   "MQTT Broker פורט 1883",
        "status": "ok" if mqtt_ok else "fail",
        "value":  "פועל" if mqtt_ok else "לא פועל",
        "fix":    ("MQTT Broker לא פועל. סגור והפעל מחדש את Hub. "
                   "אם הבעיה חוזרת, התקן Mosquitto מ-mosquitto.org") if not mqtt_ok else None,
    })

    # ── 5. Windows Firewall check ─────────────────────────────────────────────
    fw_rule_exists = False
    fw_status = "לא נבדק"
    if IS_WIN:
        try:
            r = subprocess.run(
                ["netsh", "advfirewall", "firewall", "show", "rule", "name=Fantatech Hub API"],
                capture_output=True, text=True, timeout=5,
                encoding="utf-8", errors="ignore"
            )
            fw_rule_exists = "Allow" in r.stdout or "מאפשר" in r.stdout
            fw_status = "חוק קיים ✓" if fw_rule_exists else "חוק חסר"
        except Exception:
            fw_status = "לא נבדק"
    checks.append({
        "name":   "חומת אש Windows",
        "status": "ok" if fw_rule_exists else "warn",
        "value":  fw_status,
        "fix":    ("חוק חסר בחומת אש! הפעל מחדש את start-hub.bat כמנהל מערכת (Run as Admin). "
                   "או הפעל ידנית: netsh advfirewall firewall add rule "
                   "name=\"Fantatech Hub API\" protocol=TCP dir=in localport=8080 action=allow"
                   ) if not fw_rule_exists and IS_WIN else None,
    })

    # ── 6. ARP / other devices on network ────────────────────────────────────
    arp_hosts = _arp_hosts(subnet)
    arp_hosts_clean = [h for h in arp_hosts if h != hub_ip and h != gateway]
    ap_isolation_likely = gw_ok and len(arp_hosts_clean) == 0
    checks.append({
        "name":   "מכשירים ברשת (ARP)",
        "status": "warn" if ap_isolation_likely else "ok",
        "value":  f"{len(arp_hosts_clean)} מכשירים נראים",
        "fix":    ("ייתכן שה-AP Isolation מופעל בראוטר! "
                   "כנס לממשק הניהול של הראוטר (בדרך כלל http://" + (gateway or "192.168.1.1") + ") "
                   "→ Wireless Settings → AP Isolation → כבה אותו"
                   ) if ap_isolation_likely else None,
    })

    # ── 7. Internet connectivity ──────────────────────────────────────────────
    inet_ok = await loop.run_in_executor(None, _ping_sync, "8.8.8.8")
    checks.append({
        "name":   "גישה לאינטרנט",
        "status": "ok" if inet_ok else "warn",
        "value":  "זמין" if inet_ok else "לא זמין",
        "fix":    "אין גישה לאינטרנט — ממשיך בסדר, Hub עובד מקומית" if not inet_ok else None,
    })

    # ── Summary ───────────────────────────────────────────────────────────────
    failed = [c for c in checks if c["status"] == "fail"]
    warned = [c for c in checks if c["status"] == "warn"]
    overall = "fail" if failed else ("warn" if warned else "ok")

    return {
        "overall":  overall,
        "hub_ip":   hub_ip,
        "gateway":  gateway,
        "subnet":   subnet + ".0/24",
        "checks":   checks,
        "summary":  (
            "✅ הכל תקין — האפליקציה אמורה לעבוד" if overall == "ok"
            else f"⚠️ {len(failed)} שגיאות, {len(warned)} אזהרות — ראה פירוט"
        ),
    }


# ── Auto-pair ─────────────────────────────────────────────────────────────────

class PairIn(BaseModel):
    ip:          str
    name:        str
    device_type: str
    dev_type:    str = "switch"     # switch | light | dimmer | sensor …
    room:        str = ""
    label:       str = ""


@router.post("/pair")
async def pair_device(data: PairIn):
    hub_ip    = _get_local_ip()
    device_id = data.ip.replace(".", "_")
    topic     = device_id

    async with httpx.AsyncClient(timeout=5) as client:

        # ── Tasmota auto-configure ──────────────────────────────────────────
        if data.device_type == "tasmota":
            cmd = (
                f"Backlog MqttHost {hub_ip};"
                f"MqttPort 1883;"
                f"Topic {topic};"
                f"MqttClient {device_id}"
            )
            url = f"http://{data.ip}/cm?cmnd={urllib.parse.quote(cmd)}"
            try:
                r = await client.get(url)
                if r.status_code != 200:
                    raise HTTPException(400, "Tasmota לא הגיב לפקודת הגדרה")
            except httpx.RequestError as e:
                raise HTTPException(400, f"לא ניתן להתחבר ל-{data.ip}: {e}")

        # ── Shelly auto-configure ────────────────────────────────────────────
        elif data.device_type == "shelly":
            url = (
                f"http://{data.ip}/settings/mqtt"
                f"?mqtt_enable=true"
                f"&mqtt_server={hub_ip}%3A1883"
                f"&mqtt_id={device_id}"
            )
            try:
                r = await client.get(url)
                if r.status_code != 200:
                    raise HTTPException(400, "Shelly לא הגיב להגדרת MQTT")
            except httpx.RequestError as e:
                raise HTTPException(400, f"לא ניתן להתחבר ל-{data.ip}: {e}")

        # ── ESPHome / generic — no auto-config, just register ───────────────
        # (user adds it with manual MQTT topic)

    # Register in DB
    import time as _time
    device_record = {
        "id":          device_id,
        "name":        data.name,
        "protocol":    "wifi",
        "type":        data.dev_type,
        "topic_state": f"tele/{topic}/STATE"     if data.device_type == "tasmota"
                       else f"shellies/{device_id}/relay/0" if data.device_type == "shelly"
                       else f"devices/{device_id}/state",
        "topic_cmd":   f"cmnd/{topic}/Power"     if data.device_type == "tasmota"
                       else f"shellies/{device_id}/relay/0/command" if data.device_type == "shelly"
                       else f"devices/{device_id}/cmd",
        "room":        data.room,
        "config":      {"ip": data.ip, "source": data.device_type},
        "state":       {},
        "online":      False,
        "pinned":      False,
        "label":       data.label or data.device_type,
        "created_at":  int(_time.time()),
    }
    # Topics already set correctly in device_record above — no override needed
    await upsert_device(device_record)
    return {"ok": True, "device_id": device_id, "device": device_record}


# ══════════════════════════════════════════════════════════════════════════════
# WiFi connection (hub → router)
# ══════════════════════════════════════════════════════════════════════════════

class ConnectIn(BaseModel):
    ssid:         str
    password:     str = ""
    save:         bool = False
    auto_connect: bool = True
    room:         str | None = None


class PriorityIn(BaseModel):
    priority: int


class AutoConnectIn(BaseModel):
    auto_connect: bool


def _channel_to_band(channel: int) -> str:
    """Return '2.4' or '5' based on WiFi channel number."""
    if 1 <= channel <= 13:
        return "2.4"
    if channel >= 36:
        return "5"
    return "2.4"  # default


def _radio_to_band(radio: str) -> str | None:
    """Infer band from radio type string (802.11ac / ax → 5GHz)."""
    r = radio.lower()
    if any(x in r for x in ("11ac", "11ax", "802.11ac", "802.11ax")):
        return "5"
    if any(x in r for x in ("11b", "11g")):
        return "2.4"
    return None  # 802.11n could be either — rely on channel


def _trigger_wifi_scan() -> None:
    """Force the WiFi adapter to start a fresh scan (fire-and-forget)."""
    try:
        # Running without mode=Bssid first triggers the adapter to rescan
        subprocess.run(
            ["netsh", "wlan", "show", "networks"],
            capture_output=True, timeout=6, encoding="utf-8", errors="ignore"
        )
        import time; time.sleep(1.5)
    except Exception:
        pass


def _scan_windows() -> list:
    # Trigger a fresh scan before reading results
    _trigger_wifi_scan()

    # ── Try netsh (works on English AND Hebrew Windows) ───────────────────────
    for attempt in range(2):  # retry once if first attempt returns empty
        try:
            r = subprocess.run(
                ["netsh", "wlan", "show", "networks", "mode=Bssid"],
                capture_output=True, text=True, encoding="utf-8", errors="ignore", timeout=15
            )
            output = r.stdout.strip()

            # Detect WiFi disabled / no adapter
            disabled_hints = ("no wireless", "there is no", "אין רכיב", "אין מתאם", "not available")
            if any(h in output.lower() for h in disabled_hints):
                return [{"ssid": "__wifi_disabled__", "signal": 0, "secured": False, "band": None}]

            if not output:
                if attempt == 0:
                    import time; time.sleep(2)
                    continue
                break

            networks, cur = [], {}
            for line in output.splitlines():
                line = line.strip()

                # SSID line — same in all Windows locales
                m = re.match(r"SSID\s+\d+\s*:\s*(.+)", line)
                if m:
                    if cur.get("ssid"):
                        networks.append(cur)
                    cur = {"ssid": m.group(1).strip(), "signal": None,
                           "secured": True, "band": None}

                # Signal — keep the HIGHEST signal across all BSSIDs for this SSID
                s = re.match(r"(?:Signal|אות)\s*:\s*(\d+)\s*%", line)
                if s and cur:
                    sig = int(s.group(1))
                    if cur.get("signal") is None or sig > cur["signal"]:
                        cur["signal"] = sig

                # Authentication
                a = re.match(r"(?:Authentication|אימות)\s*:\s*(.+)", line)
                if a and cur:
                    val = a.group(1).strip()
                    cur["secured"] = not any(
                        w in val for w in ("Open", "ללא", "None", "פתוחה"))

                # Channel
                ch = re.match(r"(?:Channel|ערוץ)\s*:\s*(\d+)", line)
                if ch and cur and cur.get("band") is None:
                    cur["band"] = _channel_to_band(int(ch.group(1)))

                # Radio type
                rt = re.match(r"(?:Radio type|סוג רדיו)\s*:\s*(.+)", line)
                if rt and cur and cur.get("band") is None:
                    cur["band"] = _radio_to_band(rt.group(1).strip())

            if cur.get("ssid"):
                networks.append(cur)

            # Fill missing band/signal
            for n in networks:
                if n.get("signal") is None:
                    n["signal"] = 50
                if n.get("band") is None:
                    ssid_lower = n["ssid"].lower()
                    n["band"] = "5" if any(x in ssid_lower for x in ("_5g", "-5g", " 5g", "_5ghz", "5ghz")) else "2.4"

            if networks:
                return networks

            # Empty result — retry once
            if attempt == 0:
                import time; time.sleep(2)

        except Exception:
            if attempt == 0:
                import time; time.sleep(1)

    # ── Fallback A: PowerShell with forced English culture ────────────────────
    try:
        ps = (
            "$c=[System.Threading.Thread]::CurrentThread;"
            "$c.CurrentCulture='en-US';$c.CurrentUICulture='en-US';"
            "netsh wlan show networks mode=bssid"
        )
        r2 = subprocess.run(
            ["powershell", "-NoProfile", "-NonInteractive", "-Command", ps],
            capture_output=True, text=True, encoding="utf-8", errors="ignore", timeout=15
        )
        nets2, cur2 = [], {}
        for line in r2.stdout.splitlines():
            line = line.strip()
            m = re.match(r"SSID\s+\d+\s*:\s*(.+)", line)
            if m:
                if cur2.get("ssid"):
                    nets2.append(cur2)
                cur2 = {"ssid": m.group(1).strip(), "signal": None,
                        "secured": True, "band": None}
            s = re.match(r"Signal\s*:\s*(\d+)\s*%", line)
            if s and cur2:
                sig = int(s.group(1))
                if cur2.get("signal") is None or sig > cur2["signal"]:
                    cur2["signal"] = sig
            a = re.match(r"Authentication\s*:\s*(.+)", line)
            if a and cur2:
                cur2["secured"] = "Open" not in a.group(1)
            ch = re.match(r"Channel\s*:\s*(\d+)", line)
            if ch and cur2 and cur2.get("band") is None:
                cur2["band"] = _channel_to_band(int(ch.group(1)))
            rt = re.match(r"Radio type\s*:\s*(.+)", line)
            if rt and cur2 and cur2.get("band") is None:
                cur2["band"] = _radio_to_band(rt.group(1).strip())
        if cur2.get("ssid"):
            nets2.append(cur2)
        for n in nets2:
            if n.get("signal") is None:
                n["signal"] = 50
            if n.get("band") is None:
                ssid_lower = n["ssid"].lower()
                n["band"] = "5" if any(
                    x in ssid_lower for x in ("_5g", "-5g", " 5g", "5ghz")
                ) else "2.4"
        if nets2:
            return nets2
    except Exception:
        pass

    # ── Fallback B: saved profiles — at least shows known networks ────────────
    try:
        r3 = subprocess.run(
            ["netsh", "wlan", "show", "profiles"],
            capture_output=True, text=True, encoding="utf-8", errors="ignore", timeout=8
        )
        nets3 = []
        for line in r3.stdout.splitlines():
            m = re.search(
                r"(?:All User Profile|User Profile|פרופיל כל המשתמשים|פרופיל המשתמש)\s*:\s*(.+)",
                line
            )
            if m:
                ssid = m.group(1).strip()
                if ssid:
                    ssid_lower = ssid.lower()
                    band = "5" if any(
                        x in ssid_lower for x in ("_5g", "-5g", " 5g", "5ghz")
                    ) else "2.4"
                    nets3.append({"ssid": ssid, "signal": 50,
                                  "secured": True, "saved": True, "band": band})
        if nets3:
            return nets3
    except Exception:
        pass

    return []


def _scan_linux() -> list:
    # ── Try nmcli first ───────────────────────────────────────────────────────
    try:
        r = subprocess.run(
            ["nmcli", "--mode", "tabular", "-f", "SSID,SIGNAL,SECURITY", "dev", "wifi", "list"],
            capture_output=True, text=True, timeout=12,
            env={**os.environ, "LANG": "C", "LC_ALL": "C"},
        )
        nets = []
        for line in r.stdout.strip().splitlines()[1:]:   # skip header
            parts = line.split()
            if not parts:
                continue
            ssid = parts[0]
            signal = int(parts[1]) if len(parts) > 1 and parts[1].isdigit() else 50
            secured = len(parts) > 2 and parts[2] not in ("--", "")
            nets.append({"ssid": ssid, "signal": signal, "secured": secured})
        if nets:
            return nets
    except Exception:
        pass

    # ── Fallback: iwlist scan ────────────────────────────────────────────────
    try:
        r2 = subprocess.run(
            ["iwlist", "scan"],
            capture_output=True, text=True, timeout=12,
        )
        nets2, cur2 = [], {}
        for line in r2.stdout.splitlines():
            line = line.strip()
            if "ESSID:" in line:
                m = re.search(r'ESSID:"(.+)"', line)
                if m:
                    if cur2.get("ssid"):
                        nets2.append(cur2)
                    cur2 = {"ssid": m.group(1), "signal": 50, "secured": False}
            elif "Signal level=" in line:
                m2 = re.search(r"Signal level=(-?\d+)", line)
                if m2 and cur2:
                    dbm = int(m2.group(1))
                    cur2["signal"] = max(0, min(100, 2 * (dbm + 100)))
            elif "Encryption key:on" in line and cur2:
                cur2["secured"] = True
        if cur2.get("ssid"):
            nets2.append(cur2)
        return nets2
    except Exception:
        return []


@router.get("/scan")
async def scan_networks():
    loop = asyncio.get_running_loop()
    scan_fn = _scan_windows if IS_WIN else _scan_linux
    nets = await loop.run_in_executor(None, scan_fn)
    seen, out = set(), []
    for n in sorted(nets, key=lambda x: -x["signal"]):
        if n["ssid"] not in seen:
            seen.add(n["ssid"])
            out.append(n)
    return out


@router.get("/status")
async def network_status():
    if IS_WIN:
        try:
            r = subprocess.run(["netsh", "wlan", "show", "interfaces"],
                               capture_output=True, text=True, encoding="utf-8",
                               errors="ignore", timeout=6)
            ssid = re.search(r"^\s+SSID\s*:\s*(.+)", r.stdout, re.MULTILINE)
            sig  = re.search(r"Signal\s*:\s*(\d+)%", r.stdout)
            return {"connected": bool(ssid),
                    "ssid":   ssid.group(1).strip() if ssid else None,
                    "signal": int(sig.group(1)) if sig else 0}
        except Exception:
            pass
    else:
        try:
            r = subprocess.run(["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL", "dev", "wifi"],
                               capture_output=True, text=True, timeout=6)
            for line in r.stdout.splitlines():
                p = line.split(":")
                if p[0] == "yes":
                    return {"connected": True, "ssid": p[1],
                            "signal": int(p[2]) if p[2].isdigit() else 0}
        except Exception:
            pass
    return {"connected": False, "ssid": None, "signal": 0}


def _build_wifi_xml(ssid_safe: str, pass_safe: str, auth: str, enc: str) -> str:
    """Build a Windows WLAN profile XML for the given auth/encryption combo."""
    if not pass_safe:
        key_block = ""
    else:
        key_block = f"""
      <sharedKey>
        <keyType>passPhrase</keyType>
        <protected>false</protected>
        <keyMaterial>{pass_safe}</keyMaterial>
      </sharedKey>"""
    return f"""<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
  <name>{ssid_safe}</name>
  <SSIDConfig>
    <SSID><name>{ssid_safe}</name></SSID>
    <nonBroadcast>false</nonBroadcast>
  </SSIDConfig>
  <connectionType>ESS</connectionType>
  <connectionMode>auto</connectionMode>
  <MSM>
    <security>
      <authEncryption>
        <authentication>{auth}</authentication>
        <encryption>{enc}</encryption>
        <useOneX>false</useOneX>
      </authEncryption>{key_block}
    </security>
  </MSM>
</WLANProfile>"""


def _connect_windows(ssid: str, password: str):
    """
    Try multiple WPA auth/encryption combinations until one succeeds.
    Order: WPA3-SAE → WPA2PSK/AES → WPA2PSK/TKIP → WPA2PSK/mixed → WPAPSK/AES → WPAPSK/TKIP → Open
    This handles WPA2-Personal, WPA/WPA2 mixed mode, and legacy TKIP routers.
    """
    import html as _html
    ssid_safe  = _html.escape(ssid)
    pass_safe  = _html.escape(password) if password else ""

    if not password:
        combos = [("open", "none")]
    else:
        combos = [
            ("WPA3SAE",  "GCMP256"),   # WPA3-Personal
            ("WPA2PSK",  "AES"),       # WPA2-Personal (most common)
            ("WPA2PSK",  "TKIP"),      # WPA2 with legacy TKIP
            ("WPA2PSK",  "CCMP"),      # Some routers report CCMP explicitly
            ("WPAPSK",   "AES"),       # WPA/WPA2 mixed → AES
            ("WPAPSK",   "TKIP"),      # WPA/WPA2 mixed → TKIP
        ]

    last_err = ""

    # Remove any stale profile first to avoid cached auth-type conflicts
    subprocess.run(
        ["netsh", "wlan", "delete", "profile", f"name={ssid}"],
        capture_output=True
    )

    for auth, enc in combos:
        xml = _build_wifi_xml(ssid_safe, pass_safe, auth, enc)
        tmp = None
        try:
            with tempfile.NamedTemporaryFile(
                mode="w", suffix=".xml", delete=False, encoding="utf-8"
            ) as f:
                f.write(xml)
                tmp = f.name

            add_r = subprocess.run(
                ["netsh", "wlan", "add", "profile", f"filename={tmp}"],
                capture_output=True, text=True, encoding="utf-8", errors="ignore"
            )
            if add_r.returncode != 0:
                last_err = add_r.stderr or add_r.stdout
                continue  # try next combo

            conn_r = subprocess.run(
                ["netsh", "wlan", "connect", f"name={ssid}"],
                capture_output=True, text=True, encoding="utf-8", errors="ignore"
            )
            if conn_r.returncode == 0:
                return   # ✅ success

            last_err = conn_r.stderr or conn_r.stdout

        except Exception as e:
            last_err = str(e)
        finally:
            if tmp:
                try:
                    os.unlink(tmp)
                except Exception:
                    pass

    # All combos failed
    raise subprocess.CalledProcessError(
        1, "netsh",
        f"כל שיטות האבטחה נכשלו ({last_err.strip()[:120]})".encode()
    )


def _connect_linux(ssid: str, password: str):
    cmd = ["nmcli", "dev", "wifi", "connect", ssid]
    if password:
        cmd += ["password", password]
    subprocess.run(cmd, check=True, capture_output=True)


@router.post("/connect")
async def connect_network(data: ConnectIn):
    loop = asyncio.get_running_loop()
    try:
        if IS_WIN:
            await loop.run_in_executor(None, _connect_windows, data.ssid, data.password)
        else:
            await loop.run_in_executor(None, _connect_linux,   data.ssid, data.password)
    except subprocess.CalledProcessError as e:
        raw = e.stderr.decode(errors="ignore") if isinstance(e.stderr, bytes) else str(e.stderr or e)
        # Give a human-readable explanation
        if "incorrect" in raw.lower() or "wrong" in raw.lower() or "נכשלו" in raw:
            detail = f"❌ הסיסמה שגויה או סוג האבטחה אינו תואם.\n{raw[:200]}"
        elif "not found" in raw.lower() or "profile" in raw.lower():
            detail = f"❌ הרשת לא נמצאה — ודא שהרשת בטווח ושם ה-SSID נכון.\n{raw[:200]}"
        else:
            detail = f"❌ חיבור נכשל: {raw[:300]}"
        raise HTTPException(400, detail)
    except Exception as e:
        raise HTTPException(500, f"שגיאה פנימית: {e}")
    if data.save:
        await save_wifi_profile(data.ssid, data.password, data.room or "", data.auto_connect)
    return {"ok": True, "ssid": data.ssid}


# ── Auto-connect: try saved profiles in priority order ────────────────────────

@router.post("/auto-connect")
async def auto_connect():
    """Try each auto_connect=1 profile in priority order until one succeeds."""
    profiles = await get_wifi_profiles()
    auto = [p for p in profiles if p.get("auto_connect", 1)]
    if not auto:
        return {"ok": False, "reason": "אין פרופילים לחיבור אוטומטי"}

    # Check current connection first
    try:
        status = await network_status()
        if status.get("connected"):
            current = status.get("ssid")
            if any(p["ssid"] == current for p in auto):
                return {"ok": True, "ssid": current, "already": True}
    except Exception:
        pass

    for profile in auto:
        try:
            if IS_WIN:
                _connect_windows(profile["ssid"], profile["password"])
            else:
                _connect_linux(profile["ssid"], profile["password"])
            return {"ok": True, "ssid": profile["ssid"]}
        except Exception:
            continue

    return {"ok": False, "reason": "לא הצלחנו להתחבר לאף פרופיל שמור"}


# ── Saved profiles management ─────────────────────────────────────────────────

@router.get("/saved")
async def list_saved():
    profiles = await get_wifi_profiles()
    return [
        {
            "ssid":         p["ssid"],
            "saved_at":     p["saved_at"],
            "priority":     p.get("priority", 0),
            "auto_connect": bool(p.get("auto_connect", 1)),
            "room":         p.get("room", ""),
        }
        for p in profiles
    ]


@router.delete("/saved/{ssid}")
async def remove_saved(ssid: str):
    await delete_wifi_profile(urllib.parse.unquote(ssid))
    return {"ok": True}


@router.put("/saved/{ssid}/priority")
async def set_priority(ssid: str, body: PriorityIn):
    await update_wifi_priority(urllib.parse.unquote(ssid), body.priority)
    return {"ok": True}


@router.put("/saved/{ssid}/auto-connect")
async def set_auto_connect(ssid: str, body: AutoConnectIn):
    await update_wifi_auto_connect(urllib.parse.unquote(ssid), body.auto_connect)
    return {"ok": True}


@router.get("/hub-ip")
def get_hub_ip():
    """Returns this machine's LAN IP — lets the app know the exact Hub address."""
    return {"ip": _get_local_ip(), "port": 8080}
