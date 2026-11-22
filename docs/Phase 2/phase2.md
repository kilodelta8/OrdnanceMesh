# OrdnanceMesh — Phase 2: OrdnanceBox Build & Deployment Manual

**Objective:** Move your working Phase 1 benchtop bridge into the **OrdnanceBox**—a weatherproof, solar-powered, EMP-hardened steel ammo-can relay with **48-hour zero-sun autonomy** and automatic **Starlink Mini** WAN failover—plus an unpenetrated **Cold-Spare** Faraday can.

---

## 1. Plain-English Overview: What You Are Building

You are building **two steel ammo cans**:
1. **Can #1 — Active OrdnanceBox (40 mm PA120 or Fat-50 PA108):** Houses your Raspberry Pi 5, two USB LoRa bridge radios, a 12.8 V 30 Ah LiFePO4 battery, an MPPT solar charge controller, voltage regulators, and surge-protected external ports for solar, dual 915 MHz antennas, and Starlink Mini.
2. **Can #2 — Cold-Spare Faraday Can (Standard `.50 cal` M2A1, ZERO holes drilled):** An unpenetrated, RF-gasketed steel vault lined with foam holding a pre-flashed spare RPi 5, two spare USB LoRa bridge nodes, spare carry nodes, and cables. If a direct surge or EMP ever kills Can #1 through an external cable, you open Can #2 and swap in a working relay in under 10 minutes.

> **Why not a standard `.50 cal` can for Can #1?** Once you put a 30 Ah LiFePO4 battery, MPPT controller, two DC converters, an RPi 5, two LoRa boards, and surge arrestors inside a `.50 cal` can, there is no room for airflow and summer sun will overheat the electronics. Use a **40 mm (PA120)** or **Fat-50 (PA108)** steel can.

---

## 2. Power Budget & Runtime Math

| Operating Mode | Average Draw | Daily Energy | Runtime on 30 Ah LiFePO4 (384 Wh / ~326 Wh usable) |
| :--- | :--- | :--- | :--- |
| **Core Relay Only** *(Starlink OFF)* | **~7.5 W** *(RPi 5 ~5.5 W + 2× LoRa ~1.0 W + DC overhead ~1.0 W)* | ~180 Wh / day | **~43–48 hours** with zero sun |
| **Relay + Starlink Mini Active** | **~35 W** *(Core ~7.5 W + Starlink Mini ~25–30 W avg, 60 W boot peak)* | ~840 Wh / day | **~9–10 hours** off-battery, or **indefinite daytime** on 100 W solar |

**Design Rule:** Put Starlink Mini on a **physical fused rocker switch** on the OrdnanceBox. Flip it ON when you need TAK federation, remote MQTT bridging, or Project NOMAD archive sync; flip it OFF to stretch battery life to 2 full days without sun.

---

## 3. Complete Shopping & Sourcing List (BOM)

