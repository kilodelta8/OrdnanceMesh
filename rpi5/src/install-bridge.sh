#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BRIDGE_DIR="/opt/ordnance-bridge"
CONF_DIR="/etc/ordnancemesh"

echo "[1/6] Installing system prerequisites..."
apt-get update
apt-get install -y python3 python3-venv python3-pip git curl

echo "[2/6] Creating dedicated 'ordnance' service user..."
id -u ordnance &>/dev/null || useradd --system --create-home --groups dialout ordnance
usermod -aG dialout ordnance

echo "[3/6] Installing AMMB into ${BRIDGE_DIR}..."
mkdir -p "${BRIDGE_DIR}" "${CONF_DIR}"
if [ ! -d "${BRIDGE_DIR}/.git" ]; then
  git clone https://github.com/AkitaEngineering/Akita-Meshtastic-Meshcore-Bridge.git "${BRIDGE_DIR}"
else
  git -C "${BRIDGE_DIR}" pull --ff-only
fi

python3 -m venv "${BRIDGE_DIR}/.venv"
"${BRIDGE_DIR}/.venv/bin/pip" install --upgrade pip
"${BRIDGE_DIR}/.venv/bin/pip" install -r "${BRIDGE_DIR}/requirements.txt"

echo "[4/6] Installing udev rules & config template..."
cp -n "${REPO_ROOT}/bridge/99-ordnance-radios.rules" /etc/udev/rules.d/99-ordnance-radios.rules
cp -n "${REPO_ROOT}/bridge/config.ini.example" "${CONF_DIR}/bridge.ini"
udevadm control --reload-rules && udevadm trigger

echo "[5/6] Installing systemd unit..."
cp "${REPO_ROOT}/rpi5/src/ordnance-bridge.service" /etc/systemd/system/ordnance-bridge.service
chown -R ordnance:dialout "${BRIDGE_DIR}" "${CONF_DIR}"
systemctl daemon-reload
systemctl enable ordnance-bridge.service

echo "[6/6] Done! Next steps:"
echo "  1. Edit /etc/udev/rules.d/99-ordnance-radios.rules with your two USB radio serials."
echo "  2. Reload udev: sudo udevadm control --reload-rules && sudo udevadm trigger"
echo "  3. Run preflight: sudo -u ordnance ${BRIDGE_DIR}/.venv/bin/python ${BRIDGE_DIR}/run_bridge_tui.py --check --config ${CONF_DIR}/bridge.ini"
echo "  4. Start bridge: sudo systemctl start ordnance-bridge.service"