# Installation at the gate

Everything here exists because the gate is outdoors: sun, rain, dust, insects and a WiFi link that is
already weak (-73 to -80 dBm measured with the board in the open).

## Enclosure rules

- **Plastic only.** A metal box turns a weak link into a dead one at 2.4 GHz. Printed parts are ASA
  (ADR-009); a molded ABS or PC junction box from a vendor is also fine.
- **Microphone:** a small port (3 mm) directly in front of the board's microphone holes, covered by a
  hydrophobic membrane or acoustic mesh. No slot, no open grille.
- **Speaker:** openings facing **down**, so water cannot pool in the cone or the chamber. Behind the
  grille, a fine mesh keeps insects out.
- **Cable entry:** a cable gland (PG7 or M12), not a hole. Water runs along a cable into an open hole.
- **Drainage:** if the design has a lower lip, leave a small weep hole, at the lowest point, outside the
  electronics cavity.
- **Servicing:** the lid opens with four screws, and the USB-C port stays reachable while it is closed.
  A device you cannot re-flash without dismounting it will not be re-flashed.

## Thermal

- The board's own dissipation is small, but a sealed box in the sun is an oven. Light colours and a
  shaded mounting position matter more than a vent.
- If the Li-ion cell stays inside (ADR-011), the cavity needs a breathable vent (a gore vent or a
  membrane-covered hole) so the cell does not sit in a pressurised hot box. A swelling cell is a
  removal item, not a warning item.

## Radio

- Mount the box so the board's ceramic antenna is not against metal, masonry or a metal gate post.
- If the link proves unreliable in the field, the next change is an external antenna on the board's
  IPEX1 connector (enabled by moving an onboard 0R resistor), with the pigtail leaving the box through a
  dedicated gland. Verify by measurement: the baseline is the signal level reported by the device.
- Keep the switch mode supply of any nearby equipment away from the antenna; 2.4 GHz hates noisy
  neighbours more than it hates distance.

## Wiring

- Speaker: GH1.25 2 pin into H3, wires kept short and away from the microphone ports.
- Power: USB-C into a properly strain-relieved cable, or the battery connector if a cell is installed.
  Never leave a USB cable as the mechanical anchor of the box.
- Gate bell: GPIO0 (BOOT) is wired as the bell button. If a physical button is exposed outdoors, wire
  it between GPIO0 and ground, with a series resistor and a pull-up, and a sealed button body.

## Before sealing anything

Check, in this order:

1. The device boots and joins WiFi with the lid closed (the box must not kill the link).
2. Microphone level measured through the sealed case, not on the bench: a membrane port that is too
   small muffles speech and no gain setting will fix it.
3. Speaker level and intelligibility at the gate, with the grille installed.
4. One full call from the phone, off-site, with the screen off and a deliberate network gap, confirming
   the call resumes instead of dropping.
5. Then seal it, and write the numbers back into `docs/`.
