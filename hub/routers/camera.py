"""
Camera router — real drivers for IP cameras.

Supported drivers:
  rtsp         Generic RTSP
  hikvision    Hikvision / ISAPI HTTP + RTSP
  dahua        Dahua CGI HTTP + RTSP
  reolink      Reolink HTTP API + RTSP
  tapo         TP-Link Tapo RTSP
  amcrest      Amcrest HTTP + RTSP
  foscam       Foscam HTTP CGI + RTSP
  onvif        ONVIF-compatible (any brand)
  http_mjpeg   Generic HTTP MJPEG stream (proxy)
  http_snapshot  Generic HTTP snapshot (proxy)
"""

import asyncio
import logging
import socket
import time
import threading
from typing import Optional, List

import httpx
from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import StreamingResponse, Response
from pydantic import BaseModel

router = APIRouter()
log = logging.getLogger(__name__)

# ── Optional heavy deps ────────────────────────────────────────────────────
try:
    import cv2
    HAS_CV2 = True
except ImportError:
    HAS_CV2 = False

# ── Driver registry ────────────────────────────────────────────────────────
DRIVERS = {
    "rtsp":           {"label": "RTSP (Generic)",         "icon": "📡", "has_http": False},
    "hikvision":      {"label": "Hikvision / ISAPI",      "icon": "🎥", "has_http": True},
    "dahua":          {"label": "Dahua",                  "icon": "🎥", "has_http": True},
    "reolink":        {"label": "Reolink",                "icon": "🎥", "has_http": True},
    "tapo":           {"label": "TP-Link Tapo",           "icon": "🎥", "has_http": False},
    "amcrest":        {"label": "Amcrest",                "icon": "🎥", "has_http": True},
    "foscam":         {"label": "Foscam",                 "icon": "🎥", "has_http": True},
    "onvif":          {"label": "ONVIF (any brand)",      "icon": "🔍", "has_http": True},
    "http_mjpeg":     {"label": "HTTP MJPEG Stream",      "icon": "🌐", "has_http": True},
    "http_snapshot":  {"label": "HTTP Snapshot",          "icon": "📸", "has_http": True},
}

DEFAULT_PORTS = {
    "foscam": 88,
    "reolink": 80,
    "hikvision": 80,
    "dahua": 80,
    "tapo": 554,
}
DEFAULT_RTSP_PORTS = {"foscam": 88}

# ── RTSP URL builders ──────────────────────────────────────────────────────
def build_rtsp_url(driver: str, ip: str, username: str, password: str,
                   channel: int, subtype: int, rtsp_port: int,
                   custom_path: str = "") -> str:
    cred = f"{username}:{password}@" if username and password else (f"{username}@" if username else "")

    if custom_path:
        return f"rtsp://{cred}{ip}:{rtsp_port}/{custom_path.lstrip('/')}"

    if driver == "hikvision":
        stream_id = 100 * channel + (1 if subtype == 0 else 2)
        return f"rtsp://{cred}{ip}:{rtsp_port}/Streaming/Channels/{stream_id}"

    if driver in ("dahua", "amcrest"):
        return f"rtsp://{cred}{ip}:{rtsp_port}/cam/realmonitor?channel={channel}&subtype={subtype}"

    if driver == "reolink":
        quality = "main" if subtype == 0 else "sub"
        return f"rtsp://{cred}{ip}:{rtsp_port}/h264Preview_0{channel}_{quality}"

    if driver == "tapo":
        stream = "stream1" if subtype == 0 else "stream2"
        return f"rtsp://{cred}{ip}:554/{stream}"

    if driver == "foscam":
        return f"rtsp://{cred}{ip}:{rtsp_port}/videoMain"

    if driver == "onvif":
        return f"rtsp://{cred}{ip}:{rtsp_port}/stream1"

    # Generic RTSP
    return f"rtsp://{cred}{ip}:{rtsp_port}/"


