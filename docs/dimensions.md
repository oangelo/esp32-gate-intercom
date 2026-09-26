# Dimensions

The enclosure must fit the real board, so every number here comes from an authoritative source: the
vendor's mechanical drawing (DXF or STEP), a caliper on the actual board, or a measurement taken on
the live hardware. Vision estimates, product photos and concept renders are **not** a source — a
vision pass on the vendor's drawing image misread the assembly heights, which is why the numbers below
were taken from the files themselves.

## Source files (not redistributed, see ADR-012)

| File | Where | Notes |
|---|---|---|
| Mechanical drawing archive | `https://files.waveshare.com/wiki/ESP32-S3-AUDIO-Board/ESP32-S3-AUDIO-Board.rar` (4215746 bytes) | Contains `ESP32-S3-AUDIO-Board.stp` (26.4 MB, 3D), `.dxf` (1.7 MB, 2D) and `.pdf` (44 KB, dimensioned) |
| Schematic v1.1 | `https://files.waveshare.com/wiki/ESP32-S3-AUDIO-Board/ESP32-S3-AUDIO-Board_1.1.pdf` | Already read: pinout, amplifier enable, battery path, camera and AEC nets |
| Product page | `https://www.waveshare.com/esp32-S3-audio-board.htm` | Confirms the DVP camera interface supports OV2640 / OV5640 |

The archive is RAR5; `7z` refuses it (`Unsupported Method`), `unar` extracts it. Extracted locally to
`~/Downloads/waveshare-audio-board/extracted/drawing/` (not in this repository):

| Extracted file | Size | md5 |
|---|---|---|
| `ESP32-S3-AUDIO-Board.dxf` | 1721501 | `3c673095b9ee4a29abcdf27da1aff241` |
| `ESP32-S3-AUDIO-Board.pdf` | 44270 | `06294cd5c1b07fd03c4bd1fee8059acd` |
| `ESP32-S3-AUDIO-Board.stp` | 26409699 | `3109779fbcfa025436a1270171bf46b6` |

The PDF has no text layer (it is CAD output, needs OCR), so the numbers below were read from the DXF
itself with `tools/dxf_probe.py`, which parses group-code pairs and reports extents, holes and the
measurement values of the DIMENSION entities. Reproduce with:

    python3 tools/dxf_probe.py <drawing>.dxf --text

The DXF carries exactly 8 DIMENSION entities; reading their group code 42 (the real measurement, not
the rendered text) returns 37.60, 42.60, 44.30, 47.00, 58.00, 28.00, 42.93 and 19.18 — the values in
the tables below.

The STEP is the third and richest source. It is not only the board: it is the **finished product
assembled**, 5547 solids, every part named (`TYPE-C_16PIN-9X3X7_3`, `MIC-4X3X1MM`, `SPK-4020-5W`,
`BATTERY-803040-1000MAH`, `HEX_STUDS-M2_5XH25MM`, the acrylic parts, the housing base). Read headless
with `freecadcmd` (`Import.insert` into a document, then `Shape.BoundBox` and `Shape.Faces` per
object), it yields the position of every connector, the acoustic port of each microphone, the speaker,
the cell and the mounting hardware in one consistent frame. The DXF cannot do that: it is a mechanical
drawing, and inside the Ø58 outline it carries only the outline, the three holes and the two central
FPC connectors — nothing else of the board is drawn there.

**Frame convention for every STEP number below:** the assembly frame, in millimetres, z = 0 at the top
of the product, floor at z = -50.60. The PCB occupies z -8.80 .. -7.60, so the **component side is
z = -7.60** (mics, USB-C, header, SD slot) and the **solder side is z = -8.80** (RGB LEDs, speaker
header). "r" and the angle are measured from the centre of the board in that same frame.

## Measured from the vendor DXF

**The board is round.** This invalidated an earlier assumption (a rectangular 60 x 40 board) that was
corrected before any geometry was drawn.

