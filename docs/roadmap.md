# Roadmap

Phases are small on purpose. Each one ends in an artifact that can be checked, not in a promise.

## F0 - Repository scaffold (done)

Deliverable: this repository, with the decisions, the dimension plan, the bill of materials and the
first parametric CAD file. Acceptance: `git clone` plus `make check` compiles the CAD without errors.

## F1 - Real dimensions

Deliverable: `docs/dimensions.md` filled in, from the vendor STEP/DXF (once the RAR5 archive can be
extracted) and from caliper measurements on the physical board and speaker.

Acceptance: the board outline, hole pattern, connector positions, speaker and battery are all numbers
with a stated source, and the STEP model (if extracted) agrees with the caliper within 0.5 mm. Where
they disagree, the caliper wins: the vendor file describes a reference board, the caliper describes
this one.

## F2 - Enclosure v1, printable

Deliverable: `cad/case.scad` producing three parts: base, lid with the speaker chamber, and a gasket
gasket groove. Design points from ADR-009 and ADR-010: ASA material, wall 3 mm, downward speaker
grille, microphone behind a hydrophobic membrane port, cable gland instead of an open hole, mounting
tabs for a wall or a pole, screw bosses sized for heat-set inserts.

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
