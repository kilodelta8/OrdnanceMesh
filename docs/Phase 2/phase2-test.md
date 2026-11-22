Once you verify Starlink Mini works over eth0, enable Bypass Mode in the Starlink app (turns off Starlink's built-in Wi-Fi router). That cuts ~3–5 W of wasted draw and reduces 2.4/5 GHz RF noise next to your ammo can.

With those three fixes applied, Phase 2 is electrically safe, won't fight Raspberry Pi OS networking, and will broadcast a real offline EUD hotspot out of the box.

One tiny Raspberry Pi OS detail to keep in mind when you run setup-network.sh for the first time: a fresh Pi image keeps Wi-Fi soft-blocked until a country code is set, so run sudo raspi-config nonint do_wifi_country US && sudo rfkill unblock wifi first if wlan0 doesn't broadcast OrdnanceBox immediately.

Run your multimeter polarity checks before plugging in the Pi 5 or Starlink Mini, then clear the four Phase 2 exit gates (48h thermal/solar soak, <3 dB RF desense check, 5s Starlink failover drill, and <10 min cold-spare swap).