| Feature | Value | How it was obtained |
|---|---|---|
| Board outline | circle, **diameter 58.00 mm** | DIMENSION entity value 58.0 over a 90 degree vertical dimension, plus a CIRCLE of d=58.00 |
| Mounting holes | **3 holes, diameter 4.00 mm**, each with a 4.80 mm ring | three CIRCLE pairs at identical centres |
| Hole pattern | 120 degrees apart on a **radius of 23.75 mm** from the board centre | computed from the hole centres; cross-checked by the 28.00 mm chord between two of them |
| Hole spacing, measured dims | **28.00** between two holes; **42.93** in X and **19.18** from centre to the third | DIMENSION entities |
| Speaker face (same sheet, second view) | concentric circles **57.04, 52.00, 48.50, 46.20, 44.82** | CIRCLE entities, one shared centre |
| Assembly heights (section view) | **37.60, 42.60, 44.30, 47.00** | DIMENSION entities |

Interpretation: the vendor drawing documents the board together with its reference enclosure (a
cylinder with a translucent band for the RGB ring, USB-C on the side and the speaker grille in the
bottom face). It is a desk product shape, not a weatherproof one. The board diameter, the three-hole
pattern and the speaker dimensions are the parts worth reusing.

## Measured from the vendor STEP

Board, its components and the reference mechanics. Sizes are bounding boxes, so a part can be placed
in the new case without arithmetic later.

| Item | Size (mm) | Position (mm) | Notes |
|---|---|---|---|
| PCB | 57.63 x 56.54 x **1.20** thick | centre (0, 0.04), z -8.80..-7.60 | 1.20 thick, not 1.6. The bounding box is smaller than the DXF's Ø58 circle: the outline is not a pure circle, or it has flats — confirm with a caliper |
| Mounting holes / standoffs | 3 x **M2.5** (screw Ø4.00, boss Ø4.80) | r = **23.75** at **-36.1°, +36.1°, 180°** | the vendor stack is HEX_STUDS-M2_5XH25MM (25 mm below the board) + HEX_STUDS-M2_5X5-H (11 mm above) + KM2_5X5 screws driven through the top cover |
| USB Type-C | 8.94 x 7.60 x 4.12 | centre (0, **-24.60**), mouth at y = -28.40, z -8.41..-4.29 | the shell runs from **0.39 mm above the PCB's bottom face** to **3.31 mm above its top face** |
| Pin header, 2x9, 90 degree | 22.86 x 13.00 x 7.80 | centre (0, **+20.00**), z -10.40..-2.60 | tallest part on the component side: **5.00 mm above the PCB top**, 1.60 below the bottom |
| Microphone package, x2 | 4.99 x 4.87 x 1.00 | centres (±17.25, +20.50), z -7.60..-6.60 | component side, r = 26.8, angles 50.0° and 130.0° |
| **Microphone acoustic port, x2** | Ø 0.66, 0.66 deep, domed mesh | **(+18.24, +19.68)** and **(-18.30, +19.76)**, r = 26.83 / 26.94, angles 47.2° / 132.8° | the recess opens on the **top face of the package** (z = -6.60), that is, on the component side; **36.54 mm between the two** |
| RGB LEDs, ring of 7 | 2.00 x 3.00 x 1.50 each (rotated tangentially) | r = **22.00**, **51.43°** apart (360/7), z -10.30..-8.80 | on the **solder** side, shining into the vendor's translucent band; free to be used as a status light on the new case |
| microSD slot | 15.00 x 16.10 x 2.45 | centre (17.80, 0.95), z -8.20..-5.75 | component side, r = 17.8 |
| Display FPC, 16 pin | 12.00 x 5.69 x 2.00 | centre (0, -7.16), z -7.60..-5.60 | component side, near the centre |
| Speaker header | 4.05 x 4.35 x 4.60 | (-17.52, -6.00), z -13.30..-8.70 | 1 mm pitch, 2 pin, on the **solder** side; protrudes **4.50 below the PCB bottom** |
| Chip antenna / charge LED | 3.49 x 3.30 x 1.25 / 2.64 x 2.10 x 1.00 | (-21.51, +15.81) / (+9.36, -25.99) | both on the component side |
| Speaker SPK-4020-5W | **Ø 43.30 x 20.50** | z -42.10..-21.60 | **no mounting holes of its own**: in the vendor product the housing clamps it, so the new case needs its own ring or claws |
| Battery 803040, 1000 mAh | 30.49 x 41.98 x **8.49** | centre (-0.35, 0.25), z -21.35..-12.85 | below the board, in front of the speaker; optional (ADR-011) |
| Reference housing | base Ø58 x 30.67; acrylic band Ø58 x 7.40; acrylic cover Ø58 x 1.70; bottom disc Ø52 x 5.80; 3 rubber feet 2.70 thick | band z -16.20..-8.80, cover z -2.60..-0.90, feet z -50.60..-47.90 | the band is the translucent ring the LEDs shine through; in the reference product the speaker fires **downward** and the feet lift it off the table |

