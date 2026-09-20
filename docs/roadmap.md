# Roadmap

Phases are small on purpose. Each one ends in an artifact that can be checked, not in a promise.

## F0 - Repository scaffold (done)

Deliverable: this repository, with the decisions, the dimension plan, the bill of materials and the
first parametric CAD file. Acceptance: `git clone` plus `make check` compiles the CAD without errors.

## F1 - Real dimensions

Deliverable: `docs/dimensions.md` filled in, from the vendor STEP/DXF and from caliper measurements on the
physical board and speaker.

Status: the RAR5 archive was extracted with `unar` and the DXF was measured with `tools/dxf_probe.py`, so
the board outline (round, 58.00 mm), the three-hole pattern and the speaker diameters already have a
stated source. What is missing is the caliper pass on the physical parts and the photographs of both faces
of the board.

Acceptance: the board outline, hole pattern, connector positions, speaker and battery are all numbers
with a stated source, and the STEP model (if extracted) agrees with the caliper within 0.5 mm. Where
they disagree, the caliper wins: the vendor file describes a reference board, the caliper describes
this one.

## F2 - Enclosure v1, printable

Deliverable: `cad/case.scad` producing three parts: base, lid with the speaker chamber, and a gasket
groove. Design points from ADR-009, ADR-014, ADR-015, ADR-016 and ADR-017: ASA material, wall 3 mm,
speaker on the front face and microphones at the back and low, front profile a capsule (semicircle,
straight sides, semicircle), rounded illuminated button in the middle, cable gland and a membrane vent
instead of open holes, mounting tabs for a wall or a pole, screw bosses sized for heat-set inserts.
Power enters as 5 V: the mains supply stays outside the printed part.

Acceptance:

- `make stl` produces watertight meshes (checked with trimesh).
- The board volume fits inside the cavity with at least 1 mm clearance everywhere.
- No wall covers a connector that must stay reachable, checked geometrically, not by eye.
- Renders (assembled and exploded) are committed under `cad/media/`.

## F3 - Firmware and Home Assistant side in the repository

Deliverable: the sanitized ESPHome configuration, the pinned third-party components with their
licenses and hashes, the Home Assistant component with our patches, the dashboard card and the
automations, plus the build history.

Acceptance: no credentials in any tracked file (checked by grep before every commit), and a documented
rollback path for each artifact.

## F4 - Installation at the gate, then v2

Deliverable: the enclosure installed and measured in the field: signal level at the gate, echo
behaviour outdoors, microphone level with the case sealed, and thermal behaviour in the sun.

Acceptance: a documented before/after with numbers, and the changes folded back into the CAD as v2.
External antenna on IPEX1 is evaluated here, not before: it is the highest-value change for link
reliability at -73 to -80 dBm.

## Where we stopped (2026-09-20)

The design conversation is recorded as ADR-014 through ADR-017. Decided: speaker on the front face and
microphones at the back and low, front profile a capsule with a round illuminated button in the middle,
mains conversion outside the printed part, and the moisture strategy (vent, acoustic membranes, coating).

Not decided yet, needed before F2 starts:

1. Photographs of both faces of the board, with a ruler in frame, and of the speaker.
2. Whether the microphone acoustic port is top-port or bottom-port; this decides which side of the case
   carries the microphone holes.
3. The caliper pass over `docs/dimensions.md`.
4. Where the 220 V comes from at the gate, and whether a supply point already exists there.
5. Button: 12 mm or 16 mm, and whether its LED is always on from 5 V or controlled by the firmware
   (free EXIO pins exist on the TCA9555; GPIO0 is already the doorbell input).
6. Capsule width and the height of the straight section. The current proposal is 66 mm wide, 30 mm of
   straight side, about 96 mm tall, which leaves room for a 46 to 48 mm speaker in the upper semicircle,
   the button in the middle, and the board lying flat at the bottom with the microphones facing the floor.
