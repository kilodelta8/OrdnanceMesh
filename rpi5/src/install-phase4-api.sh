#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BRIDGE_DIR="/opt/ordnance-bridge"

echo "[1/3] Installing ordnance_api.py & systemd unit..."
mkdir -p "${BRIDGE_DIR}"
cp "${REPO_ROOT}/rpi5/src/ordnance_api.py" "${BRIDGE_DIR}/ordnance_api.py"
chmod +x "${BRIDGE_DIR}/ordnance_api.py"
chown ordnance:ordnance "${BRIDGE_DIR}/ordnance_api.py"

cp "${REPO_ROOT}/rpi5/src/ordnance-api.service" /etc/systemd/system/ordnance-api.service
systemctl daemon-reload
systemctl enable --now ordnance-api.service

echo "[2/3] Checking live telemetry JSON (127.0.0.1:8081)..."
sleep 2
curl -fsS http://127.0.0.1:8081/api/v1/status | python3 -m json.tool

echo "[3/3] Done! Test beacon injection anytime with:"
echo "  curl -s -X POST http://10.88.0.1:8081/api/v1/beacon -H 'Content-Type: application/json' -d '{\"type\":\"PLI\",\"callsign\":\"ALPHA1\",\"lat\":39.9612,\"lon\":-82.9988,\"alt\":275}'"