Cavity heights derived from the table, which is what the case has to clear:

| Direction | Governed by | Value |
|---|---|---|
| Above the component side | the 2x9 header | **5.00 mm** plus clearance |
| Below the solder side | the speaker header | **4.50 mm** plus clearance |
| Battery bay, if the cell stays | the 803040 cell | 30.49 x 41.98 x 8.49 |

## Cross-check: the two vendor files agree

The DXF's four assembly heights land exactly on the STEP's part positions:

| DXF dimension | STEP geometry |
|---|---|
| 47.00 | top of the acrylic cover (z -0.90) to the bottom of the Ø52 disc (z -48.10); 49.70 including the rubber feet |
| 44.30 | top of the cover to the bottom face of the body (z -45.20) |
| 42.60 | to the inner face of the acrylic cover (z -2.60) |
| 37.60 | from the **top of the PCB** (z -7.60) to the bottom of the body |

Two independently produced files describing the same revision. Where they disagree (the board outline,
above), the caliper decides — and on 2026-09-26 it did, on both the unit's diameter and its height: see
the section below.

## Calipered on the real unit (2026-09-26)

The assembled Waveshare, measured with a caliper. These are the numbers the CAD uses, because the rule
holds: the vendor file describes a reference board, the caliper describes this one.

| Feature | Caliper | Vendor says | Effect |
|---|---|---|---|
| Body diameter | **57.50** | 58.00 (the DXF circle), 57.63 x 56.54 (the STEP board's bounding box) | both vendor numbers are high, by 0.50 and 0.13. The cavity stays Ø60, so the gap around the unit grows from 1.00 to **1.25 mm**; the collar on the floor is bored **57.90** (the unit plus 0.2 a side) and is 1.25 mm thick, still Ø60.40 outside, so its outer 0.20 mm keeps fusing with the cavity's wall |
| Height, whole unit with its three rubber feet | **50.00** | 49.70 (the STEP, assembled) | 0.30 more than the STEP, which is the number the earlier rounds treated as the truth |
| Height, feet off | **47.30** | 47.00 (the DXF, to the Ø52 disc), 43.70 + 5.10 = 48.80 (the product page) | the model uses **47.30**: the feet are peeled because they stick out of the grille face. The case's outer depth follows it to **58.70** |

Those two caliper numbers are what `cad/case.scad` takes at the top of the file (`unit_dia`, `unit_h`), and
the whole depth chain follows from them: `case_d` 58.70 = the unit's face 6.20 behind the crown + 47.30 +
the 1.80 mm gap the microphones breathe + the 3.40 mm plate. The plate's inner face therefore sits at
**55.30**, and everything keyed to it (the collar, the M4 pockets, the standoff pads, the M3 pillars) moves
with it; only `mic_slot_cy` needed a hand, to 50.30, which keeps the slot's back end 0.80 mm inside the gap.

Two things this does not settle, and both are worth a second pass with the caliper:

- **Whether 57.50 is the body's widest point.** It is *less* than both vendor numbers for the outline, and
  the housing has to contain the board, so one of the three is off. If a reading at the widest point comes
  back as 58.00, the collar's bore goes back to 58.40 and the gap to 1.00 mm: two variables, `lip_bore`
  and `lip_wall`.
- **The Ø52 grille disc.** Not measured. The seat is Ø53.0 and the retaining lip grips 2 mm of the disc,
  so a disc that comes back over Ø53.0 has its seat re-cut.

## Verified on the board (independent of the drawing)

| Item | Value | How it was checked |
|---|---|---|
| MCU | ESP32-S3R8, 16 MB flash, 8 MB octal PSRAM | `esptool` read |
| Microphone ADC | ES7210 at I2C 0x40 | live I2C scan |
| DAC | ES8311 at I2C 0x18 | live I2C scan |
| I/O expander | TCA9555 at I2C 0x20, amplifier enable on EXIO8 (P1_0) | live scan plus vendor demo code |
| RTC | PCF85063 at I2C 0x51 | live I2C scan |
| I2C | SDA GPIO11, SCL GPIO10 | schematic and working config |
| I2S | MCLK GPIO12, BCLK GPIO13, LRCLK GPIO14, mic DIN GPIO15, speaker DOUT GPIO16 | schematic and working config |
| Buttons | BOOT on GPIO0 (used as the gate bell) | working config |
| Speaker connector | GH1.25 2 pin (H3) | schematic |
| Battery connector | MX1.25 2 pin, 3.7 V cell | schematic |
| Audio bus format | 16 kHz mono, 512-sample frames, 32 ms | working firmware |

## Still to be measured or confirmed

Much shorter than it was: the STEP answered the geometric questions. What is left is what a vendor CAD
file does not carry, plus the two parts the STEP names with library codes only.

| # | Measurement | Value | Notes |
|---|---|---|---|
| 1 | PCB outline: diameter and any flats | TODO | the STEP bounding box is 57.63 x 56.54 against the DXF's Ø58.00 circle. Measure both axes and note whether the edge has castellated pads that stick out |
| 2 | Confirm the MEMS acoustic port is on the component side | TODO | the STEP says yes (a Ø0.66 recess with a mesh on the top face of the package). The check is a loupe on the real board, and it decides which wall of the case carries the acoustic ports |
| 3 | Panel button: head diameter, body depth behind the panel, thread length, panel thickness range | TODO | the case-side part is a 22 mm cutout metal momentary switch with a 3-9 V LED (ADR-018). The seller's listing exposes no drawing, so measure the part on arrival. The cutout is 22 mm |
| 4 | Speaker cable length and the direction it leaves the board | TODO | routes from the speaker header at (-17.52, -6.00) on the solder side. The MX1.25 battery header is not identifiable in the STEP (library code), and only matters if the cell stays (ADR-011) |
| 5 | Weight of the assembled stack | TODO | sanity check for the wall/pole mount |

The tactile switches on the board (RESET, BOOT, user) are no longer a case constraint: the gate bell is
the external 22 mm switch wired to GPIO0 (ADR-018), so those three keep their vendor positions and are
only reachable with the lid off.

## Case parameters derived from the above

`cad/case.scad` takes these as parameters at the top of the file. Nothing in the geometry is allowed to
hold a hardcoded number: if a dimension changes, one variable changes and the model follows. The
`Makefile` renders and the checks in `tools/` verify that the board volume fits inside the cavity with
clearance and that no wall interferes with a connector.

Fixed by the measurements, with the unit going in **assembled** (roadmap item 5):

- The unit's envelope is Ø57.5 x **47.30**, both by caliper (see above): the assembled height 50.00 with
  the three rubber feet, minus their 2.70, because the feet stick out of the grille face and are peeled
  off. It governs the case's depth: **58.70 mm** outer, against the 49 the bare-board layout needed.
  Width stays 66.8 (the Ø60 cavity plus 1.25 a side plus the 3.4 mm shell) and height 96.8 (30 mm of
  straight side plus the two Ø66.8 ends).
- Its grille disc is Ø52 and its face sits 2.90 mm proud of the Ø57.5 body (STEP), so the seat in the lid
  is spot-faced flat and the retaining lip grips 2 mm of that disc.
- The unit sits with its centre 33.4 mm from the bottom end's centre: the lowest position that still
  clears the rounded bottom, which is what frees the upper half of the front face. Its top edge lands at
  62.15, so the Ø22 button's centre goes at **76.4** — above the unit's top edge and clear of the seat's
  rim at 59.9, while its land keeps 2 mm of material below the cavity's ceiling (ADR-018). The 0.25 mm
  between the switch's body, which ends at 61.9, and the unit's top edge is the tightest margin in the case.
- The microphones listen through the unit's own cover: eight Ø1 holes at r = 5.5 to 8.9 around its axis
  (STEP). Their air volume is the 1.80 mm gap behind the unit, and the case opens that gap to the
  outside through its **bottom**, close behind the unit: **two slots of 1.20 × 8.00 mm** (ADR-023), one
  each side at the microphones' own x of ±18.23 mm (`r = 26.83`, `47.2° / 132.8°` in the board's frame,
  which is z = 17.3 in the case), running from y = 46.30 to 54.30 along the depth. Each slot passes
  through the shell **and** the collar — 4.70 mm of material at that x, because the collar's bore is at
  10.44 and `mic_slot_top` is 13.00 — and its back end (54.30) reaches 0.80 mm into the gap the unit
  breathes: the unit's own back face is at 53.50. No spot face: the hydrophobic membrane (ADR-017) is
  an adhesive-backed patch and the bottom is a Ø66.8 cylinder, so a 9 mm patch follows that curve to
  within 0.31 mm with nothing to peel its edge. The Ø9 × 1 mm seat that ADR-022 carried as its land is
  out (ADR-023). The back plate carries nothing at all: it is the face that beds on the wall.
