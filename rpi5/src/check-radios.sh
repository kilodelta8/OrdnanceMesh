#!/usr/bin/env bash
set -euo pipefail

echo "=== OrdnanceMesh Radio Symlinks ==="
for dev in /dev/ordnance-meshtastic /dev/ordnance-meshcore; do
  if [ -e "$dev" ]; then
    echo "  [OK] $dev -> $(readlink -f "$dev")"
  else
    echo "  [MISSING] $dev"
  fi
done

echo ""
echo "=== Bridge Service Status ==="
systemctl is-active --quiet ordnance-bridge.service \
  && echo "  [OK] ordnance-bridge.service is active" \
  || echo "  [DOWN] ordnance-bridge.service is not running"

echo ""
echo "=== Local Bridge API (127.0.0.1:8080) ==="
curl -fsS --max-time 3 http://127.0.0.1:8080/api/health 2>/dev/null \
  && echo "" \
  || echo "  [UNREACHABLE] API not responding on port 8080"