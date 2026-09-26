# Bill of materials

Quantities are for one gate unit. Items marked TODO are waiting on the caliper
(see `docs/dimensions.md`).

## Electronics

| Item | Spec | Notes |
|---|---|---|
| Main board | Waveshare ESP32-S3-AUDIO-Board (SKU 32184, with battery) or 32185 (without) | ESP32-S3R8, 16 MB flash, 8 MB octal PSRAM |
| Speaker | Supplied with the kit, GH1.25 2 pin into H3 | Measured from the vendor STEP: Ø 43.30 x 20.50, no screw holes of its own (clamped by the housing) |
| Battery | 3.7 V Li-ion, MX1.25 2 pin | Optional; see ADR-011 |
| Antenna | 2.4 GHz with IPEX/U.FL pigtail | Optional, for the external antenna on IPEX1 (requires moving an onboard 0R resistor) |

## Power chain (ADR-016)

Two stages, both off the shelf. A potted 5 V mains unit is scarce; a 12 V one is a commodity, and 12 V is
the better voltage to run over any distance between the 220 V point and the gate.

| Order | Item | Spec | Notes |
|---|---|---|---|
| 1 | Potted outdoor driver | 220 V AC to 12 V DC, **IP67**, 12 to 24 W | Lives outside the printed part: the gate's electrical box, or strapped to the post. Its own IP rating is the weatherproofing. 24 W gives 2 A at 12 V, twice the headroom the 5 V side needs |
| 2 | Buck module | 12 V to **5 V, 3 A** fixed output (Mini560 class, about 22 x 17 x 6 mm) | Inside the case, on the gland side. Set the output to 5 V and verify with a meter before connecting the board |
| 3 | USB-C pigtail | USB-C male to two bare wires, 24 AWG, 5 V 3 A | Into the board's USB-C, so the charger path and the input protection stay as Waveshare designed them |
| 4 | Cable gland | PG7 or M12, IP68, with nut | The only penetration for power. A PG7 takes a 3 to 6.5 mm cable, which is the two-conductor 12 V cable below |
| 5 | 12 V cable | Two conductors, **0.75 mm² (18 AWG)**, outdoor rated, with polarity marked | Runs from the driver down to the case. 12 V tolerates a run where 5 V would sag: at 1 A the drop is under 0.5 V even at 30 m |
| 6 | In-line fuse | 1 A, on the 12 V positive, at the driver end | Cheap insurance for a pinched cable, which the driver's own protection does not cover |
| 7 | Terminal block | 2-way screw terminal or a lever nut (Wago 221 class) | Where the 12 V lands before the buck, so the case opens without unsoldering anything |

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

| Item | Spec | Notes |
|---|---|---|
| Filament | ASA, 1.75 mm | ADR-009. ABS and PETG are rejected for outdoor service |
| Acoustic membrane | ePTFE acoustic vent, adhesive backed, 8 to 12 mm | Over the microphone ports |
| Insect mesh | Stainless or nylon, 0.2 to 0.5 mm aperture | Behind the speaker grille |
| Gasket | Silicone cord 2 mm, or a matching O-ring | Sits in the lid groove |
| Cable gland | PG7 or M12, IP68, with a matching nut | Power cable entry |
| Blind plug | Same thread as the gland | For the antenna opening if it is not used yet |
| Heat-set inserts | M3, 5 mm long | One per screw pillar (review 3: two of them) |
| Screws | M3 x 12, stainless, socket head | Lid to base, two of them, into the inserts |
| Mounting screws | M4 x 40, stainless, with wall plugs | Wall or pole mount, two of them, on the case's centre line a quarter up and a quarter down (ADR-021) |
| Desiccant | Silica gel sachet | Inside the sealed cavity, replaced at each service |

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
