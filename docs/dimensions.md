# Dimensions

The enclosure must fit the real board, so every number here comes from one of two authoritative
sources: the vendor's mechanical drawing, or a caliper on the actual board. Vision estimates and
product photos are not a source.

## Source files (not redistributed, see ADR-012)

| File | Where | Notes |
|---|---|---|
| Mechanical drawing archive | `https://files.waveshare.com/wiki/ESP32-S3-AUDIO-Board/ESP32-S3-AUDIO-Board.rar` (4215746 bytes) | Contains `ESP32-S3-AUDIO-Board.stp` (26.4 MB, 3D), `.dxf` (1.7 MB, 2D) and `.pdf` (44 KB, dimensioned) |
| Schematic v1.1 | `https://files.waveshare.com/wiki/ESP32-S3-AUDIO-Board/ESP32-S3-AUDIO-Board_1.1.pdf` | Already read: pinout, amplifier enable, battery path, camera and AEC nets |
| Product page | `https://www.waveshare.com/esp32-S3-audio-board.htm` | Confirms the DVP camera interface supports OV2640 / OV5640 |

The archive is RAR5 and the `7z` on the build host refuses it (`Unsupported Method`). It needs
`unar` (or an extraction on a machine with a full RAR5 implementation) before the STEP and DXF can be
measured programmatically. Until then, the numbers below are awaited from the caliper.

## Verified on the board (independent of the drawing)

| Item | Value | How it was checked |
|---|---|---|
| MCU | ESP32-S3R8, 16 MB flash, 8 MB octal PSRAM | `esptool` read |
| Microphone ADC | ES7210 at I2C 0x40 | live I2C scan |
| DAC | ES8311 at I2C 0x18 | live I2C scan |
| I/O expander | TCA9555 at I2C 0x20, amplifier enable on EXIO8 (P1_0) | live scan plus vendor demo code |
| RTC | PCF85063 at I2C 0x51 | live scan |
| I2C | SDA GPIO11, SCL GPIO10 | schematic and working config |
| I2S | MCLK GPIO12, BCLK GPIO13, LRCLK GPIO14, mic DIN GPIO15, speaker DOUT GPIO16 | schematic and working config |
| Buttons | BOOT on GPIO0 (used as the gate bell) | working config |
| Speaker connector | GH1.25 2 pin (H3) | schematic |
| Battery connector | MX1.25 2 pin, 3.7 V cell | schematic |
| Audio bus format | 16 kHz mono, 512-sample frames, 32 ms | working firmware |

## To be measured with a caliper (fill in, then the case stops being a guess)

Record every value in millimetres, with the board resting flat on a table.

| # | Measurement | Value | Notes |
|---|---|---|---|
| 1 | PCB length and width (maximum, over the widest part) | TODO | |
| 2 | PCB thickness | TODO | |
| 3 | Board mounting holes: count, diameter, spacing in X and Y, distance from each edge | TODO | If there are none, the case must clamp the board by its edges and nothing else |
| 4 | Tallest component above the PCB, and which part it is | TODO | Sets the internal cavity height above the board |
| 5 | Height of the tallest part below the PCB (if any) | TODO | Sets the standoff height |
| 6 | Pin header (2x8, 2.54 mm) position: which edge, distance to the two nearest edges | TODO | Decides whether the case leaves it exposed or hides it |
| 7 | USB-C connector: centre position from the two nearest edges | TODO | Either an opening for programming or a sealed wall |
| 8 | Acoustic ports of the two microphones: position relative to the edges and distance between them | TODO | The case needs its own membrane port in front of these |
| 9 | Speaker: outer diameter, total depth, mounting holes (spacing and diameter) or none, where the wires exit | TODO | Sets the acoustic chamber and the grille |
| 10 | Speaker cable length and connector orientation | TODO | Cable routing inside the case |
| 11 | Battery cell: length, width, thickness, cable length | TODO | Housing bay, only if the cell stays (see ADR-011) |
| 12 | Weight of the assembled stack (board + speaker + cell) | TODO | Sanity check for the wall/pole mount |

## Case parameters derived from the above

Once the table is filled, `cad/case.scad` takes them as parameters at the top of the file. Nothing in
the geometry is allowed to hold a hardcoded number: if a dimension changes, one variable changes and
the model follows. The `Makefile` renders and the checks in `tools/` verify that the board volume fits
inside the cavity with clearance and that no wall interferes with a connector.