# ── Snapshot URL builders ──────────────────────────────────────────────────
def build_snapshot_url(driver: str, ip: str, port: int,
                       username: str, password: str,
                       channel: int, custom_url: str = "") -> Optional[str]:
    if custom_url:
        return custom_url

    base = f"http://{ip}:{port}"

    if driver == "hikvision":
        return f"{base}/ISAPI/Streaming/channels/{channel * 100 + 1}/picture"

    if driver in ("dahua", "amcrest"):
        return f"{base}/cgi-bin/snapshot.cgi?channel={channel}"

    if driver == "reolink":
        ts = int(time.time())
        return f"{base}/cgi-bin/api.cgi?cmd=Snap&channel={channel - 1}&rs={ts}&user={username}&password={password}"

    if driver == "foscam":
        return f"{base}/cgi-bin/CGIProxy.fcgi?usr={username}&pwd={password}&cmd=snapPicture2"

    if driver == "onvif":
        return f"{base}/onvif/snapshot"

    if driver == "http_snapshot":
        return None  # user must supply URL directly

    return None  # RTSP-only drivers


# ── Pydantic models ────────────────────────────────────────────────────────
class TestCameraBody(BaseModel):
    driver: str
    ip: str
    port: int = 80
    username: str = "admin"
    password: str = ""
    rtsp_port: int = 554
    channel: int = 1
    subtype: int = 0
    custom_path: str = ""
    custom_url: str = ""


class DiscoverBody(BaseModel):
    subnet: Optional[str] = None


# ── Endpoints ─────────────────────────────────────────────────────────────

@router.get("/drivers")
def list_drivers():
    """Return all supported camera drivers."""
    return {
        "drivers": [
            {
                "id": k,
                "label": v["label"],
                "icon": v["icon"],
                "has_http": v["has_http"],
                "default_port": DEFAULT_PORTS.get(k, 80),
                "default_rtsp_port": DEFAULT_RTSP_PORTS.get(k, 554),
                "rtsp_example": build_rtsp_url(k, "192.168.1.x", "admin", "pass", 1, 0,
                                               DEFAULT_RTSP_PORTS.get(k, 554)),
            }
            for k, v in DRIVERS.items()
        ],
        "mjpeg_proxy_available": HAS_CV2,
    }


@router.post("/test")
async def test_camera(body: TestCameraBody):
    """
    Test connectivity to a camera and return working URLs.
    Returns: rtsp_url, snapshot_url, reachable, snapshot_ok, error
    """
    driver = body.driver
    rtsp_url = build_rtsp_url(driver, body.ip, body.username, body.password,
                               body.channel, body.subtype, body.rtsp_port, body.custom_path)
    snap_url = build_snapshot_url(driver, body.ip, body.port, body.username,
                                  body.password, body.channel, body.custom_url)

    result = {
        "driver": driver,
        "rtsp_url": rtsp_url,
        "snapshot_url": snap_url,
        "mjpeg_proxy_url": f"/api/camera/stream/mjpeg?url={rtsp_url}" if HAS_CV2 else None,
        "reachable": False,
        "snapshot_ok": False,
        "error": None,
    }

    # TCP reachability check
    probe_port = body.rtsp_port if driver == "tapo" else body.port
    try:
        reader, writer = await asyncio.wait_for(
            asyncio.open_connection(body.ip, probe_port), timeout=3.0
        )
        writer.close()
        try:
            await writer.wait_closed()
        except Exception:
            pass
        result["reachable"] = True
    except Exception as e:
        result["error"] = f"Cannot reach {body.ip}:{probe_port} — {e}"
        return result

    # HTTP snapshot test
    if snap_url and driver not in ("rtsp", "tapo", "http_mjpeg"):
        try:
            auth = (body.username, body.password) if body.username else None
            async with httpx.AsyncClient(timeout=5.0, verify=False, follow_redirects=True) as client:
                r = await client.get(snap_url, auth=auth)
            result["snapshot_ok"] = r.status_code in (200, 206)
            if not result["snapshot_ok"]:
                result["error"] = f"Snapshot HTTP {r.status_code}"
        except Exception as e:
            result["error"] = f"Snapshot error: {e}"

    return result


