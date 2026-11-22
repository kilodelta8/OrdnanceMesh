#!/usr/bin/env bash
set -euo pipefail

STATE_FILE="/run/ordnance-wan.state"
PREV_STATE="$(cat "$STATE_FILE" 2>/dev/null || echo "OFFLINE")"

# Check two public IPs so a single host outage never triggers false failover
if ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1 || ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
  NEW_STATE="ONLINE"
else
  NEW_STATE="OFFLINE"
fi

if [ "$NEW_STATE" != "$PREV_STATE" ]; then
  echo "$NEW_STATE" > "$STATE_FILE"
  logger -t ordnance-wan "Starlink WAN state changed: ${PREV_STATE} -> ${NEW_STATE}"
  # Hook future Phase 3/5 actions here (e.g., TAK federation or Project NOMAD sync)
fi