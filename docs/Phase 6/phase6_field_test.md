# OrdnanceMesh — Master Field Deployment, Testing & Troubleshooting Manual (Phase 6)

**Printable Field Edition | Covers Phases 1–4 End-to-End | Version 1.0**  
*Print double-sided, place in a waterproof sleeve, and store one copy inside your Cold-Spare Faraday ammo can.*

---

## Chapter 1: Master Software Installation (RPi 5 + Mobile EUDs)

### 1.1 One-Command RPi 5 Installation (`installer.sh`)
Start with a fresh **64-bit Raspberry Pi OS Lite** (Bookworm/Trixie) on your Raspberry Pi 5 with temporary internet access:

```bash
git clone https://github.com/<your-org>/OrdnanceMesh.git
cd OrdnanceMesh

# Run the master installer (pass your desired OrdnanceBox Wi-Fi passphrase)
sudo AP_PASS="YourStrongTeamKey123" bash installer.sh
```

What `installer.sh` automates in order:
(Run from the repo root: sudo AP_PASS="YourStrongTeamKey123" bash installer.sh — or run a single stage with sudo bash installer.sh --only 3.)
1. **Wi-Fi Regulatory & Radio Prep:** Sets Wi-Fi country (`US`) and unblocks `rfkill` so `wlan0` broadcasts cleanly.
2. **Phase 1 (Dual-Radio Bridge):** Creates the `ordnance` service user (`dialout` + `systemd-journal` + `video`), installs pinned **AMMB** into `/opt/ordnance-bridge/.venv`, installs `udev` rules, `bridge.ini`, `ordnance-bridge.service`, `ordnance-watchdog.timer`, and caps `journald` to `100M`.
3. **Phase 2 (Network Failover & Thermal Logger):** Configures `NetworkManager` for **Starlink Mini WAN (`eth0`, metric 100)**, **OrdnanceBox Wi-Fi AP (`wlan0`, `10.88.0.1/24`)**, optional **Wired LAN (`eth1`, `10.88.1.1/24`)**, `ordnance-wan-monitor.timer`, and `ordnance-telemetry.timer`.
4. **Phase 3 (ATAK CoT Bridge & Voice):** Installs `ordnance_cot_bridge.py` + `ordnance-cot-bridge.service`, optionally installs `mumble-server`, and invokes the official **OpenTAKServer** Raspberry Pi installer as your non-root user.
5. **Phase 4 (Mobile Relay API & Firewall):** Installs `ordnance_api.py` + `ordnance-api.service` on port `8081` and configures `ufw` so port `8081` is reachable **only** on `wlan0` and `eth1` (never exposed out Starlink `eth0`).

### 1.2 Post-Install Manual Locks (5 Minutes)
1. **Lock USB Radio Serials:** Plug in one LoRa bridge radio at a time, record its serial via `udevadm info -a -n /dev/ttyUSB0 | grep -E "idVendor|idProduct|serial" | head -n 6`, and update `/etc/udev/rules.d/99-ordnance-radios.rules` (use `KERNELS` port matching if both boards share `0001`). Reload with `sudo udevadm control --reload-rules && sudo udevadm trigger`.
2. **Verify AMMB Endpoints:** Run `curl -s http://127.0.0.1:8080/openapi.json` once `ordnance-bridge.service` is running to confirm `/api/health` and `/api/send` paths, and record your tested commit SHA (`git -C /opt/ordnance-bridge rev-parse HEAD`).
3. **Enable OpenTAKServer Local TCP CoT:** Ensure `OTS_ENABLE_TCP_STREAMING_PORT: true` in `~/ots/config.yml` (bound to `127.0.0.1:8088`).
4. **Set Mumble Password:** Set `serverpassword=` in `/etc/mumble-server.ini` and run `sudo systemctl restart mumble-server`.
5. **Load Mobile EUDs:** Build/sideload `OrdnanceMesh/mobile/` via Flutter onto Android & iOS phones, import your OpenTAKServer client certificate `.zip` into ATAK/iTAK, and copy regional offline `.mbtiles` maps to each EUD.

---

## Chapter 2: Pre-Deployment Hardware & Cold-Spare Sign-Off

Complete before leaving base:

- [ ] **Conductive RF Gaskets:** Bare steel rim contact verified on **both** Can #1 (Active OrdnanceBox) and Can #2 (Unpenetrated Cold-Spare).
- [ ] **MPPT Wiring Check:** Victron SmartSolar MPPT is wired **directly to LiFePO4 via its own 15 A fuse** (bypassing the `MAIN` load switch) and preset to **LiFePO4 (`14.2 V` / `13.5 V`)**.
- [ ] **Polarity & Voltage Smoke Test (RPi 5 & Starlink Unplugged):**
  - Battery terminals: `12.8–13.6 V DC` (correct polarity)
  - `MAIN` ON → RPi 5 USB-C PD output: `5.00–5.15 V DC`
  - `STARLINK` ON → Starlink DC boost output: `24 V` or `30 V DC`
- [ ] **Antenna-First Rule:** Both external 915 MHz antennas (`MESHTASTIC 906.875` and `MESHCORE 910.525`) screwed tightly onto their N-Type GDT surge arrestors **before** flipping `MAIN` ON.
- [ ] **Cold-Spare Can #2 Inventory (Zero Holes Drilled, EVA Foam Lined):**
  - 1× Golden-cloned spare RPi 5 + SD/NVMe
  - 2× Pre-flashed USB LoRa bridge radios (matching `bridge/radio-presets.md`)
  - 1× Spare Seeed T1000-E + 1× Spare RAK4631
  - 2× Shielded USB cables, 2× RF pigtails, 1× Spare 5 V/5 A USB-C PD buck
  - 1× Printed copy of this manual

---

## Chapter 3: 15-Minute Field Deployment SOP

1. **Site & Ground (Min 0–3):** Place OrdnanceBox on dry ground. If stationary, drive the 2–4 ft portable copper ground rod into damp earth and clamp the ground lead to the external brass ground stud.
2. **Solar & Shade (Min 3–6):** Deploy the 100 W folding panel facing south at ~30–45° tilt. Place the OrdnanceBox **in the shade behind the solar panel** to cut internal heat buildup. Plug Anderson Powerpole into `SOLAR IN`.
3. **Antennas & Power On (Min 6–9):** Attach both labeled 915 MHz antennas to the N-Type GDT arrestors (elevate on a portable mast if in dense foliage). Flip **`MAIN` ON**. Leave **`STARLINK` OFF** unless WAN uplink is needed.
4. **Verify Health (Min 9–12):** Join `OrdnanceBox` Wi-Fi (`10.88.0.1`) or plug a wired Airplane-Mode EUD into `eth1` (`10.88.1.1`). Open the **OrdnanceMesh** app → **Relay** tab and confirm all 7 green checks (`CPU < 75°C`, `0x0` throttle, both USB radios `LINKED`, AMMB + CoT `ACTIVE`).
5. **Optional Starlink Uplink (Min 12–15):** Plug Starlink Mini Ethernet into `STARLINK ETH` and DC plug into `STARLINK OUT`, then flip **`STARLINK` ON** (enable Bypass Mode in Starlink app to save ~3–5 W). Confirm `Starlink Mini WAN: ONLINE` in the app.

---

## Chapter 4: 72-Hour Field Stress-Test & Validation Drills

Record actual measured numbers below during your shakedown exercise. Every drill must pass before declaring your kit **Field Ready**.

### Drill 1: Dual-Mesh Bidirectional & Range Test
- Send 10 messages each way (Meshtastic Ch 1 ↔ MeshCore Ch 2) at 100 m, 500 m, and max local terrain distance.
- **Pass Criteria:** 100% delivery within range, **zero** duplicate echo loops.
- **Logged Results:** Max clean range: `______ km` | Meshtastic SNR/RSSI: `______` | MeshCore SNR/RSSI: `______` | Pass: `[ ]`

### Drill 2: Ammo-Can RF Desense Audit
- Compare SNR/RSSI of both radios mounted on the OrdnanceBox bulkheads against your Phase 1 benchtop baseline while the opposite radio transmits.
- **Pass Criteria:** **< 3 dB** degradation compared to benchtop.
- **Logged Results:** Benchtop baseline: `______ dB` | Ammo-can live: `______ dB` | Delta: `______ dB` | Pass: `[ ]`

