# OrdnanceMesh — Phase 3: Carry Kits, ATAK & MeshCore CoT Bridge

**Objective:** Field individual operator carry kits (text, type, and talk), deploy a local offline **OpenTAKServer** on the OrdnanceBox Raspberry Pi 5, connect **Airplane-Mode wired ATAK/iTAK EUDs**, and bridge **MeshCore** position/pin beacons into live **Cursor-on-Target (CoT)** icons on one unified tactical map.

---

## 1. Individual Carry Kit Tiers

Standard LoRa bandwidth (especially Meshtastic SF11) cannot carry real-time voice audio. OrdnanceMesh keeps LoRa dedicated to silent text and Position Location Information (PLI), and routes real-time voice over IP MANET/Wi-Fi Mumble or VHF/UHF handhelds.

| Kit Tier | Hardware Stack | Primary Role | Voice / Talk Path |
| :--- | :--- | :--- | :--- |
| **Tier 1: Slick / Admin** | **Seeed SenseCAP T1000-E** + Phone/EUD (BLE) | Credit-card sized, IP65, internal antenna, GPS, ~48h battery; reflashes Meshtastic ↔ MeshCore in ~60s. | Separate VHF/UHF (GMRS/DMR) handheld |
| **Tier 2: Shoulder Node** | **RAK4631 WisBlock** + 6"–12" **RG316 SMA pigtail** + **17 cm flexible 915 MHz whip** | Ultra-low-power nRF52840 (3–5 day battery on 2000 mAh LiPo); clears body mass on shoulder MOLLE without snagging rifles. | Separate VHF/UHF handheld or local Wi-Fi intercom |
| **Tier 3: Comms Leader** | **LilyGO T-Deck Plus** (physical keyboard + screen + GPS) | Standalone phone-free typing, channel management, and field diagnostics. | Separate VHF/UHF handheld |
| **Tier 4: Full ATAK / MANET** | **Juggernaut / Kagwerks chest mount** + **USB-C Ethernet adapter** + **Doodle Labs** (`Rm-915-2j-xm` / `Rm-1700-22m3`) or **Microhard** (`pMDDL2450`) | Runs Android EUD in **full Airplane Mode** (zero cellular/Wi-Fi/BT RF signature) with HD video, VoIP, and full ATAK data. | **ATAK Mumble / VoIP** over IP MANET or OrdnanceBox LAN |

---

## 2. Step-by-Step Deployment

### Step 1: Install Local OpenTAKServer on the OrdnanceBox RPi 5
Run the official [OpenTAKServer Raspberry Pi installer](https://github.com/brian7704/OpenTAKServer-Installer) while your RPi 5 has temporary internet (or Starlink Mini):

```bash
curl https://i.opentakserver.io/raspberry_pi_installer -Ls | bash -
```

1. During setup, accept **Certificate Authority** generation (creates your local offline TLS CA).
2. Enable **MediaMTX** if you plan to stream video over Doodle Labs / Microhard broadband MANET.
3. Verify the WebUI is reachable locally at `https://10.88.0.1:8443` (or `https://10.88.0.1` via nginx) and note the CoT ports:
   - **TCP CoT (local bridge injection):** `127.0.0.1:8088`
   - **SSL CoT (EUD clients):** `10.88.0.1:8089`

### Step 2: Build the Offline ATAK / iTAK Data Package
1. Log into the OpenTAKServer WebUI, create one user account per operator/callsign, and generate a **Client Certificate Data Package (`.zip`)** pointing to `10.88.0.1:8089`.
2. Pre-download regional offline topo/satellite maps as **`.mbtiles`** (using MOBAC or QGIS) and store them in `OrdnanceMesh/atak/maps/` (gitignored if large; mirror on your local SSD / Cold-Spare).
3. Load both the certificate `.zip` and `.mbtiles` onto every Android (**ATAK-CIV**) and iOS (**iTAK**) EUD so they operate 100% air-gapped.

### Step 3: Configure Wired Airplane-Mode EUDs
1. Mount your Android EUD in a **Juggernaut / Kagwerks** chest rig with a **USB-C to Gigabit Ethernet** adapter (with PD pass-through if powering from a rear dangler battery bank).
2. Switch the phone into **full Airplane Mode** (cellular, Wi-Fi, and Bluetooth all OFF).
3. Connect the Ethernet cable either directly to your **Doodle Labs / Microhard IP MANET** radio or to an Ethernet switch/USB-Ethernet LAN port on the **OrdnanceBox**.
4. Open **ATAK** → **Settings → Network Preferences → Manage Server Connections**, import the Data Package `.zip`, and verify the green connected indicator for `10.88.0.1:8089`.

### Step 4: Deploy the MeshCore-to-CoT Bridge (`bridge/cot-bridge/`)
Meshtastic already supports live ATAK CoT pins via the official **Meshtastic ATAK Plugin**. To bring **MeshCore** teammates onto the exact same ATAK map, run `ordnance_cot_bridge.py` on the RPi 5:

- **Compact Beacon Grammar (sent on your MeshCore BRIDGE channel):**
  - **Team PLI:** `PLI:<CALLSIGN>:<LAT>,<LON>[,<ALT_M>]`  
    Example: `PLI:ALPHA1:39.9612,-82.9988,275`
  - **Tactical Pin / Waypoint:** `PIN:<LABEL>:<LAT>,<LON>[:<COT_TYPE>]`  
    Example: `PIN:RALLY1:39.9650,-83.0010:a-u-G` *(defaults to friendly/neutral waypoint `b-m-p-s-m` if omitted)*
- **Translation Flow:**
  1. `ordnance_cot_bridge.py` tails incoming bridged MeshCore text events (via AMMB's local event/MQTT/log stream).
  2. Valid `PLI:` and `PIN:` strings are converted into **CoT 2.0 XML** (`<event version="2.0" uid="ORD-MC-..." ...>`) with a 15-minute stale timer.
  3. The XML event is pushed over local TCP to **OpenTAKServer (`127.0.0.1:8088`)**, immediately broadcasting the icon to every connected ATAK and iTAK EUD.

### Step 5: Configure Local Voice (Optional IP Mumble + RF Fallback)
- **On IP MANET / OrdnanceBox Wi-Fi:** Install `mumble-server` (`sudo apt install -y mumble-server`) on the RPi 5 (`10.88.0.1:64738`) and pair with the **ATAK Mumble plugin** or Mumla (Android) / Mumble (iOS) for low-latency push-to-talk voice.
- **Beyond IP Range:** Standardize a primary + alternate **VHF/UHF (GMRS/DMR)** voice channel on your team's handheld radios so voice never depends on LoRa bandwidth.

---

## 3. Phase 3 Exit Gates (Pass Before Moving to Phase 4)

- [ ] **Airplane-Mode EUD Enrollment:** Android ATAK EUD in full Airplane Mode connects to `10.88.0.1:8089` over wired USB-C Ethernet and renders offline `.mbtiles` maps with zero internet.
- [ ] **Meshtastic CoT Verification:** A Meshtastic carry node running the Meshtastic ATAK Plugin updates its live PLI icon on the local OpenTAKServer.
- [ ] **MeshCore CoT Bridge Verification:** Sending `PLI:BRAVO2:39.9612,-82.9988,275` and `PIN:LZ1:39.9650,-83.0010` from a MeshCore carry node displays both icons on ATAK/iTAK within 10 seconds.
- [ ] **Voice Comms Verification:** Clear push-to-talk voice works over local Mumble on the OrdnanceBox LAN/MANET, and VHF/UHF fallback channels are verified on team handhelds.