@router.get("/snapshot/proxy")
async def proxy_snapshot(
    url: str = Query(..., description="Camera snapshot URL"),
    username: str = "",
    password: str = "",
):
    """
    Fetch a snapshot from the camera and return it.
    Bypasses CORS and allows the app to show camera images regardless of network topology.
    """
    try:
        auth = (username, password) if username else None
        async with httpx.AsyncClient(timeout=8.0, verify=False, follow_redirects=True) as client:
            resp = await client.get(url, auth=auth)
        if resp.status_code == 200:
            ct = resp.headers.get("content-type", "image/jpeg")
            return Response(
                content=resp.content,
                media_type=ct,
                headers={"Cache-Control": "no-store"},
            )
        raise HTTPException(502, f"Camera returned HTTP {resp.status_code}")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(502, str(e))


# ── MJPEG stream proxy (requires opencv-python-headless) ──────────────────

# Per-URL streamer instances (shared across clients)
_streamers: dict = {}
_streamers_lock = threading.Lock()


class _MJPEGStreamer:
    """Reads RTSP/HTTP via OpenCV and serves MJPEG frames."""

    def __init__(self, url: str):
        self.url = url
        self.frame: Optional[bytes] = None
        self.clients: int = 0
        self._running = False
        self._thread: Optional[threading.Thread] = None

    def start(self):
        if self._running:
            return
        self._running = True
        self._thread = threading.Thread(target=self._capture, daemon=True)
        self._thread.start()

    def stop(self):
        self._running = False

    def _capture(self):
        cap = cv2.VideoCapture(self.url)
        cap.set(cv2.CAP_PROP_BUFFERSIZE, 2)
        while self._running:
            ret, frame = cap.read()
            if not ret:
                time.sleep(0.2)
                # Attempt reconnect
                cap.release()
                cap = cv2.VideoCapture(self.url)
                cap.set(cv2.CAP_PROP_BUFFERSIZE, 2)
                continue
            _, jpg = cv2.imencode(".jpg", frame, [cv2.IMWRITE_JPEG_QUALITY, 60])
            self.frame = jpg.tobytes()
        cap.release()

    def generate(self):
        self.clients += 1
        try:
            while self._running:
                if self.frame:
                    data = self.frame
                    yield (
                        b"--frame\r\n"
                        b"Content-Type: image/jpeg\r\n"
                        b"Content-Length: " + str(len(data)).encode() + b"\r\n\r\n"
                        + data + b"\r\n"
                    )
                time.sleep(0.04)  # ~25 fps cap
        finally:
            self.clients -= 1
            if self.clients <= 0:
                with _streamers_lock:
                    self.stop()
                    _streamers.pop(self.url, None)


@router.get("/stream/mjpeg")
def stream_mjpeg(url: str = Query(..., description="RTSP or MJPEG source URL")):
    """
    Live MJPEG stream proxy. Reads RTSP via OpenCV and serves browser-compatible MJPEG.
    Requires: pip install opencv-python-headless
    """
    if not HAS_CV2:
        raise HTTPException(
            503,
            "opencv-python-headless is not installed on the hub. "
            "Run: pip install opencv-python-headless  then restart the hub."
        )
    with _streamers_lock:
        if url not in _streamers:
            streamer = _MJPEGStreamer(url)
            streamer.start()
            _streamers[url] = streamer
        streamer = _streamers[url]

    return StreamingResponse(
        streamer.generate(),
        media_type="multipart/x-mixed-replace; boundary=frame",
        headers={"Cache-Control": "no-cache", "Connection": "keep-alive"},
    )


# ── Camera discovery ──────────────────────────────────────────────────────

