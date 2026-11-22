#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC_DIR="${REPO_ROOT}/rpi5/src"

echo "[1/4] Installing systemd-networkd Starlink failover configs..."
mkdir -p /etc/systemd/network
cp "${SRC_DIR}/network/10-starlink-wan.network" /etc/systemd/network/
cp "${SRC_DIR}/network/20-ordnance-lan.network" /etc/systemd/network/

echo "[2/4] Installing Starlink WAN monitor..."
cp "${SRC_DIR}/ordnance-wan-monitor.sh" /usr/local/bin/ordnance-wan-monitor.sh
chmod +x /usr/local/bin/ordnance-wan-monitor.sh
cp "${SRC_DIR}/ordnance-wan-monitor.service" /etc/systemd/system/
cp "${SRC_DIR}/ordnance-wan-monitor.timer" /etc/systemd/system/

echo "[3/4] Installing 48-hour thermal & health telemetry logger..."
cp "${SRC_DIR}/ordnance-telemetry.sh" /usr/local/bin/ordnance-telemetry.sh
chmod +x /usr/local/bin/ordnance-telemetry.sh
cp "${SRC_DIR}/ordnance-telemetry.service" /etc/systemd/system/
cp "${SRC_DIR}/ordnance-telemetry.timer" /etc/systemd/system/

echo "[4/4] Enabling systemd-networkd & timers..."
systemctl daemon-reload
systemctl enable --now systemd-networkd
systemctl enable --now ordnance-wan-monitor.timer ordnance-telemetry.timer

echo "Phase 2 software layer installed."
echo "Inspect live soak log anytime with: tail -f /var/log/ordnance-telemetry.csv"