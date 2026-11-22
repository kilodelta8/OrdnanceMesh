# OrdnanceMesh — Phase 4: Unified Android & iOS Companion Apps

**Objective:** Deliver a single **OrdnanceMesh** mobile app for both **Android** (`android/src/`) and **iOS** (`iOS/src/`) that unifies Meshtastic + MeshCore messaging, live **OrdnanceBox** relay telemetry, one-tap **ATAK CoT** beacons, and offline **Project NOMAD** access—without maintaining two drifting UI codebases.

---

## 1. Architecture Strategy: Shared Flutter Core + Native Bridges

| Layer | Directory | Responsibility |
| :--- | :--- | :--- |
| **Shared UI & Protocol Core** | `mobile/` (Flutter / Dart) | 4 core screens, Red-Light Night Mode theme, Relay HTTP/JSON client, and `PLI:`/`PIN:` beacon formatter. |
| **Android Native Bridge** | `android/src/` (Kotlin + Gradle) | Bluetooth Low Energy (BLE), USB-Serial OTG support for wired carry nodes, and local ATAK CoT intent hooks. |
| **iOS Native Bridge** | `iOS/src/` (Swift + Xcode) | CoreBluetooth BLE scanning/bonding and iOS Local Network permissions for `10.88.0.1` *(note: Apple restricts raw USB serial without MFi, so iOS uses BLE + Wi-Fi/USB-Ethernet)*. |
| **OrdnanceBox Relay API** | `rpi5/src/ordnance_api.py` | Lightweight zero-dependency Python JSON API on port `8081` exposing live thermal/WAN/USB telemetry and direct CoT beacon injection. |

---

## 2. Two Seamless Field Connection Modes

1. **OrdnanceBox Relay Mode (Wi-Fi AP `10.88.0.1` or Wired USB-Ethernet `10.88.1.1`):**
   - Polls `http://10.88.0.1:8081/api/v1/status` for real-time ammo-can health (CPU temp, throttling flags, Starlink Mini `ONLINE`/`OFFLINE`, and Meshtastic/MeshCore USB link state).
   - Connects to AMMB's local API (`:8080`) for unified Meshtastic + MeshCore chat.
   - Sends one-tap `PLI:` / `PIN:` beacons straight into `ordnance_cot_bridge.py` → **OpenTAKServer (`127.0.0.1:8088`)**.
2. **Direct Carry-Node Mode (BLE — Away from the Ammo Can):**
   - Pairs directly over BLE with a personal **Seeed T1000-E** or **RAK4631** (running Meshtastic or MeshCore Companion BLE).
   - Uses the exact same `PLI:<CALLSIGN>:<LAT>,<LON>,<ALT>` and `PIN:` format so beacons sent over LoRa automatically appear on ATAK/iTAK once heard by the OrdnanceBox relay.

---

## 3. Four Core MVP Screens (Glove-Friendly & Night-Ops Ready)

1. **Unified Mesh Chat:** Single message stream tagging every packet `[MT]` (Meshtastic) or `[MC]` (MeshCore), channel filter pills, and one-tap canned tactical replies.
2. **Offline Map & One-Tap Beacons:** Offline tile viewer + two large thumb buttons (**`Send PLI`** and **`Drop PIN`**) that pull phone GPS and emit valid Phase 3 CoT beacon payloads.
3. **OrdnanceBox Telemetry:** Live hardware status cards—RPi 5 CPU temperature, undervoltage/thermal throttle warning, Starlink WAN badge, and both USB radio link indicators (`/dev/ordnance-meshtastic`, `/dev/ordnance-meshcore`).
4. **Field Portal & Night Vision Mode:** One-tap links to local **OpenTAKServer** (`https://10.88.0.1:8443`), **Project NOMAD** (`http://10.88.0.1`), and **Mumble** voice status, plus a **Red-Light Night Mode** toggle to preserve night vision.

---

## 4. Phase 4 Directory Structure (`OrdnanceMesh/`)

```text
OrdnanceMesh/
├── rpi5/src/
│   ├── ordnance_api.py                # Lightweight Relay Status & Beacon API (:8081)
│   └── ordnance-api.service           # systemd unit for ordnance_api.py
├── mobile/                            # Shared Flutter Dart codebase
│   ├── pubspec.yaml
│   └── lib/
│       ├── main.dart                  # App shell + Red-Light Night Mode theme
│       ├── services/
│       │   ├── relay_api.dart         # HTTP client for OrdnanceBox :8081
│       │   └── beacon_formatter.dart  # PLI: / PIN: payload builder
│       └── screens/
│           ├── telemetry_screen.dart  # Live RPi 5 / Starlink / USB health
│           ├── beacon_screen.dart     # One-tap Send PLI & Drop PIN
│           ├── chat_screen.dart       # Unified [MT] + [MC] message feed
│           └── portal_screen.dart     # OpenTAKServer, NOMAD & Mumble links
├── android/src/                       # Android platform config, BLE/USB permissions
└── iOS/src/                           # iOS platform config, CoreBluetooth/LocalNet Info.plist
```

---

## 5. Relay API Contract (`http://10.88.0.1:8081`)

- **`GET /api/v1/status`** — Returns live JSON telemetry:
  ```json
  {
    "cpu_temp_c": 46.2,
    "throttled_hex": "0x0",
    "wan_state": "OFFLINE",
    "bridge_active": true,
    "cot_bridge_active": true,
    "meshtastic_usb": true,
    "meshcore_usb": true
  }
  ```
- **`POST /api/v1/beacon`** — Accepts `{"type":"PLI","callsign":"ALPHA1","lat":39.9612,"lon":-82.9988,"alt":275}` (or `"type":"PIN"`) and injects CoT 2.0 XML directly into local OpenTAKServer (`127.0.0.1:8088`).

---

## 6. Build Prerequisites & Local Dev Setup

1. Install the **Flutter SDK** (stable channel) on your dev workstation.
2. For **Android builds (`android/src/`)**: Android Studio / Android SDK + USB debugging enabled on your EUD.
3. For **iOS builds (`iOS/src/`)**: macOS with Xcode and a free Apple Developer account (for sideloading onto your own iPhone) or paid Apple Developer Program account (for TestFlight / App Store).
4. Add required runtime permissions:
   - **Android (`AndroidManifest.xml`):** `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, `ACCESS_FINE_LOCATION`, `INTERNET`, `USES_CLEARTEXT_TRAFFIC="true"` (for local `10.88.0.1` LAN HTTP).
   - **iOS (`Info.plist`):** `NSBluetoothAlwaysUsageDescription`, `NSLocationWhenInUseUsageDescription`, `NSLocalNetworkUsageDescription`, and `NSAppTransportSecurity` local-networking exception.

---

## 7. Phase 4 Exit Gates (Pass Before Moving to Phase 5 / OrdnanceOS)

- [ ] **Relay API Verification:** `curl http://10.88.0.1:8081/api/v1/status` returns valid live JSON from the OrdnanceBox over both `OrdnanceBox` Wi-Fi (`10.88.0.1`) and wired LAN (`10.88.1.1`).
- [ ] **Dual-Platform Telemetry Check:** Both Android and iOS builds display live CPU temp, Starlink WAN state, and USB radio status with zero internet access.
- [ ] **One-Tap CoT Beacon Check:** Tapping **`Send PLI`** or **`Drop PIN`** in the mobile app renders the icon on a connected ATAK/iTAK EUD within 5 seconds.
- [ ] **Red-Light Night Mode Check:** Night Mode toggle switches the entire UI to low-glare dark/red palette cleanly across all four screens.