- The two halves meet at **y = 8.00**, 3 mm behind the crown's edge, as a **half-lap** (ADR-024): the lid
  carries a **lip** 1.50 mm thick -- the outer 1.50 mm of its 3.40 mm shell, **flush** with the case's own
  surface -- reaching 3.00 mm back into the base, and the base carries the **recess** over the same
  3.00 mm, which leaves it a **1.70 mm rim**. Lip and rim are 0.20 mm apart all round the contour, and
  `fitcheck_pair` proves it by boolean. Nothing protrudes: the outer surface runs straight across the joint
  (the 0.40 mm drip shadow the first cut had was dropped the same day), so a film of water running down the
  outside has the mouth of the 0.20 mm gap, the whole 3.00 mm of lap and the press of the two screws to
  beat before it reaches the gasket's shoulder. An 8.00 joint leaves the unit's seat (6.25), the grille
  field (3.00 to 6.25) and the button's lands (1.20, 4.47) all on the lid. The shell is 3.40 -- which is
  why the case is **66.80 x 96.80 x 58.40**, uniformly -- and the **front** wall is still 3.00.
- The front stays closed over the unit with the **Ø44 field of Ø2 holes**, 0.80 mm recessed behind the
  crown's apex to make a drip lip, centred on the unit's axis 33 mm from the bottom end. The speaker's own
  grille sits right behind it, so the path out is two grilles in series. The microphones do **not** share
  that field any more: one opening is sound going out, the other is sound coming in.
