#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BRIDGE_DIR="/opt/ordnance-bridge"

echo "[1/4] Granting 'ordnance' user journal read permissions..."
id -u ordnance &>/dev/null || useradd --system --create-home --groups dialout ordnance
usermod -aG systemd-journal ordnance

echo "[2/4] Installing MeshCore-to-CoT bridge & systemd service..."
mkdir -p "${BRIDGE_DIR}"
cp "${REPO_ROOT}/bridge/cot-bridge/ordnance_cot_bridge.py" "${BRIDGE_DIR}/ordnance_cot_bridge.py"
chmod +x "${BRIDGE_DIR}/ordnance_cot_bridge.py"
chown ordnance:ordnance "${BRIDGE_DIR}/ordnance_cot_bridge.py"

cp "${REPO_ROOT}/bridge/cot-bridge/ordnance-cot-bridge.service" /etc/systemd/system/ordnance-cot-bridge.service
systemctl daemon-reload
systemctl enable --now ordnance-cot-bridge.service

echo "[3/4] Optional: Install local Mumble VoIP server for IP MANET / Wi-Fi voice?"
read -r -p "Install mumble-server now? [y/N]: " INSTALL_MUMBLE
if [[ "${INSTALL_MUMBLE}" =~ ^[Yy]$ ]]; then
  apt-get update && apt-get install -y mumble-server
  systemctl enable --now mumble-server
  echo "  -> Mumble server active on 10.88.0.1:64738 (set serverpassword in /etc/mumble-server.ini)"
fi

echo "[4/4] Optional: Run official OpenTAKServer Raspberry Pi installer?"
read -r -p "Run OpenTAKServer installer now? (requires internet/Starlink) [y/N]: " INSTALL_OTS
if [[ "${INSTALL_OTS}" =~ ^[Yy]$ ]]; then
  sudo -u "${SUDO_USER:-$USER}" bash -c 'curl -Ls https://i.opentakserver.io/raspberry_pi_installer | bash -'
fi

echo "Phase 3 setup complete. Test CoT injection with: bash bridge/cot-bridge/test-cot-bridge.sh"