#!/usr/bin/env bash
set -euo pipefail

AP_SSID="${AP_SSID:-OrdnanceBox}"
AP_PASS="${AP_PASS:-}"

if [ "${#AP_PASS}" -lt 8 ]; then
  echo "Error: Set AP_PASS (at least 8 characters), e.g.:"
  echo "  sudo AP_PASS=\"MyStrongKey123\" bash $0"
  exit 1
fi

# 1. Configure Starlink Mini WAN on eth0 (DHCP, metric 100, fast offline timeout)
ETH_CON="$(nmcli -t -f NAME,DEVICE con show | awk -F: '$2=="eth0"{print $1; exit}')"
if [ -n "${ETH_CON}" ]; then
  nmcli con mod "${ETH_CON}" ipv4.route-metric 100 ipv4.dhcp-timeout 10
  nmcli con up "${ETH_CON}" || true
else
  nmcli con add type ethernet ifname eth0 con-name starlink-wan autoconnect yes \
    ipv4.method auto ipv4.route-metric 100 ipv4.dhcp-timeout 10
fi

# 2. Configure local offline Wi-Fi Access Point on wlan0 (10.88.0.1/24 + DHCP)
nmcli con delete ordnance-ap >/dev/null 2>&1 || true
nmcli con add type wifi ifname wlan0 con-name ordnance-ap autoconnect yes \
  ssid "${AP_SSID}" mode ap \
  ipv4.method shared ipv4.addresses 10.88.0.1/24 \
  wifi-sec.key-mgmt wpa-psk wifi-sec.psk "${AP_PASS}"
nmcli con up ordnance-ap

# Optional wired LAN port (USB-Ethernet adapter) for Airplane-Mode EUDs & IP MANET
nmcli con add type ethernet ifname eth1 con-name ordnance-wired-lan autoconnect yes \
  ipv4.method shared ipv4.addresses 10.88.1.1/24

echo "Network configured: eth0 (Starlink WAN failover) + wlan0 AP (${AP_SSID} @ 10.88.0.1/24)."