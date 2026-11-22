#!/usr/bin/env bash
set -euo pipefail

STATE_FILE="/run/ordnance-watchdog.fails"
MAX_FAILS=3

healthy=true
[ -e /dev/ordnance-meshtastic ] || healthy=false
[ -e /dev/ordnance-meshcore ]   || healthy=false
curl -fsS --max-time 4 http://127.0.0.1:8080/api/health >/dev/null 2>&1 || healthy=false

if $healthy; then
  rm -f "$STATE_FILE"
  exit 0
fi

fails=$(( $(cat "$STATE_FILE" 2>/dev/null || echo 0) + 1 ))
echo "$fails" > "$STATE_FILE"
logger -t ordnance-watchdog "Bridge health check failed (${fails}/${MAX_FAILS})"

if [ "$fails" -ge "$MAX_FAILS" ]; then
  logger -t ordnance-watchdog "Threshold reached; restarting ordnance-bridge.service"
  rm -f "$STATE_FILE"
  systemctl restart ordnance-bridge.service
fi