# Bill of materials

Quantities are for one gate unit. Items marked TODO are waiting on the caliper
(see `docs/dimensions.md`).

## Electronics

| Item | Spec | Notes |
|---|---|---|
| Main board | Waveshare ESP32-S3-AUDIO-Board (SKU 32184, with battery) or 32185 (without) | ESP32-S3R8, 16 MB flash, 8 MB octal PSRAM |
| Speaker | Supplied with the kit, GH1.25 2 pin into H3 | Diameter and depth TODO |
| Battery | 3.7 V Li-ion, MX1.25 2 pin | Optional; see ADR-011 |
| Antenna | 2.4 GHz with IPEX/U.FL pigtail | Optional, for the external antenna on IPEX1 (requires moving an onboard 0R resistor) |

## Enclosure

| Item | Spec | Notes |
|---|---|---|
| Filament | ASA, 1.75 mm | ADR-009. ABS and PETG are rejected for outdoor service |
| Acoustic membrane | ePTFE acoustic vent, adhesive backed, 8 to 12 mm | Over the microphone ports |
| Insect mesh | Stainless or nylon, 0.2 to 0.5 mm aperture | Behind the speaker grille |
| Gasket | Silicone cord 2 mm, or a matching O-ring | Sits in the lid groove |
| Cable gland | PG7 or M12, IP68, with a matching nut | Power cable entry |
| Blind plug | Same thread as the gland | For the antenna opening if it is not used yet |
| Heat-set inserts | M3, 5 mm long | One per screw boss |
| Screws | M3 x 12, stainless, socket head | Lid to base, four of them |
| Mounting screws | M4 x 40, stainless, with wall plugs | Wall or pole mount |
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
