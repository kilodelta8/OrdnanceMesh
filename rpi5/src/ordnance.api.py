#!/usr/bin/env python3
"""OrdnanceMesh Relay Telemetry, Unified Chat & CoT Beacon API (:8081).

Endpoints:
  GET  /api/v1/status    -> Live RPi 5 thermal, Starlink WAN, and dual-radio health
  POST /api/v1/beacon    -> Injects PLI or PIN CoT 2.0 XML into local OpenTAKServer
  GET  /api/v1/messages  -> Returns recent unified [MT] / [MC] / [APP] messages
  POST /api/v1/messages  -> Stores LAN message and forwards to AMMB local API if available
"""

import collections
import datetime
import json
import logging
import os
import re
import socket
import subprocess
import threading
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from xml.sax.saxutils import escape

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [ordnance-api] %(levelname)s: %(message)s",
)
log = logging.getLogger("ordnance-api")

BIND_HOST = os.environ.get("ORDNANCE_API_HOST", "0.0.0.0")
BIND_PORT = int(os.environ.get("ORDNANCE_API_PORT", "8081"))
OTS_HOST = os.environ.get("OTS_COT_HOST", "127.0.0.1")
OTS_PORT = int(os.environ.get("OTS_COT_PORT", "8088"))
STALE_MINUTES = int(os.environ.get("COT_STALE_MINUTES", "15"))
AMMB_SEND_URL = os.environ.get("AMMB_SEND_URL", "http://127.0.0.1:8080/api/send")

MESSAGES = collections.deque(maxlen=200)
MSG_LOCK = threading.Lock()
MSG_SEQ = 0


def append_message(net: str, sender: str, text: str) -> dict:
    global MSG_SEQ
    with MSG_LOCK:
        MSG_SEQ += 1
        entry = {
            "id": MSG_SEQ,
            "ts": datetime.datetime.now(datetime.timezone.utc).strftime("%H:%M:%SZ"),
            "net": net,
            "sender": sender[:24],
            "text": text[:240],
        }
        MESSAGES.append(entry)
        return entry


def tail_bridge_messages():
    """Background reader that mirrors bridged Meshtastic/MeshCore text into MESSAGES."""
    cmd = ["journalctl", "-u", "ordnance-bridge.service", "-f", "-n", "30", "-o", "cat"]
    try:
        proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
        assert proc.stdout is not None
        for raw in proc.stdout:
            line = raw.strip()
            if not line:
                continue
            low = line.lower()
            if "meshtastic" in low and ("rx" in low or "msg" in low or "text" in low):
                append_message("MT", "Meshtastic", line)
            elif "meshcore" in low and ("rx" in low or "msg" in low or "text" in low):
                append_message("MC", "MeshCore", line)
    except OSError as exc:
        log.warning("journalctl bridge tail unavailable: %s", exc)


def forward_to_ammb(sender: str, text: str) -> bool:
    payload = json.dumps({"sender": sender, "text": f"[{sender}] {text}"}).encode("utf-8")
    req = urllib.request.Request(
        AMMB_SEND_URL,
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=3) as resp:
            return 200 <= resp.status < 300
    except (OSError, urllib.error.URLError):
        return False


def read_cpu_temp() -> float:
    try:
        with open("/sys/class/thermal/thermal_zone0/temp", "r", encoding="utf-8") as f:
            return round(int(f.read().strip()) / 1000.0, 1)
    except OSError:
        return -1.0


def read_throttled() -> str:
    try:
        out = subprocess.check_output(["vcgencmd", "get_throttled"], text=True, timeout=2).strip()
        return out.split("=", 1)[-1] if "=" in out else out
    except (OSError, subprocess.SubprocessError):
        return "unknown"


def read_wan_state() -> str:
    try:
        with open("/run/ordnance-wan.state", "r", encoding="utf-8") as f:
            return f.read().strip() or "UNKNOWN"
    except OSError:
        return "UNKNOWN"


def service_active(unit: str) -> bool:
    try:
        return subprocess.run(["systemctl", "is-active", "--quiet", unit], timeout=2).returncode == 0
    except (OSError, subprocess.SubprocessError):
        return False


