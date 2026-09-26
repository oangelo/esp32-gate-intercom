# Bill of materials

Quantities are for one gate unit. Items marked TODO are waiting on the caliper
(see `docs/dimensions.md`). Links are AliExpress product pages; the items left
without a link (screws, silica gel, filament, insect mesh) are hardware-shop stock,
where a listing would only go stale.

## Electronics

| Item | Spec | Link | Notes |
|---|---|---|---|
| Main board | Waveshare ESP32-S3-AUDIO-Board (SKU 32184, with battery, or 32185 without) | waveshare.com | ESP32-S3R8, 16 MB flash, 8 MB octal PSRAM. **In hand** |
| Speaker | Supplied with the kit, GH1.25 2 pin into H3 | - | Measured from the vendor STEP: Ø 43.30 x 20.50, no screw holes of its own (clamped by the housing). **In hand** |
| Panel switch | 22 mm cutout, metal momentary (1NO), IP65 or better, red, **LED rated 3-6 V** | [12/16/19/22 mm momentary metal switch](https://www.aliexpress.us/item/3256805376351484.html) · [ring-LED version](https://www.aliexpress.us/item/3256808446358485.html) | The gate bell. **Pick the 3-6 V LED option**, not the 12 V or 24 V one: it runs off the same 5 V rail, with its own series resistor. Contacts between GPIO0 and GND, plus a 1 k series resistor and 100 nF to GND at the board end (ADR-018). The case's cutout is 22.00 and the land behind the face is flat; head diameter and body depth are measured on arrival |
| Battery | 3.7 V Li-ion, MX1.25 2 pin | - | Optional; see ADR-011 |
| Antenna | 2.4 GHz with IPEX/U.FL pigtail | - | Optional, for the external antenna on IPEX1 (requires moving an onboard 0R resistor) |

## Power chain (ADR-016)

Two stages, both off the shelf. A potted 5 V mains unit is scarce; a 12 V one is a commodity, and 12 V is
the better voltage to run over any distance between the 220 V point and the gate.

| Order | Item | Spec | Link | Notes |
|---|---|---|---|---|
| 1 | Potted outdoor driver | 220 V AC to 12 V DC, **IP67**, 12 to 24 W | [IP67 driver, 220 V to 12 V](https://www.aliexpress.com/item/1005012130085444.html) · [same, other seller](https://www.aliexpress.com/item/1005009594792009.html) | Lives outside the printed part: the gate's electrical box, or strapped to the post. Its own IP rating is the weatherproofing. 24 W gives 2 A at 12 V, twice the headroom the 5 V side needs |
| 2 | Buck module | 12 V to **5 V, 3 A or more** fixed output (Mini560 class, about 22 x 17 x 6 mm) | [Mini560, 5 A max](https://www.aliexpress.com/item/1005001629723875.html) | Inside the case, on the gland side. Set the output to 5 V and verify with a meter before connecting the board |
| 3 | USB-C pigtail | USB-C male to two bare wires, 24 AWG, 5 V 3 A | [USB-C male to bare wire](https://www.aliexpress.com/item/1005009575976077.html) · [2-pin open end, 24 AWG](https://www.aliexpress.com/item/1005009576021095.html) | Into the board's USB-C, so the charger path and the input protection stay as Waveshare designed them |
| 4 | Cable gland | **PG7**, IP68, with nut, for a 3 to 6.5 mm cable | [PG7/PG9 IP68 nylon gland](https://www.aliexpress.com/item/1005010677536282.html) · [10-pack PG7](https://www.aliexpress.com/item/32860545314.html) | The only penetration for power, in the case's top boss. The hole is **Ø12.50** — the PG7's own thread — and its first 1.20 mm stay round so the gland's washer seals on a flat face (ADR-025). An M12 gland would need that hole redrawn |
| 5 | 12 V cable | Two conductors, **0.75 mm² (18 AWG)**, outdoor rated, polarity marked | [18 AWG 0.75 mm², 2-core](https://www.aliexpress.com/item/1005001371010626.html) · [rubber, 2-core](https://www.aliexpress.com/item/33024165219.html) | Runs from the driver down to the case. 12 V tolerates a run where 5 V would sag: at 1 A the drop is under 0.5 V even at 30 m |
| 6 | In-line fuse | 1 A, on the 12 V positive, at the driver end | [5x20 in-line holder](https://www.aliexpress.us/item/3256801196034421.html) | Cheap insurance for a pinched cable, which the driver's own protection does not cover. Buy the 1 A glass fuses locally |
| 7 | Terminal block | 2-way screw terminal or a lever nut | [221-series lever connectors](https://www.aliexpress.com/item/1005012342041146.html) | Where the 12 V lands before the buck, so the case opens without unsoldering anything |

Power budget: the board pulls up to about 2 A at 5 V with the class-D amplifier at full output (the onboard
MP1605GTF-Z regulator is rated 3.3 V 2 A), so 5 V 2 A is the floor and 3 A is the comfortable size. On the
12 V side that is under 1 A, which is why a 12 to 24 W driver is enough.

Rejected: a bare open-frame mains module (HLK-PM01/HLK-10M05 class) inside the printed case. It is the
cheapest way to get 5 V and the one combination ADR-016 exists to prevent: 220 V sharing a sealed volume
with condensate, in a printed ASA box that is not a certified mains enclosure.

Alternative single stage: a certified 5 V 2 A adapter in its own IP65 junction box outside, 5 V through the
gland, no buck and no pigtail. One more enclosure, one fewer part, and it works only if the 220 V point is
close enough that 5 V does not sag over the run.

## Enclosure

| Item | Spec | Link | Notes |
|---|---|---|---|
| Filament, case | ASA, 1.75 mm | - | ADR-009. ABS and PETG are rejected for outdoor service. About **100 g** for the base and the lid together (their meshes displace 65.1 and 17.5 cm³ of solid), so one spool is many attempts |
| Filament, gasket | TPU 95A, 1.75 mm | - | In hand. See the gasket line for how to print it |
| Acoustic membrane | ePTFE acoustic vent, adhesive backed, Ø10 to Ø12, 0.30 to 0.35 thick | [IP67 acoustic membrane for MIC/speaker](https://www.aliexpress.com/item/1005008666249037.html) | Two, one per microphone slot (1.20 x 8.00). The CAD draws them as 5.00 x 12.00 patches that follow the bottom's curve — nothing is cut for them (ADR-023) |
| Vent membrane | ePTFE, IP67 or IP68, hydrophobic **and oleophobic**, Ø10.00 x 0.30 to 0.35 | [OD10/ID5, 0.35 thick](https://www.aliexpress.com/item/1005008928111367.html) · [OD10/OD14, 0.30](https://www.aliexpress.com/item/1005009140921077.html) · [size ladder, OD4/ID2 to OD20/ID15](https://www.aliexpress.com/item/1005008646960056.html) | Drops into the Ø11.00 x 0.35 recess in the vent's mouth, so it finishes flush with the wall (ADR-026). Oleophobic is not optional: without it oil mist closes the pores and the case stops breathing silently |
| Grille membrane | ePTFE acoustic vent sheet, hydrophobic | same sheet as the acoustic membrane | Behind the grille's perforated field (Ø44 of Ø2.00 holes, ADR-017/018). Cut from the microphone sheet; no marker of its own in the CAD yet |
| Insect mesh | Stainless or nylon, 0.2 to 0.5 mm aperture | - | Behind the speaker grille |
| Gasket | **Printed in TPU 95A**: the ring the CAD exports, 1.70 wide x 1.00 thick, squeezed to 0.70 when the halves close | `make gasket` | The user's call (2026-09-26), replacing ADR-024's closed-cell silicone foam: a printed ring springs back instead of taking a set, and TPU is already on the shelf. Print it **soft** — the 1.70 mm of ring fits about two 0.45 mm lines, so 2 walls, 10 to 20 % infill (none at all leaves a soft hollow tube) and 2 top/bottom layers so the two seal faces come out solid. 30 % is a gasket's normal squeeze, but a *solid* TPU ring would need far more force to reach it than two M3 screws can deliver into printed ASA; if you would rather print solid, drop `gasket_t` to 0.80 first |
| Heat-set inserts | M3, **4.6 OD x 5 long** | [M2 to M6 brass heat-set inserts](https://www.aliexpress.us/item/3256803396040989.html) | Two, one per screw pillar. The pillar's blind hole is Ø4.00 x 10.00, so the insert is a press fit into printed ASA |
| Screws | M3 x 12, stainless, socket head (DIN 912) | - | Lid to base, two of them, into the inserts. The head is Ø5.5 x 3.0 and the case counterbores for it |
| Mounting screws | M4 x 40, stainless, with wall plugs, head **up to Ø8.00** | - | Wall or pole mount through the back plate, two of them, on the case's centre line a quarter up and a quarter down. The plate is 1.90 thick with a Ø8.00 x 1.50 pocket for the head and a Ø4.50 through hole (ADR-021, ADR-027) |
| Desiccant | Silica gel sachet | - | Inside the sealed cavity, replaced at each service |

Open in the CAD, none of it blocking a first print: the mounting screws' thread is in the wall plug or the
post, the button's head and body are measured on arrival, and the antenna opening does not exist yet — if
it is added (roadmap F2), it needs a blind plug of the gland's own thread.

## Tools and consumables

| Item | Spec | Notes |
|---|---|---|
| Enclosed 3D printer | Chamber capable of roughly 50 °C | ASA needs it |
| Digital caliper | 0.01 mm resolution | Source of every dimension in `docs/dimensions.md` |
| Multimeter | - | Continuity and the amplifier enable check |
| USB-C cable | Data capable | The board enumerates as USB Serial/JTAG |

## Reference prices

Not tracked here on purpose: prices change and a stale number is worse than no number. The notable
ones: the board is a 15 to 18 USD class part, the ASA spool and the membrane are the items that decide
whether the installation survives a year outdoors.
