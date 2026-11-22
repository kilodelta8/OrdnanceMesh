# OrdnanceMesh & [OrdnanceOS](https://github.com/kilodelta8/OrdnanceOS)

**Unified off-grid tactical communications, Meshtastic–MeshCore bridging, ATAK integration, Starlink failover, and a custom Debian-based survival Linux distribution.**

---

## Why OrdnanceMesh Exists

Meshtastic (US default `906.875 MHz`, SF11 / 250 kHz, managed flooding) and MeshCore (US default `910.525 MHz`, SF7 / 62.5 kHz, per-contact routing) are isolated at the RF, sync-word, and encryption layers. Rather than forcing every group or municipal repeater onto one firmware, **OrdnanceMesh** links both networks through a solar-powered, EMP-hardened Raspberry Pi 5 ammo-can relay—and unifies them with ATAK, broadband IP MANET, Starlink Mini backhaul, cross-platform mobile apps, and **OrdnanceOS** (our offline survival Linux distro integrating [Project NOMAD](https://github.com/crosstalk-solutions/project-nomad)).

---

## Repository Structure

Mirror this top-level folder tree in Google Drive (`OrdnanceMesh/`) for living design docs, BOM spreadsheets, and field logs:

```text
OrdnanceMesh/
├── README.md          # Master architecture overview & quick-start
├── docs/              # brainstorm.doc, gameplan.doc, SOPs, wiring diagrams
├── hardware/          # Ammo-can CAD/STL, solar/LiFePO4 BOM, EMP grounding specs
├── bridge/            # AMMB / MESH-API configs + custom MeshCore-to-CoT translator
├── atak/              # OpenTAKServer configs, client certs, offline MBTiles packages
├── iOS/
│   └── src/           # OrdnanceMesh iOS companion app (BLE + RPi 5 relay client)
├── android/
│   └── src/           # OrdnanceMesh Android companion app + ATAK CoT intent bridge
├── rpi5/
│   └── src/           # Relay daemon, USB serial watchdog, Starlink WAN failover, WebUI
└── linux/
    └── src/           # OrdnanceOS reproducible Debian image builder (ARM64 + x86_64)
```

---

## Core Architecture Layers

1. **Dual-Radio Cross-Protocol Relay (`rpi5/src`, `bridge/`):** Raspberry Pi 5 in a steel ammo can wired to two dedicated USB LoRa nodes (one Meshtastic, one MeshCore Companion Radio) running [AMMB](https://github.com/AkitaEngineering/Akita-Meshtastic-Meshcore-Bridge) or [MESH-API](https://github.com/mr-tbot/mesh-api) with channel mapping, rate limiting, and USB watchdog recovery.
2. **Individual Carry Kits (`hardware/`):**
   - *Slick PLI / Text:* Seeed SenseCAP T1000-E (IP65, GPS, ~48h battery).
   - *Shoulder / Repeater Node:* RAK4631 WisBlock + RG316 pigtail + 17 cm flexible 915 MHz whip.
   - *Phone-Free Comms Leader:* LilyGO T-Deck Plus (physical keyboard + screen + GPS).
   - *Voice / Talk:* Broadband IP MANET (Doodle Labs / Microhard) + ATAK VoIP/Mumble, local relay Wi-Fi intercom, or VHF/UHF (GMRS/DMR) fallback.
3. **ATAK & CoT Interoperability (`atak/`):** Local OpenTAKServer on the RPi 5 paired with Airplane-Mode wired USB-C Ethernet EUDs (Juggernaut / Kagwerks) and a planned MeshCore-to-CoT XML translation daemon.
4. **Starlink Failover (`rpi5/src`):** Opportunistic DC-powered Starlink Mini WAN uplink for TAK federation, remote MQTT bridging, and offline archive updates—dropping cleanly to 100% air-gapped operation when disconnected.
5. **EMP / HEMP Hardening (`hardware/`):** Two-tier protection pairing active surge defense (conductive RF lid gasket, inline coaxial GDT surge arrestors on antenna bulkheads bonded to a common ground stud, TVS diodes and ferrites on solar/Ethernet) with an unpenetrated **Cold-Spare** Faraday ammo can storing pre-flashed backup hardware and shielded OS media.
6. **OrdnanceOS (`linux/src`):** Reproducible Debian-based survival Linux (`pi-gen` for ARM64 RPi 5, `live-build` for x86_64 base stations) bundling the OrdnanceMesh bridge, OpenTAKServer, [Project NOMAD](https://github.com/crosstalk-solutions/project-nomad) (offline Wikipedia, medical/survival guides, offline maps, Khan Academy/Kolibri, optional local Ollama AI), and SDR/ham utilities on a power-cut-safe overlayfs root.

---

## Development Roadmap

| Phase | Milestone | Exit Gate |
| :--- | :--- | :--- |
| **Phase 0** | Foundation & Naming | `OrdnanceMesh/` repo & Drive mirror live; Phase 1 hardware ordered |
| **Phase 1** | Benchtop Dual-Radio Bridge | Bidirectional Meshtastic ↔ MeshCore text with zero loop storms |
| **Phase 2** | Ammo-Can Relay & Starlink | 48h off-grid solar runtime; seamless Starlink plug/unplug failover |
| **Phase 3** | Carry Kits & ATAK | Live PLI/pins from both meshes on wired Airplane-Mode ATAK EUD |
| **Phase 4** | Android & iOS Apps | Unified chat + relay telemetry working on both mobile platforms |
| **Phase 5** | OrdnanceOS Linux Distro | Fresh ARM64/x86_64 flash boots air-gapped with bridge, TAK & NOMAD |
| **Phase 6** | Field Stress Testing | Zero storage corruption on hard power cuts; 15-min repeatable setup |

---

## Upstream Open-Source Projects

- [Akita Meshtastic-MeshCore Bridge (AMMB)](https://github.com/AkitaEngineering/Akita-Meshtastic-Meshcore-Bridge)
- [MESH-API Multi-Radio Router](https://github.com/mr-tbot/mesh-api)
- [Project NOMAD Offline Knowledge & AI Server](https://github.com/crosstalk-solutions/project-nomad)