def build_cot_xml(b_type: str, callsign: str, lat: float, lon: float, alt: float, cot_type: str) -> str:
    now = datetime.datetime.now(datetime.timezone.utc)
    stale = now + datetime.timedelta(minutes=STALE_MINUTES)
    fmt = "%Y-%m-%dT%H:%M:%S.%fZ"
    t_now, t_stale = now.strftime(fmt), stale.strftime(fmt)
    uid = escape(f"ORD-APP-{b_type}-{callsign}")
    return (
        f'<event version="2.0" uid="{uid}" type="{escape(cot_type)}" '
        f'time="{t_now}" start="{t_now}" stale="{t_stale}" how="m-g">'
        f'<point lat="{lat:.6f}" lon="{lon:.6f}" hae="{alt:.1f}" ce="15.0" le="15.0"/>'
        f'<detail><contact callsign="{escape(callsign)}"/>'
        f'<remarks>Sent via OrdnanceMesh Mobile App</remarks></detail>'
        f'</event>\n'
    )


def send_cot(xml_payload: str) -> tuple[bool, str]:
    try:
        with socket.create_connection((OTS_HOST, OTS_PORT), timeout=4) as sock:
            sock.sendall(xml_payload.encode("utf-8"))
        return True, "ok"
    except OSError as exc:
        return False, str(exc)


class OrdnanceAPIHandler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        log.info("%s - %s", self.address_string(), fmt % args)

    def _send_json(self, code: int, payload):
        body = json.dumps(payload).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self._send_json(204, {})

    def do_GET(self):
        if self.path == "/api/v1/status":
            self._send_json(200, {
                "timestamp_utc": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
                "cpu_temp_c": read_cpu_temp(),
                "throttled_hex": read_throttled(),
                "wan_state": read_wan_state(),
                "bridge_active": service_active("ordnance-bridge.service"),
                "cot_bridge_active": service_active("ordnance-cot-bridge.service"),
                "meshtastic_usb": os.path.exists("/dev/ordnance-meshtastic"),
                "meshcore_usb": os.path.exists("/dev/ordnance-meshcore"),
            })
        elif self.path == "/api/v1/messages":
            with MSG_LOCK:
                self._send_json(200, {"messages": list(MESSAGES)})
        else:
            self._send_json(404, {"error": "not_found"})

    def do_POST(self):
        length = int(self.headers.get("Content-Length", "0"))
        if length <= 0 or length > 4096:
            self._send_json(400, {"error": "invalid_payload_size"})
            return

        try:
            data = json.loads(self.rfile.read(length).decode("utf-8"))
        except (ValueError, json.JSONDecodeError) as exc:
            self._send_json(400, {"error": f"bad_json: {exc}"})
            return

        if self.path == "/api/v1/messages":
            sender = re.sub(r"[^A-Za-z0-9_-]", "", str(data.get("sender", "OPS")))[:24] or "OPS"
            text = str(data.get("text", "")).strip()[:240]
            if not text:
                self._send_json(400, {"error": "empty_text"})
                return
            entry = append_message("APP", sender, text)
            forwarded = forward_to_ammb(sender, text)
            self._send_json(200, {"status": "ok", "forwarded_to_rf": forwarded, "message": entry})
            return

        if self.path == "/api/v1/beacon":
            try:
                b_type = str(data.get("type", "PLI")).upper()
                callsign = str(data.get("callsign", "")).strip()[:24]
                lat, lon = float(data["lat"]), float(data["lon"])
                alt = float(data.get("alt", 0.0))
            except (KeyError, TypeError, ValueError) as exc:
                self._send_json(400, {"error": f"bad_request: {exc}"})
                return

            if b_type not in ("PLI", "PIN") or not callsign or not (-90.0 <= lat <= 90.0 and -180.0 <= lon <= 180.0):
                self._send_json(400, {"error": "invalid_beacon_fields"})
                return

            default_cot = "a-f-G-U-C" if b_type == "PLI" else "b-m-p-s-m"
            cot_type = str(data.get("cot_type") or default_cot)[:24]
            ok, msg = send_cot(build_cot_xml(b_type, callsign, lat, lon, alt, cot_type))
            if ok:
                self._send_json(200, {"status": "injected", "type": b_type, "callsign": callsign})
            else:
                self._send_json(502, {"error": "ots_unreachable", "detail": msg})
            return

        self._send_json(404, {"error": "not_found"})


def main():
    threading.Thread(target=tail_bridge_messages, daemon=True).start()
    server = ThreadingHTTPServer((BIND_HOST, BIND_PORT), OrdnanceAPIHandler)
    log.info("OrdnanceMesh Relay API listening on %s:%s", BIND_HOST, BIND_PORT)
    server.serve_forever()


if __name__ == "__main__":
    main()