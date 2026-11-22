#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="/var/log/ordnance-telemetry.csv"

if [ ! -f "$LOG_FILE" ]; then
  echo "timestamp_utc,cpu_temp_c,throttled_hex,wan_state,bridge_active,meshtastic_usb,meshcore_usb" > "$LOG_FILE"
fi

TS="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
TEMP_RAW="$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0)"
CPU_TEMP_C="$(awk "BEGIN {printf \"%.1f\", ${TEMP_RAW}/1000}")"
THROTTLED="$(vcgencmd get_throttled 2>/dev/null | cut -d= -f2 || echo "unknown")"
WAN_STATE="$(cat /run/ordnance-wan.state 2>/dev/null || echo "UNKNOWN")"
BRIDGE_UP="$(systemctl is-active ordnance-bridge.service 2>/dev/null || echo "inactive")"
MESH_DEV="$( [ -e /dev/ordnance-meshtastic ] && echo "OK" || echo "MISSING" )"
CORE_DEV="$( [ -e /dev/ordnance-meshcore ] && echo "OK" || echo "MISSING" )"

echo "${TS},${CPU_TEMP_C},${THROTTLED},${WAN_STATE},${BRIDGE_UP},${MESH_DEV},${CORE_DEV}" >> "$LOG_FILE"