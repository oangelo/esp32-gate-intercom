# Roadmap

Phases are small on purpose. Each one ends in an artifact that can be checked, not in a promise.

## F0 - Repository scaffold (done)

Deliverable: this repository, with the decisions, the dimension plan, the bill of materials and the
first parametric CAD file. Acceptance: `git clone` plus `make check` compiles the CAD without errors.

## F1 - Real dimensions

Deliverable: `docs/dimensions.md` filled in, from the vendor STEP/DXF and from caliper measurements on the
physical board and speaker.

Status: the RAR5 archive was extracted with `unar`, the DXF was measured with `tools/dxf_probe.py`, and
the STEP was read headless with `freecadcmd` — it is the finished product assembled, so it returned the
position of every connector, the acoustic port of each microphone, the speaker, the cell and the mounting
hardware. `docs/dimensions.md` now carries the part-by-part table with the source of each number, and the
cross-check that the two vendor files agree. What is missing is the short list left at the end of that
file: the board outline under a caliper, the MEMS port face confirmed with a loupe, the three buttons and
the MX1.25 header (library codes in the STEP), the speaker cable, and the weight of the stack.

Acceptance: the board outline, hole pattern, connector positions, speaker and battery are all numbers
with a stated source, and the STEP model (if extracted) agrees with the caliper within 0.5 mm. Where
they disagree, the caliper wins: the vendor file describes a reference board, the caliper describes
this one.

## F2 - Enclosure v1, printable

Deliverable: `cad/case.scad` producing three parts: base, lid with the speaker chamber, and a gasket
groove. Design points from ADR-009, ADR-014, ADR-016, ADR-017 and ADR-018: ASA material, wall 3 mm,
speaker on the front face and microphones at the back and low, front profile a capsule (semicircle,
straight sides, semicircle) with the illuminated button above and the speaker grille below, a recessed
grille with a drip lip, microphone ports facing the floor behind hydrophobic membranes, cable gland and a
membrane vent instead of open holes, mounting tabs for a wall or a pole, screw bosses sized for heat-set
inserts. Power enters as 5 V: the mains supply stays outside the printed part.

Acceptance:

- `make stl` produces watertight meshes (checked with trimesh).
- The board volume fits inside the cavity with at least 1 mm clearance everywhere.
- No wall covers a connector that must stay reachable, checked geometrically, not by eye.
- Renders (assembled and exploded) are committed under `cad/media/`.

Status: **steps 1 to 3 done, and the joint.** `cad/case.scad` revision 2 has the capsule profile, the
crown on the front face, the cavity, the speaker chamber with a flat seat and four retaining claws, the
recessed grille field (49 tilted holes behind a drip lip), the button's two spot-faced lands with the O22
cutout, the two microphone slots (1.20 x 8.00 mm) through the bottom behind the unit, and the joint at
y = 8 as a half-lap -- the lid's lip into the base's recess, 0.20 mm apart, with the lid standing 0.40 mm
proud as a drip shadow (ADR-024) -- closed by two M3 x 12 into inserts on pillars off the back plate.
`make fit` proves the board, the speaker and the buck clear every wall and each other, that the two
printed parts clear each other across the lap, and -- with `probe_grille`, `probe_button` and `probe_mic`
-- that the openings are open through the wall, by boolean instead of by eye; `make section` and
`make inside_render` are the review views. Left: the gasket ring itself (it lies flat on the 1.30 mm
shoulder the lap leaves; no groove fits at that width), the microphone membranes' seats, the membrane vent
and the cable gland (base, bottom or side), then the mounting ears and the M4 pockets in the back plate.

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

## Where we stopped (2026-09-21)

The design conversation is recorded as ADR-014 through ADR-018. Decided: speaker on the front face and
microphones at the back and low, front profile a capsule with the illuminated button above and the
speaker grille below (ADR-018 supersedes the arrangement in ADR-015), mains conversion outside the
printed part, and the moisture strategy (vent, acoustic membranes, coating).

Geometry: closed from the vendor STEP, which turned out to be the whole product assembled and named.
`docs/dimensions.md` has the part-by-part table, including the two microphone acoustic ports, which open
on the component side of the board — so with the board lying flat at the bottom, components down, both
ports face the floor and the seven RGB LEDs face up.

Not decided yet, needed before F2 starts:

