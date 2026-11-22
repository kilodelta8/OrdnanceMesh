#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ONLY_PHASE="${2:-all}"

if [ "${EUID}" -ne 0 ]; then
  echo "Error: Run with sudo, e.g.:"
  echo "  sudo AP_PASS=\"YourStrongTeamKey123\" bash $0"
  exit 1
fi

if [ "${1:-}" = "--only" ] && [ -n "${2:-}" ]; then
  ONLY_PHASE="$2"
else
  ONLY_PHASE="all"
fi

run_phase() {
  [ "$ONLY_PHASE" = "all" ] || [ "$ONLY_PHASE" = "$1" ]
}

if run_phase 1; then
  echo "=========================================="
  echo "  ORDNANCEMESH — PHASE 1 (DUAL-RADIO BRIDGE)"
  echo "=========================================="
  bash "${REPO_ROOT}/rpi5/src/install-bridge.sh"
fi

if run_phase 2; then
  echo "=========================================="
  echo "  ORDNANCEMESH — PHASE 2 (NETWORK & TELEMETRY)"
  echo "=========================================="
  # Ensure Wi-Fi is unblocked on fresh Raspberry Pi OS before creating AP
  if command -v raspi-config >/dev/null 2>&1; then
    raspi-config nonint do_wifi_country "${WIFI_COUNTRY:-US}" || true
  fi
  command -v rfkill >/dev/null 2>&1 && rfkill unblock wifi || true

  bash "${REPO_ROOT}/rpi5/src/setup-network.sh"
  bash "${REPO_ROOT}/rpi5/src/install-phase2.sh"
fi

if run_phase 3; then
  echo "=========================================="
  echo "  ORDNANCEMESH — PHASE 3 (ATAK COT & VOICE)"
  echo "=========================================="
  bash "${REPO_ROOT}/atak/install-phase3.sh"
fi

if run_phase 4; then
  echo "=========================================="
  echo "  ORDNANCEMESH — PHASE 4 (MOBILE RELAY API)"
  echo "=========================================="
  bash "${REPO_ROOT}/rpi5/src/install-phase4-api.sh"

  echo "[Firewall] Locking Relay API (:8081) to local LAN/Wi-Fi only..."
  apt-get install -y ufw >/dev/null
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow in on wlan0 to any port 22,80,443,8081,8089,8443,64738 proto tcp
  ufw allow in on wlan0 to any port 64738 proto udp
  ufw allow in on eth1  to any port 22,80,443,8081,8089,8443,64738 proto tcp
  ufw allow in on eth1  to any port 64738 proto udp
  ufw --force enable
fi

echo ""
echo "=========================================="
echo "  OrdnanceMesh install complete!"
echo "  Next: Follow Chapter 1.2 in docs/Phase6-field-test.md to lock USB serials."
echo "=========================================="