### Core Power & Solar
| Item | Exact Spec to Buy | Qty | Verified Source / Search Terms |
| :--- | :--- | :--- | :--- |
| **LiFePO4 Battery** | 12.8 V 30 Ah LiFePO4 with **Low-Temperature Charge Cut-Off BMS** *(critical so winter sun won't ruin cells below 32°F / 0°C)* | 1 | [DC HOUSE 12V 30Ah LiFePO4 (Low-Temp BMS)](https://www.dchousepower.com/products/12v-30ah-deep-cycle-lifepo4-low-temp-protection-battery) |
| **MPPT Solar Controller** | 12 V / 15 A MPPT with Bluetooth & low-voltage load disconnect | 1 | [Victron SmartSolar MPPT 75/15](https://lightharvestsolar.com/products/victron-smartsolar-mppt-75-15-charge-controller-bluetooth-monitoring) |
| **Folding Solar Panel** | 100 W monocrystalline portable folding panel (18–22 V Voc, MC4 or Anderson output) | 1 | Search: `100W folding monocrystalline solar panel Anderson` |
| **RPi 5 Power Buck** | 12 V → **5 V / 5 A (25 W+)** USB-C PD buck converter *(do NOT use a 3 A buck—RPi 5 will brown out)* | 1 | Search: `12V to 5V 5A USB-C PD step down buck converter` |
| **Starlink Mini DC Boost** | 12 V → 24 V or 30 V (72 W–105 W) waterproof DC boost converter with Starlink Mini barrel plug | 1 | [Bullet Proof Diesel 12V/24V to 30V 3.5A Boost](https://bulletproofdiesel.com/products/starlink-mini-12v-adapter) or [XTAR-LINK 12V to 24V 72W Boost](https://xtar-link.com/products/starlink-mini-12v-to-24v-dc-step-up-converter) |
| **DC Fuse Block & Bus Bar** | 6-circuit ATO/ATC blade fuse block with negative bus + 30 A, 15 A, 10 A, 5 A blade fuses | 1 | Search: `6-way marine blade fuse block with negative bus` |
| **Panel Switches & Ports** | 2× IP67 20 A rocker switches (`MAIN` + `STARLINK`), 1× IP67 Anderson Powerpole panel mount | 1 set | Search: `IP67 Anderson Powerpole panel mount bulkhead` |

### Enclosures, RF & Thermal
| Item | Exact Spec to Buy | Qty | Notes / Search Terms |
| :--- | :--- | :--- | :--- |
| **Active Ammo Can** | **40 mm (PA120)** or **Fat-50 (PA108)** military surplus steel ammo can | 1 | Verify intact steel lid seam and latches; buy light tan spray paint to reduce solar heat gain |
| **Cold-Spare Can** | Standard **`.50 cal` (M2A1)** steel ammo can + 1/4" closed-cell EVA foam sheet | 1 | **Do NOT drill any holes in this can** |
| **RF Bulkheads & Pigtails** | 2× N-Type Female panel bulkheads + 2× 12" RG316/LMR-195 SMA-Male to N-Male internal pigtails | 2 sets | Match SMA vs. IPEX/U.FL connector on your specific LoRa boards |
| **External 915 MHz Antennas** | 2× 915 MHz N-Type Male fiberglass/whip antennas (3–5.8 dBi) | 2 | One tuned for US 915 MHz Meshtastic, one for MeshCore |
| **Thermal Management** | 1/8" aluminum mounting plate + 2 mm silicone thermal pads + 2× IP67 Gore-Tex M12 breather vents | 1 set | Optional: 12 V 40 mm brushless fan + 40°C normally-open KSD9700 thermal switch |

### EMP Surge Protection & Grounding
| Item | Exact Spec to Buy | Qty | Notes / Search Terms |
| :--- | :--- | :--- | :--- |
| **Conductive RF Lid Gasket** | Conductive silver/nickel elastomer or beryllium-copper EMI gasket tape (3/8"–1/2" wide) | 2 rolls | Enough for BOTH Can #1 and Can #2 lid rims |
| **Coax Surge Arrestors** | N-Type Male-to-Female Gas Discharge Tube (GDT) lightning arrestors (0–3 GHz or 0–6 GHz, 50 Ω) | 2 | Screw directly onto external N-Type bulkheads |
| **Ethernet Surge & Port** | IP67 shielded RJ45 panel bulkhead + inline shielded Cat6A Gigabit Ethernet surge protector | 1 set | For Starlink Mini Ethernet uplink |
| **DC Surge & Ferrites** | 18 V–24 V bidirectional TVS diodes (1.5KE / SMBJ series) + 6× snap-on **Type-31** ferrite chokes | 1 set | Clamp ferrites on solar, Starlink DC, Ethernet, and both internal USB LoRa cables |
| **Common Ground Stud** | 1/4"-20 solid brass bolt, lock washers, ring lugs, and 1/2" flat tinned-copper ground braid | 1 set | Bonds all surge arrestors to a single external ground point |

---

## 4. Tools & Consumables Needed

- Cordless drill + **step drill bit (unibit)** up to 1-1/8" + cutting oil (steel ammo cans dull dry bits fast)
- Center punch, metal deburring tool, and fine sandpaper / wire wheel (for stripping paint off lid rims and ground points)
- Wire stripper, ratchet crimper (for insulated ring/spade lugs and Anderson Powerpoles), 12 AWG & 16 AWG marine tinned copper wire (red/black)
- Digital multimeter (mandatory before powering on!)
- Adhesive-lined heat-shrink tubing, Loctite Blue 242, RTV neutral-cure silicone sealant, and dielectric grease

---

## 5. Step-by-Step Build Instructions

### Step 1: Prep Both Ammo Cans & Conductive RF Gaskets
1. Remove the factory rubber lid gasket from both Can #1 and Can #2.
2. Use sandpaper or a wire wheel to strip paint down to **bare bright steel** all the way around the top mating rim of each can and the matching channel inside each lid. Wipe clean with isopropyl alcohol.
3. Press the **conductive RF gasket** evenly into the lid channel so closing the latch creates continuous 360° metal-to-metal RF contact.
4. *(Recommended)* Paint the outside of Can #1 light tan/sand to cut internal temperatures by 15–20°F in direct summer sun.

### Step 2: Drill & Mount External Bulkheads (Can #1 Only)
Keep all holes on the upper third of the vertical walls (never on the flat top lid if avoidable, to prevent rain pooling):
1. **RF Bulkheads (Opposite Ends!):** Drill two holes for the **N-Type female bulkheads** on **opposite ends** of the ammo can (10–12 inches apart). Separating Meshtastic (`906.875 MHz`) and MeshCore (`910.525 MHz`) as far as possible prevents front-end RF desense.
2. **Power & Comms Panel (Front Side):** Drill and mount:
   - 1× IP67 Anderson Powerpole bulkhead (**SOLAR IN**)
   - 1× IP67 shielded RJ45 bulkhead (**STARLINK / LAN ETH**)
   - 1× IP67 DC bulkhead or waterproof cable gland (**STARLINK 24V/30V OUT**)
   - 2× IP67 rocker switches (**MAIN PWR** and **STARLINK PWR**)
   - 2× IP67 Gore-Tex breather vents (high on opposite sides for passive pressure/heat relief)
3. **Common Brass Ground Stud:** Drill a 1/4" hole near the RF/Ethernet side, sand paint to bare steel around the hole inside and out, and bolt the **1/4"-20 brass ground stud** tight with star lock washers.
4. Deburr every hole and seal around all bulkhead washers with neutral-cure RTV silicone.

### Step 3: Bond All EMP Surge Arrestors to the Ground Stud
1. Thread the two **N-Type GDT coaxial surge arrestors** onto the external RF bulkheads (or mount them immediately inside with short jumpers) and bond their ground lugs to the **brass ground stud** using short, flat tinned-copper braid.
2. Wire the **shielded Cat6A Ethernet surge protector** inline immediately inside the IP67 RJ45 bulkhead and bond its ground lead to the same brass stud.
3. Solder/crimp a **bidirectional TVS diode** across the `+` and `-` terminals of the internal Solar Powerpole input, and clamp **Type-31 ferrite chokes** onto the solar input leads, Starlink DC leads, Ethernet cable, and both internal USB LoRa cables.

### Step 4: Wire the Power Backbone (Follow Exact Order!)
> **CRITICAL MPPT RULE:** Always connect the **battery** to the Victron MPPT **before** plugging in a solar panel so the MPPT auto-detects 12 V correctly. Never run the MPPT with solar connected and battery disconnected.

Wire using 12 AWG for battery/solar/Starlink and 16 AWG for the RPi 5 buck:

```text
[12.8V 30Ah LiFePO4 (+)] ──┬──▶ [15A Inline Fuse] ──▶ [Victron MPPT Batt (+)] ◀── [15A Fuse] ◀── [Solar In]
                           │
                           └──▶ [30A Main Fuse] ──▶ [MAIN Rocker Switch] ──▶ [Fuse Block (+)]
                                                                                   ├──▶ [10A] ──▶ [5V/5A RPi 5]
                                                                                   ├──▶ [10A] ──▶ [STARLINK Switch] ──▶ [24V/30V Boost]
                                                                                   └──▶ [5A]  ──▶ [Optional 40°C Fan]
```

- Tie all negative (`-`) leads back cleanly to the fuse block's negative bus bar and the LiFePO4 `(-)` terminal.
- Strap the LiFePO4 battery firmly to the bottom of the ammo can with heavy nylon webbing and foam padding so it cannot shift during transport.

### Step 5: Mount RPi 5, Thermal Plate & Dual LoRa Radios
1. Bolt your **Raspberry Pi 5** (with Active Cooler) and both **USB LoRa bridge boards** onto the **1/8" aluminum sub-plate** using brass standoffs.
2. Place a 2 mm silicone thermal pad between the aluminum sub-plate and the lower inner steel wall of the ammo can so heat conducts out through the steel shell.
3. Connect the two internal RF pigtails from the LoRa boards to the N-Type bulkheads (**label both ports clearly inside and out: `MESHTASTIC 906.875` and `MESHCORE 910.525`**).
4. **Attach both external 915 MHz antennas BEFORE turning on power.**
5. Plug both shielded USB data cables into your labeled RPi 5 USB ports.

### Step 6: Assemble Can #2 (Unpenetrated Cold-Spare Faraday Can)
1. Line the entire inside of the `.50 cal` steel can (bottom, walls, and underside of lid) with **1/4" non-conductive EVA foam** so nothing touches the bare metal shell.
2. Pack inside anti-static bags:
   - 1× pre-flashed spare Raspberry Pi 5 + cloned SD/NVMe card
   - 2× pre-flashed USB LoRa bridge nodes (matching `bridge/radio-presets.md`)
   - 1× spare Seeed T1000-E + 1× spare RAK4631
   - 2× spare USB data cables + 2× spare RF pigtails + 1× spare 5 V/5 A buck converter
3. Latch the RF-gasketed lid shut and store dry.

### Step 7: Configure Starlink Mini Automatic Failover (`rpi5/src/`)
Drop these files onto your RPi 5 so unplugging Starlink Mini never stalls local comms:

**1. `/etc/systemd/network/10-starlink-wan.network`** *(commit to `OrdnanceMesh/rpi5/src/`)*:
```ini
[Match]
Name=eth0

[Network]
DHCP=ipv4
DNSDefaultRoute=yes

[DHCPv4]
RouteMetric=100
```

**2. `/etc/systemd/network/20-ordnance-lan.network`** *(local Wi-Fi AP or USB-Ethernet LAN for EUDs, zero default gateway)*:
```ini
[Match]
Name=wlan0

[Network]
Address=10.88.0.1/24
ConfigureWithoutCarrier=yes
```

**3. `/usr/local/bin/ordnance-wan-monitor.sh`** *(checks WAN every 5s and logs/triggers failover cleanly)*:
```bash
#!/usr/bin/env bash
set -euo pipefail

STATE_FILE="/run/ordnance-wan.state"
PREV_STATE="$(cat "$STATE_FILE" 2>/dev/null || echo "OFFLINE")"

if ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; then
  NEW_STATE="ONLINE"
else
  NEW_STATE="OFFLINE"
fi

if [ "$NEW_STATE" != "$PREV_STATE" ]; then
  echo "$NEW_STATE" > "$STATE_FILE"
  logger -t ordnance-wan "WAN state changed: ${PREV_STATE} -> ${NEW_STATE}"
  # Hook future Phase 3/5 actions here (e.g., TAK federation or Project NOMAD sync)
fi
```

Enable `systemd-networkd` and run `ordnance-wan-monitor.sh` via a 5-second `systemd` timer (matching the Phase 1 watchdog pattern).

---

## 6. Pre-Power Smoke Test (Do NOT Skip!)

Before plugging in the RPi 5 or Starlink Mini:
1. Leave `MAIN` and `STARLINK` switches **OFF**. Verify battery terminal polarity with a multimeter (`~13.2 V DC`).
2. Flip `MAIN` **ON** (with RPi 5 still unplugged). Verify **5.0–5.15 V DC** at the RPi 5 USB-C PD output.
3. Flip `STARLINK` **ON** (with Starlink still unplugged). Verify **24 V or 30 V DC** (matching your boost converter) at the Starlink DC port.
4. Connect the Victron SmartSolar app via Bluetooth and set battery preset to **LiFePO4** (`14.2 V` absorption, `13.5 V` float).
5. Plug in the 100 W solar panel in sunlight and confirm positive charge current in VictronConnect.
6. Confirm both 915 MHz antennas are screwed on tight, then plug in the RPi 5 and verify `bash rpi5/src/check-radios.sh` passes all green.

---

## 7. Phase 2 Field Deployment & Exit Gates

When deploying in the field:
1. Drive a short portable **copper ground rod** (2–4 ft) into damp earth if stationary, and clip a ground lead to the OrdnanceBox brass ground stud.
2. Position the 100 W solar panel facing south at ~30–45° tilt and shade the ammo can behind the panel to keep internal temperatures low.
3. Run the four **Phase 2 Exit Gates** before moving to Phase 3:
   - [ ] **48-Hour Solar/Battery Soak:** Run the closed OrdnanceBox outdoors for 48 hours; confirm CPU stays below 75°C and LiFePO4 recovers cleanly each day.
   - [ ] **RF Desense Check:** Compare Meshtastic & MeshCore SNR/RSSI on the ammo-can bulkheads against your Phase 1 benchtop baseline (target **< 3 dB** degradation).
   - [ ] **Starlink Plug/Unplug Drill:** Flip the `STARLINK` switch OFF mid-session and confirm dual-mesh bridging stays 100% live within 5 seconds.
   - [ ] **Cold-Spare Swap Drill:** Open Can #2, swap in the spare RPi 5 + radios, and confirm full bidirectional bridging in **under 10 minutes**.
