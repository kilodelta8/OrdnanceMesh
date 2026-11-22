# OrdnanceMesh — Bridge Radio Presets (US 915 MHz)

> **Rule:** Never power on a LoRa radio without a 915 MHz antenna attached.

## Node A: Meshtastic USB Bridge Radio
- **Region:** `US` (`906.875 MHz`, LongFast / SF11 / 250 kHz)
- **Device Role:** `CLIENT_MUTE` (bridges traffic cleanly without rebroadcast-flooding next to Node B)
- **Bluetooth / Wi-Fi:** **Disabled** (reduces local RF noise and USB power draw)
- **Channel Index 0:** Default `LongFast` (unbridged)
- **Channel Index 1:** `BRIDGE` — private 256-bit AES PSK (shared with your carry nodes), `Hop Limit = 3`

## Node B: MeshCore Companion USB Radio
- **Firmware:** MeshCore **Companion Radio (USB Serial)**
- **Region / Preset:** US `910.525 MHz` (SF7 / 62.5 kHz)
- **USB Serial Baud:** `115200` (8N1)
- **Bluetooth / Wi-Fi:** **Disabled**
- **Channel Index 2:** `BRIDGE` — matching private group key (mapped in `/etc/ordnancemesh/bridge.ini`)