- Three pads on the back plate push the unit forward onto the seat; the gap behind it is 1.80 mm.

Case-side hardware adds its own fixed numbers: a **Ø22 mm cutout** for the panel button (ADR-018) with a
flat land behind it for the switch gasket, a **PG7 or M12 cable gland** for the **5 V** entry (the buck
now lives outside, so still two 0.75 mm² conductors, but at 5 V), a breathable membrane vent, and M4
wall/pole mounting holes. The button's head diameter and the depth of its body behind the panel are
measured on arrival and become parameters in the same file. Neither the gland nor the vent touches the back
plate: that face is what beds against the wall, so it carries nothing at all — the microphone ports are on
the bottom now (ADR-023). **The gland goes through the TOP** (2026-09-26, the user), on the unit's own axis
29.70 mm back from the crown: the unit's USB-C points **up** at its top edge, so a gland directly above it
is the shortest cable route and the only one that needs no bend inside the case. It sits on a raised
cylindrical boss, so that its gasket and its locknut both land on flat faces instead of on the case's
curved top (ADR-025). The vent stays on the bottom or on a side.

Inside the cavity there is now nothing to make room for: the unit fills it. The free space left is the
upper part, above the unit's top edge at 62.15, which is where the button's body and the cable route to the
unit's USB-C live. That route is now short and straight: the unit's USB-C is at its top edge pointing up,
and the gland is directly above it at the top of the case, on the same axis, so the pigtail leaves the
gland and drops into the port without a bend (ADR-025). The buck that used to sit on the back plate is out of the case, next to the
potted supply (ADR-016's single-stage option).
