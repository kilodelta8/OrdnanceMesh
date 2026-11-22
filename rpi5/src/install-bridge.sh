#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BRIDGE_DIR="/opt/ordnance-bridge"
CONF_DIR="/etc/ordnancemesh"
# Pin to a verified AMMB commit SHA once tested on your bench (default: main)
AMMB_REF="${AMMB_REF:-main}"

echo "[1/7] Installing system prerequisites..."
apt-get update
apt-get install -y python3 python3-venv python3-pip git curl

echo "[2/7] Creating dedicated 'ordnance' service user..."
id -u ordnance &>/dev/null || useradd --system --create-home --groups dialout ordnance
usermod -aG dialout ordnance

echo "[3/7] Cloning & pinning AMMB (${AMMB_REF}) into ${BRIDGE_DIR}..."
mkdir -p "${BRIDGE_DIR}" "${CONF_DIR}"
if [ ! -d "${BRIDGE_DIR}/.git" ]; then
  git clone https://github.com/AkitaEngineering/Akita-Meshtastic-Meshcore-Bridge.git "${BRIDGE_DIR}"
fi
git -C "${BRIDGE_DIR}" fetch --all --tags
git -C "${BRIDGE_DIR}" checkout "${AMMB_REF}"

python3 -m venv "${BRIDGE_DIR}/.venv"
"${BRIDGE_DIR}/.venv/bin/pip" install --upgrade pip
"${BRIDGE_DIR}/.venv/bin/pip" install -r "${BRIDGE_DIR}/requirements.txt"

echo "[4/7] Installing udev rules & config template..."
cp -n "${REPO_ROOT}/bridge/99-ordnance-radios.rules" /etc/udev/rules.d/99-ordnance-radios.rules
cp -n "${REPO_ROOT}/bridge/config.ini.example" "${CONF_DIR}/bridge.ini"
udevadm control --reload-rules && udevadm trigger

echo "[5/7] Installing bridge service & health watchdog..."
cp "${REPO_ROOT}/rpi5/src/ordnance-bridge.service" /etc/systemd/system/ordnance-bridge.service
cp "${REPO_ROOT}/rpi5/src/ordnance-watchdog.sh" /usr/local/bin/ordnance-watchdog.sh
chmod +x /usr/local/bin/ordnance-watchdog.sh
cp "${REPO_ROOT}/rpi5/src/ordnance-watchdog.service" /etc/systemd/system/ordnance-watchdog.service
cp "${REPO_ROOT}/rpi5/src/ordnance-watchdog.timer" /etc/systemd/system/ordnance-watchdog.timer

echo "[6/7] Capping systemd-journald storage at 100M..."
mkdir -p /etc/systemd/journald.conf.d
cat <<'EOF' > /etc/systemd/journald.conf.d/ordnance.conf
[Journal]
SystemMaxUse=100M
RuntimeMaxUse=50M
EOF
systemctl restart systemd-journald

echo "[7/7] Enabling services..."
chown -R ordnance:dialout "${BRIDGE_DIR}" "${CONF_DIR}"
systemctl daemon-reload
systemctl enable ordnance-bridge.service ordnance-watchdog.timer

echo "Done! Record your tested AMMB commit SHA with: git -C ${BRIDGE_DIR} rev-parse HEAD"