1. The panel button (ADR-018): head diameter and body depth behind the panel, measured when the part
   arrives. The tactile switches on the board stop being a constraint, since the gate bell is an
   external 22 mm switch wired to GPIO0.
2. The board outline under a caliper: the STEP bounding box (57.63 x 56.54) is smaller than the DXF's
   Ø58.00 circle, so something is not a pure circle. Where they disagree, the caliper wins.
3. Where the 220 V comes from at the gate, and whether a supply point already exists there. The supply
   chain itself is settled (ADR-016, parts in `hardware/bom.md`): a potted IP67 220 V to 12 V driver
   outside, a 12 V to 5 V 3 A buck inside the case, and 5 V to the board through a USB-C pigtail. The
   button LED is settled too: always on, off the same 5 V rail, nothing switched.
4. Capsule width and the height of the straight section. Width is no longer a free choice: the board is
   Ø58 and the walls are 3 mm, so 66 mm outer is the width that fits it with 1 mm of clearance a side,
   and going under that means the board does not fit. Depth is the real decision: about **66 mm** if the
   board lies flat (its Ø58 then sets the depth as well as the width), or about **52 mm** if the board
   stands parallel to the front face (the tallest part on the component side is 5.0 mm, on the solder side
   4.5 mm, and the button's body gets the free upper half). The concept render — convex
   front, flat back, slim D profile — only matches the second. Height still about 96 mm: 30 mm of straight
   side plus the two Ø66 semicircles, which holds a Ø46 grille field and the 22 mm button.
5. **DECIDED (2026-09-24): the unit goes in ASSEMBLED.** The Waveshare goes in as it arrives — one
   cylinder, Ø58, the black body with the speaker inside, the acrylic band and the cover, all screwed
   together, and its own acoustic chamber and microphone ducting come with it. The case is built
   around it: depth **58** (was 49), the unit's grille face 6.20 behind the crown at its rim sitting on
   a spot-faced seat in the lid, held axially by three pads on the back plate, and the unit sits **low**
   (centre at z = 33, the lowest the rounded bottom allows) because that is what frees the upper half
   for the 22 mm button: the unit's top edge is at 62, the button's centre at 76.
   This reverses the earlier "hollowed out" decision, which was taken to keep our own speaker chamber
   because the vendor's ducting could not be resolved from the STEP. It is resolved now: **the unit
   listens through its own cover** — the acrylic cover has eight Ø1 holes at r = 5.5 to 8.9 around its
   axis (measured in the STEP), and the microphones' ports open into the air volume those holes vent.
   That volume is now the 1.80 mm gap behind the unit, and the case opens it to the outside through its
   **bottom**, with **two thin slots (1.20 × 8.00 mm)** cut close behind the unit, one each side at the
   microphones' own x (ADR-023, which moved them off the back plate: that face beds flat on the post),
   each under a hydrophobic membrane. They deliberately do **not** use the front grille: that field is
   the speaker's own air path, and sharing it means the speaker fires straight into the microphones,
   which is the one geometry error ADR-014 exists to prevent. **F4 decides the level anyway**: if it
   comes back muffled, the ports grow before any geometry moves.
   The seat also turns into an acoustic part: the disc presses on it, and a 1 mm foam ring there is what
   stops the speaker's front radiation from leaking into the cavity the microphones breathe. That leak is
   the whole echo-coupling budget, so the ring is not optional in the build.
   Costs accepted: +9 mm of depth (58 against 49) and the buck moves **outside** the case — the potted
   supply feeds the unit's USB-C pigtail, which ADR-016 already had as its single-stage alternative.
   The gland and the vent can no longer live on the back plate either: they move to the bottom or to a
   side (step 3).
   `make fit` proves the unit clears both printed parts and that the front grille and the button cutout
   are both open.
   The height readings, for the record: the product page drawing says 43.70 + 5.10 = 48.80, the DXF
   says 46.90 to the body's bottom and 47.00 to the Ø52 disc's bottom, and the assembled product in the
   STEP is 49.70 including the rubber feet. The model uses **47.00** = 49.70 minus the 2.70 feet, which
   are peeled off because they stick out of the grille face and would land on the seat. If the real part
   is 48.80 rather than 47.00, the case has 1.80 mm less margin than it thinks: the caliper decides
   (`docs/dimensions.md`).