@router.post("/discover")
async def discover_cameras(body: DiscoverBody = None):
    """
    Discover IP cameras on the local network:
    1. Scan subnet for devices responding on camera ports
    2. Probe HTTP headers/content to identify brand
    3. Send ONVIF WS-Discovery multicast
    """
    subnet = (body.subnet if body else None) or _local_subnet()
    log.info(f"Camera discovery on subnet {subnet}.x")

    async def check_host(host: str):
        for port in [80, 8080, 8000, 88]:
            try:
                reader, writer = await asyncio.wait_for(
                    asyncio.open_connection(host, port), timeout=0.35
                )
                writer.close()
                try:
                    await writer.wait_closed()
                except Exception:
                    pass
                driver = await _probe_brand(host, port)
                if driver:
                    return {"ip": host, "port": port, "driver": driver}
            except Exception:
                pass
        return None

    tasks = [check_host(f"{subnet}.{i}") for i in range(1, 255)]
    results = await asyncio.gather(*tasks, return_exceptions=True)
    http_found = [r for r in results if r and not isinstance(r, Exception)]

    onvif_found = await _onvif_discover()
    for cam in onvif_found:
        if not any(f["ip"] == cam["ip"] for f in http_found):
            http_found.append(cam)

    return {"cameras": http_found, "subnet": subnet}


def _local_subnet() -> str:
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ".".join(ip.split(".")[:3])
    except Exception:
        return "192.168.1"


async def _probe_brand(ip: str, port: int) -> Optional[str]:
    """Identify camera brand from HTTP response."""
    try:
        async with httpx.AsyncClient(timeout=1.5, verify=False) as client:
            r = await client.get(f"http://{ip}:{port}/")
        server = r.headers.get("server", "").lower()
        body_lo = r.text.lower()[:600]

        if "hikvision" in server or "hikvision" in body_lo:
            return "hikvision"
        if "dahua" in server or "dahua" in body_lo:
            return "dahua"
        if "reolink" in body_lo:
            return "reolink"
        if "foscam" in body_lo:
            return "foscam"
        if "amcrest" in body_lo:
            return "amcrest"
        if "tp-link" in server or "tapo" in body_lo:
            return "tapo"

        # ONVIF probe
        r2 = await client.get(f"http://{ip}:{port}/onvif/device_service", timeout=1.0)
        if r2.status_code in (200, 400, 401, 405):
            return "onvif"
    except Exception:
        pass
    return None


async def _onvif_discover() -> List[dict]:
    """WS-Discovery broadcast for ONVIF cameras (UDP multicast)."""
    WS_DISCOVERY = (
        '<?xml version="1.0" encoding="UTF-8"?>'
        '<e:Envelope xmlns:e="http://www.w3.org/2003/05/soap-envelope"'
        ' xmlns:w="http://schemas.xmlsoap.org/ws/2004/08/addressing"'
        ' xmlns:d="http://schemas.xmlsoap.org/ws/2005/04/discovery"'
        ' xmlns:dn="http://www.onvif.org/ver10/network/wsdl">'
        "<e:Header>"
        "<w:MessageID>uuid:fantatech-cam-discovery</w:MessageID>"
        "<w:To>urn:schemas-xmlsoap-org:ws:2005:04:discovery</w:To>"
        "<w:Action>http://schemas.xmlsoap.org/ws/2005/04/discovery/Probe</w:Action>"
        "</e:Header>"
        "<e:Body><d:Probe><d:Types>dn:NetworkVideoTransmitter</d:Types></d:Probe></e:Body>"
        "</e:Envelope>"
    ).encode()

    found = []
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        sock.settimeout(2.0)
        sock.sendto(WS_DISCOVERY, ("239.255.255.250", 3702))
        while True:
            try:
                _, addr = sock.recvfrom(4096)
                ip = addr[0]
                if not any(f["ip"] == ip for f in found):
                    found.append({"ip": ip, "port": 80, "driver": "onvif"})
            except socket.timeout:
                break
        sock.close()
    except Exception as e:
        log.debug(f"ONVIF discovery: {e}")
    return found
