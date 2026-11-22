#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRIDGE_PY="${SCRIPT_DIR}/ordnance_cot_bridge.py"

echo "=== 1. Dry-Run XML Generation Test ==="
printf "PLI:BRAVO2:39.9612,-82.9988,275\nPIN:LZ1:39.9650,-83.0010:a-u-G\n" \
  | python3 "${BRIDGE_PY}" --stdin --dry-run

echo ""
echo "=== 2. Live Injection into Local OpenTAKServer (127.0.0.1:8088) ==="
printf "PLI:BRAVO2:39.9612,-82.9988,275\nPIN:LZ1:39.9650,-83.0010:a-u-G\n" \
  | python3 "${BRIDGE_PY}" --stdin

echo "Done. Check your connected ATAK / iTAK EUD for BRAVO2 and LZ1!"