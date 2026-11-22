# OrdnanceMesh — Phase 1: Benchtop Dual-Radio Bridge

**Objective:** Prove reliable, loop-free bidirectional text bridging between **Meshtastic** (`906.875 MHz`) and **MeshCore** (`910.525 MHz`) on a Raspberry Pi 5 workbench before building the Phase 2 solar/EMP-hardened ammo-can enclosure.

---

## 1. Bridge Engine Choice: AMMB vs. MESH-API

| Feature | [AMMB](https://github.com/AkitaEngineering/Akita-Meshtastic-Meshcore-Bridge) *(Recommended Baseline)* | [MESH-API](https://github.com/mr-tbot/mesh-api) *(Optional WebUI + AI)* |
| :--- | :--- | :--- |
| **Footprint** | Lightweight Python daemon (`run_bridge.py` / `run_bridge_async.py`) | Heavier Python/Docker router + WebUI (`:5000/dashboard`) |
| **MeshCore Mode** | Native `companion_radio` binary USB serial handler | Native `meshcore` block in `config.json` (Serial / TCP / BLE) |
| **Field Diagnostics** | Built-in preflight (`--check`), TUI Command Center, FastAPI `/api/*` | WebUI composer, node map, and 30+ AI/API extensions |
| **Best Role** | Headless, low-power RPi 5 ammo-can production daemon | Base-station dashboard or local Ollama AI chat over LoRa |

**Phase 1 Baseline:** Deploy **AMMB** as the core headless daemon for stability and minimal power draw; optionally layer **MESH-API** later as a Docker profile on **OrdnanceOS**.

---

## 2. Benchtop Hardware Required

- **1× Raspberry Pi 5** (8 GB recommended) running 64-bit Raspberry Pi OS Lite / Debian
- **2× USB LoRa Bridge Nodes** (e.g., RAK4631 WisBlock or Heltec V3, 915 MHz) with antennas attached
- **2× Handheld Carry Test Nodes** (one on Meshtastic, one on MeshCore — e.g., Seeed T1000-E, RAK4631, or LilyGO T-Deck Plus)
- **2× Quality Data-Rated USB Cables** (shielded, with ferrite beads recommended)

---

## 3. Step-by-Step Bring-Up

### Step 1: Flash the Two USB LoRa Bridge Nodes
> **Safety Note:** Always attach a 915 MHz antenna before powering on any LoRa board.

1. Flash **Node A** with stock **Meshtastic** firmware (US `906.875 MHz`). Create a dedicated secondary channel (e.g., **Index 1: `BRIDGE`**) so bridged traffic does not flood the public `LongFast` channel.
2. Flash **Node B** with **MeshCore Companion Radio (USB)** firmware (US `910.525 MHz`) and configure its matching bridge channel (e.g., **Index 2**).

### Step 2: Lock USB Serial Ports with `udev` Rules
Plug in **one radio at a time** on the Raspberry Pi 5 and inspect its unique hardware serial number (use `/dev/ttyACM0` for nRF52840/RAK4631 boards or `/dev/ttyUSB0` for CP210x/CH340 ESP32 boards):

```bash
udevadm info -a -n /dev/ttyUSB0 | grep -E "idVendor|idProduct|serial" | head -n 6
```

Create `/etc/udev/rules.d/99-ordnance-radios.rules` (and commit a template copy to `OrdnanceMesh/bridge/99-ordnance-radios.rules`):

```udev
# Deterministic symlinks for OrdnanceMesh dual-radio bridge
SUBSYSTEM=="tty", ATTRS{serial}=="REPLACE_MESHTASTIC_SERIAL", SYMLINK+="ordnance-meshtastic", GROUP="dialout", MODE="0660"
SUBSYSTEM=="tty", ATTRS{serial}=="REPLACE_MESHCORE_SERIAL",   SYMLINK+="ordnance-meshcore",   GROUP="dialout", MODE="0660"
```

Reload rules and verify both symlinks exist:

```bash
sudo udevadm control --reload-rules && sudo udevadm trigger
ls -l /dev/ordnance-meshtastic /dev/ordnance-meshcore
```

### Step 3: Install AMMB in a Dedicated Virtual Environment

```bash
sudo apt update && sudo apt install -y python3 python3-venv python3-pip git
sudo usermod -aG dialout $USER
# Log out and back in for dialout group membership to take effect

sudo mkdir -p /opt/ordnance-bridge /etc/ordnancemesh
sudo chown -R $USER:$USER /opt/ordnance-bridge /etc/ordnancemesh

git clone https://github.com/AkitaEngineering/Akita-Meshtastic-Meshcore-Bridge.git /opt/ordnance-bridge
cd /opt/ordnance-bridge
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### Step 4: Configure Channel Mapping & Rate Limits
Copy the upstream example config to `/etc/ordnancemesh/bridge.ini` (and commit your sanitized template to `OrdnanceMesh/bridge/config.ini`):

```bash
cp /opt/ordnance-bridge/examples/config.ini.example /etc/ordnancemesh/bridge.ini
```

Set these core parameters in `/etc/ordnancemesh/bridge.ini`:

```ini
[meshtastic]
SERIAL_PORT = /dev/ordnance-meshtastic
MESHTASTIC_CHANNEL_INDEX = 1

[external]
EXTERNAL_TRANSPORT = serial
SERIAL_PORT = /dev/ordnance-meshcore
SERIAL_PROTOCOL = companion_radio
COMPANION_HANDSHAKE_ENABLED = True
COMPANION_CONTACTS_POLL_S = 0
COMPANION_DEBUG = False
SERIAL_AUTO_SWITCH = True
MESHCORE_CHANNEL_INDEX = 2

[api]
API_ENABLED = True
API_HOST = 127.0.0.1
API_PORT = 8080
```

### Step 5: Run Preflight & Bidirectional Air Tests

```bash
cd /opt/ordnance-bridge
source .venv/bin/activate

# 1. Verify dependencies, config, and serial ports
python run_bridge_tui.py --check --config /etc/ordnancemesh/bridge.ini

# 2. Print effective config with secrets redacted
python run_bridge_tui.py --print-config --config /etc/ordnancemesh/bridge.ini

# 3. Launch live TUI Command Center for benchtop testing
python run_bridge_tui.py --config /etc/ordnancemesh/bridge.ini
```

With the TUI open:
1. Send a text message from your handheld **Meshtastic** node on Channel Index 1 and confirm it appears on your handheld **MeshCore** node on Channel Index 2.
2. Reply from the **MeshCore** node and confirm it arrives back on the **Meshtastic** node with **zero duplicate echo loops**.

### Step 6: Promote to Headless `systemd` Service
Install `/etc/systemd/system/ordnance-bridge.service` (and commit to `OrdnanceMesh/rpi5/src/ordnance-bridge.service`):

```ini
[Unit]
Description=OrdnanceMesh Dual-Radio Bridge (AMMB Async)
After=network.target dev-ordnance\x2dmeshtastic.device dev-ordnance\x2dmeshcore.device
Wants=dev-ordnance\x2dmeshtastic.device dev-ordnance\x2dmeshcore.device

[Service]
Type=simple
User=ordnance
Group=dialout
WorkingDirectory=/opt/ordnance-bridge
Environment=AMMB_CONFIG=/etc/ordnancemesh/bridge.ini
ExecStart=/opt/ordnance-bridge/.venv/bin/python run_bridge_async.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Enable, start, and verify logs:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now ordnance-bridge.service
sudo journalctl -u ordnance-bridge.service -f
```

---

## 4. Phase 1 Exit Gates (Pass Before Moving to Phase 2)

- [ ] **Bidirectional Cleanliness:** 10 messages each way across Meshtastic ↔ MeshCore with **zero** duplicate loops or dropped frames.
- [ ] **RF Desense Baseline:** Keep both benchtop antennas at least **24–36 inches apart** initially and log baseline SNR/RSSI for comparison when mounting on the steel ammo can in Phase 2.
- [ ] **Reboot Persistence:** Reboot the Raspberry Pi 5 three times and confirm `/dev/ordnance-meshtastic`, `/dev/ordnance-meshcore`, and `ordnance-bridge.service` come up cleanly without manual intervention.
- [ ] **USB Hot-Pull Recovery:** Unplug either USB LoRa node for 10 seconds, plug it back in, and verify the bridge reconnects automatically within 15 seconds.
