#!/usr/bin/env python3
"""OrdnanceMesh MeshCore-to-ATAK Cursor-on-Target (CoT 2.0) Bridge.

Tails ordnance-bridge.service logs (or --stdin for testing), parses compact
MeshCore PLI and PIN beacons, deduplicates repeated log lines, and injects
CoT 2.0 XML into local OpenTAKServer.

Beacon grammar:
  PLI:<CALLSIGN>:<LAT>,<LON>[,<ALT_M>]
  PIN:<LABEL>:<LAT>,<LON>[:<COT_TYPE>]
"""

import argparse
import datetime
import logging
import os
import re
import socket
import subprocess
import sys
import time
from xml.sax.saxutils import escape

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [ordnance-cot] %(levelname)s: %(message)s",
)
log = logging.getLogger("ordnance-cot")

OTS_HOST = os.environ.get("OTS_COT_HOST", "127.0.0.1")
OTS_PORT = int(os.environ.get("OTS_COT_PORT", "8088"))
STALE_MINUTES = int(os.environ.get("COT_STALE_MINUTES", "15"))
DEDUPE_SECONDS = int(os.environ.get("COT_DEDUPE_SECONDS", "10"))

PLI_RE = re.compile(
    r"\bPLI:([A-Za-z0-9_-]{1,24}):(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)(?:,(-?\d+(?:\.\d+)?))?\b"
)
PIN_RE = re.compile(
    r"\bPIN:([A-Za-z0-9_-]{1,32}):(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)(?::([a-zA-Z0-9-]{3,24}))?\b"
)

RECENT_EVENTS: dict[str, float] = {}


def valid_coords(lat: float, lon: float) -> bool:
    return -90.0 <= lat <= 90.0 and -180.0 <= lon <= 180.0


def is_duplicate(dedupe_key: str) -> bool:
    now = time.monotonic()
    # Prune expired keys periodically so memory stays bounded during multi-week runs
    if len(RECENT_EVENTS) > 256:
        expired = [k for k, ts in RECENT_EVENTS.items() if (now - ts) >= DEDUPE_SECONDS]
        for k in expired:
            del RECENT_EVENTS[k]

    prev = RECENT_EVENTS.get(dedupe_key)
    if prev is not None and (now - prev) < DEDUPE_SECONDS:
        return True
    RECENT_EVENTS[dedupe_key] = now
    return False


def build_cot_xml(uid: str, callsign: str, cot_type: str, lat: float, lon: float, alt: float = 0.0) -> str:
    now = datetime.datetime.now(datetime.timezone.utc)
    stale = now + datetime.timedelta(minutes=STALE_MINUTES)
    fmt = "%Y-%m-%dT%H:%M:%S.%fZ"
    t_now = now.strftime(fmt)
    t_stale = stale.strftime(fmt)
    safe_uid = escape(uid)
    safe_cs = escape(callsign)
    safe_type = escape(cot_type)

    return (
        f'<event version="2.0" uid="{safe_uid}" type="{safe_type}" '
        f'time="{t_now}" start="{t_now}" stale="{t_stale}" how="m-g">'
        f'<point lat="{lat:.6f}" lon="{lon:.6f}" hae="{alt:.1f}" ce="15.0" le="15.0"/>'
        f'<detail>'
        f'<contact callsign="{safe_cs}"/>'
        f'<remarks>Bridged via OrdnanceMesh MeshCore-to-CoT</remarks>'
        f'</detail>'
        f'</event>\n'
    )


def parse_line(line: str):
    m = PLI_RE.search(line)
    if m:
        cs, lat_s, lon_s, alt_s = m.groups()
        lat, lon, alt = float(lat_s), float(lon_s), float(alt_s) if alt_s else 0.0
        if valid_coords(lat, lon):
            uid = f"ORD-MC-PLI-{cs}"
            key = f"{uid}:{lat:.5f}:{lon:.5f}:{alt:.1f}"
            return key, build_cot_xml(uid, cs, "a-f-G-U-C", lat, lon, alt)

    m = PIN_RE.search(line)
    if m:
        label, lat_s, lon_s, cot_type = m.groups()
        lat, lon = float(lat_s), float(lon_s)
        if valid_coords(lat, lon):
            uid = f"ORD-MC-PIN-{label}"
            c_type = cot_type or "b-m-p-s-m"
            key = f"{uid}:{lat:.5f}:{lon:.5f}:{c_type}"
            return key, build_cot_xml(uid, label, c_type, lat, lon, 0.0)
    return None, None


def send_cot(xml_payload: str, host: str = OTS_HOST, port: int = OTS_PORT) -> bool:
    try:
        with socket.create_connection((host, port), timeout=5) as sock:
            sock.sendall(xml_payload.encode("utf-8"))
        return True
    except OSError as exc:
        log.error("Failed to send CoT to %s:%s: %s", host, port, exc)
        return False


def stream_journal(unit: str = "ordnance-bridge.service"):
    cmd = ["journalctl", "-u", unit, "-f", "-n", "0", "-o", "cat"]
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    assert proc.stdout is not None
    for line in proc.stdout:
        yield line.strip()


def main():
    parser = argparse.ArgumentParser(description="OrdnanceMesh MeshCore-to-CoT Bridge")
    parser.add_argument("--stdin", action="store_true", help="Read lines from stdin instead of journalctl")
    parser.add_argument("--dry-run", action="store_true", help="Print CoT XML instead of sending over TCP")
    parser.add_argument("--unit", default="ordnance-bridge.service", help="systemd unit to tail")
    args = parser.parse_args()

    source = (line.strip() for line in sys.stdin) if args.stdin else stream_journal(args.unit)
    log.info(
        "Started CoT bridge (target=%s:%s, dedupe=%ss, dry_run=%s)",
        OTS_HOST,
        OTS_PORT,
        DEDUPE_SECONDS,
        args.dry_run,
    )

    for line in source:
        dedupe_key, cot_xml = parse_line(line)
        if not cot_xml or not dedupe_key:
            continue
        if is_duplicate(dedupe_key):
            log.debug("Suppressed duplicate beacon: %s", dedupe_key)
            continue
        if args.dry_run:
            print(cot_xml, end="", flush=True)
        else:
            if send_cot(cot_xml):
                log.info("Injected CoT event: %s", dedupe_key)


if __name__ == "__main__":
    main()