### Drill 3: 48–72 Hour Thermal & Solar Autonomy Soak
- Run the closed OrdnanceBox outdoors for 48–72 hours with `STARLINK` OFF (plus one 2-hour `STARLINK` ON window). Pull `/var/log/ordnance-telemetry.csv` at completion.
- **Pass Criteria:** Peak CPU temp **< 75°C**, `throttled_hex` remains **`0x0`**, LiFePO4 recovers cleanly each day.
- **Logged Results:** Peak ambient: `____°F` | Peak CPU: `____°C` | Lowest battery V: `____ V` | Throttle hex: `______` | Pass: `[ ]`

### Drill 4: 10× Hard Power-Cut Recovery Drill
- Flip `MAIN` **OFF** abruptly 10 consecutive times during active bridging, waiting 30 seconds between cuts.
- **Pass Criteria:** Clean boot every time, zero filesystem corruption, both USB radios + bridge + API auto-recover within 90 seconds without SSH intervention.
- **Logged Results:** Clean recoveries: `___ / 10` | Max boot-to-ready time: `____ s` | Pass: `[ ]`

### Drill 5: Starlink Mini Failover Drill
- With Starlink Mini `ONLINE`, flip `STARLINK` **OFF** mid-session while sending messages and ATAK pins.
- **Pass Criteria:** `ordnance-wan-monitor` logs `OFFLINE` within 5 seconds; local Wi-Fi, OpenTAKServer, and dual-mesh bridging stay 100% uninterrupted.
- **Logged Results:** Failover time: `____ s` | Local service drop: `Yes / No` | Pass: `[ ]`

### Drill 6: End-to-End ATAK CoT, Mobile App & Voice Drill
- Verify (a) Airplane-Mode wired Android ATAK loads `.mbtiles` and sees `10.88.1.1:8089`, (b) mobile app **`Send PLI`** and **`Drop PIN`** appear on ATAK within 5s, (c) MeshCore `PLI:`/`PIN:` beacon appears on ATAK within 10s, (d) Red-Light Night Mode works, and (e) local Mumble PTT + VHF/UHF fallback audio are clear.
- **Logged Results:** Airplane-Mode ATAK: `[ ]` | App CoT: `[ ]` | MeshCore CoT: `[ ]` | Voice: `[ ]`

### Drill 7: Unpenetrated Cold-Spare Swap Drill
- Simulate a fried active relay. Open Can #2, swap in the spare RPi 5 + two spare USB LoRa bridge radios, power up, and pass a test message across both meshes.
- **Pass Criteria:** Full restoration in **under 10 minutes**.
- **Logged Results:** Swap time: `____ min ____ sec` | Pass: `[ ]`

---

## Chapter 5: Field Troubleshooting & Phase-by-Phase Mitigation Guide

### Phase 1 Issues — Dual-Radio Bridge & USB Serial
| Symptom | Root Cause | Immediate Field Fix |
| :--- | :--- | :--- |
| `/dev/ordnance-meshtastic` or `meshcore` missing after reboot | Identical factory USB serial (`0001`) on two CP2102/Heltec V3 boards | Switch `/etc/udev/rules.d/99-ordnance-radios.rules` to Option B (`KERNELS=="1-1.1"` / `"1-1.2"`), physically label the two Pi USB ports, and reload `udev`. |
| Bridge stays `active` in systemd, but stops forwarding packets | Silent USB-UART brownout/wedge or noisy unshielded USB cable | Verify `ordnance-watchdog.timer` is running (`systemctl status ordnance-watchdog.timer`), add Type-31 ferrite chokes to USB cables, and confirm `vcgencmd get_throttled` is `0x0`. |
| Infinite message echo loop across meshes | Both nodes bridging on public `LongFast` or misconfigured channel indices | Verify Meshtastic is on `CLIENT_MUTE` + dedicated Index 1 (`BRIDGE`), MeshCore on Index 2, and confirm AMMB rate-limiting is enabled in `/etc/ordnancemesh/bridge.ini`. |
| Watchdog restarts bridge every 3 minutes even when working | AMMB health route path differs from `/api/health` | Run `curl -s http://127.0.0.1:8080/openapi.json` and update the URL in `/usr/local/bin/ordnance-watchdog.sh`. |

### Phase 2 Issues — Ammo-Can Power, Thermals, RF & Starlink
| Symptom | Root Cause | Immediate Field Fix |
| :--- | :--- | :--- |
| `vcgencmd get_throttled` shows non-zero (`0x50000` / `0x50005`) | Undersized 3 A buck converter or voltage drop across thin USB-C wire | Replace with a true **12 V → 5 V / 5 A USB-C PD** buck and keep 16 AWG DC leads short. |
| CPU temp > 75°C inside closed ammo can | Direct summer sun on dark steel can or poor heat conduction | Move can into shade behind the solar panel, verify thermal pad contact between aluminum sub-plate and steel wall, and open/enable the 40°C thermostatic fan. |
| Battery won't charge in winter sun | LiFePO4 low-temp BMS cutoff triggered (< 32°F / 0°C) — *this is protecting the cells!* | Normal safety behavior. Insulate the battery bay or warm the can above freezing before solar charging resumes. |
| MPPT stops charging when `MAIN` switch is OFF | MPPT accidentally wired downstream of `MAIN` load switch | Rewire Victron MPPT Batt `(+)` directly to LiFePO4 `(+)` via its own 15 A fuse, bypassing `MAIN`. |
| > 3 dB SNR drop when both LoRa antennas are on the can | 906.875 MHz and 910.525 MHz antennas too close together | Separate N-Type bulkheads to opposite ends of the can or route one antenna onto a 3–6 ft fiberglass mast jumper; add 915 MHz band-pass filters if needed. |
| `OrdnanceBox` Wi-Fi SSID does not appear on fresh Pi OS | `rfkill` soft-blocks Wi-Fi until country code is set | Run `sudo raspi-config nonint do_wifi_country US && sudo rfkill unblock wifi && sudo nmcli con up ordnance-ap`. |
| `eth0` and `wlan0` randomly drop IPs | `systemd-networkd` and `NetworkManager` fighting over interfaces | Disable `systemd-networkd` (`sudo systemctl disable --now systemd-networkd`) and manage both interfaces solely via `setup-network.sh` (`NetworkManager`). |

### Phase 3 Issues — Carry Kits, OpenTAKServer, CoT & Voice
| Symptom | Root Cause | Immediate Field Fix |
| :--- | :--- | :--- |
| OpenTAKServer installer fails or puts files in `/root/ots` | Installer was executed as `root` instead of normal user | Re-run as your regular user: `curl -Ls https://i.opentakserver.io/raspberry_pi_installer | bash -`. |
| `ordnance_cot_bridge.py` logs `Connection refused` to `127.0.0.1:8088` | Local TCP CoT streaming port disabled in OpenTAKServer | Set `OTS_ENABLE_TCP_STREAMING_PORT: true` in `~/ots/config.yml` and restart `opentakserver`. |
| Duplicate pins burst onto ATAK map | AMMB logs both RX and TX lines for the same beacon | Confirm you are running the updated `ordnance_cot_bridge.py` with the 10-second `RECENT_EVENTS` deduplication cache. |
| Wired Airplane-Mode Android EUD gets no IP | Plugged into `eth0` (Starlink WAN) instead of `eth1` (LAN) | Plug wired EUD / MANET switch into the USB-Ethernet `eth1` port (`10.88.1.1/24`) configured in `setup-network.sh`. |
| Unauthorized clients join Mumble voice | Default `mumble-server` has blank password | Set `serverpassword=` in `/etc/mumble-server.ini` and restart `mumble-server`. |

### Phase 4 Issues — Mobile App & Relay API (`:8081`)
| Symptom | Root Cause | Immediate Field Fix |
| :--- | :--- | :--- |
| Android app says `OrdnanceBox unreachable` while connected to Wi-Fi | Android routes traffic over cellular when Wi-Fi has no internet | Tap **"Stay connected without internet"** on the Android Wi-Fi prompt, or toggle **Airplane Mode ON + Wi-Fi ON**. |
| iOS app cannot reach `10.88.0.1:8081` | Operator denied the iOS Local Network permission prompt | On iPhone: **Settings → Privacy & Security → Local Network → OrdnanceMesh → ON**. |
| `throttled_hex` shows `unknown` or Chat feed stays empty | `ordnance` user missing `video` or `systemd-journal` group | Confirm `SupplementaryGroups=video systemd-journal` in `/etc/systemd/system/ordnance-api.service`, then `sudo systemctl daemon-reload && sudo systemctl restart ordnance-api.service`. |
| Outbound app chat shows on LAN phones but doesn't transmit over LoRa | AMMB REST send URL differs or API write is disabled | Verify AMMB's send endpoint via `curl -s http://127.0.0.1:8080/openapi.json` and update `AMMB_SEND_URL` in `ordnance-api.service`. |
