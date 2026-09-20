# CAD

Parametric OpenSCAD for the gate intercom enclosure: base, lid with the speaker chamber, gasket
groove, microphone membrane ports, cable gland and mounting tabs.

## Files

| File | What it is |
|---|---|
| `case.scad` | The whole enclosure. One file, parameters at the top, `part` selects what to export |
| `media/` | Renders used for validation and for the documentation |

## Rules for this design

1. **No hardcoded dimensions.** Every number lives in the parameter block at the top, with a comment
   pointing at the item in `docs/dimensions.md`. If a measurement changes, one variable changes.
2. **ASA, not ABS and not PETG.** Outdoors, in the sun, on a gate post (ADR-009).
3. **Wall 3 mm minimum**, 3 perimeters at 0.4 mm. Nothing thinner than 1.2 mm anywhere.
4. **No overhang beyond 45 degrees** and no bridge longer than 10 mm, so the part prints without
   supports. The speaker grille is a ring of holes in a downward-facing wall for exactly this reason.
5. **Clearances are for FDM and for ASA shrinkage**: 0.2 mm for a tight fit, 0.3 mm for sliding,
   0.5 mm for loose. Heat-set inserts instead of printed threads.

## Print settings that work for ASA

| Setting | Value |
|---|---|
| Nozzle temperature | 250 to 260 °C |
| Bed temperature | 100 to 110 °C |
| Chamber | enclosed, warm (passively heated by the bed is enough) |
| Part cooling | off, or a very low fan after layer 3 |
| First layer | brim, 10 mm, for warp control |
| Layer height | 0.2 mm |
| Perimeters | 3 |
| Infill | 25 percent, gyroid |

## Commands

    make check     # compile the model and show any warning or error
    make stl       # export build/case_base.stl and build/case_lid.stl
    make render    # PNG preview into cad/media/ (starts its own Xvfb display)

`make check` must be clean before any export is taken seriously: OpenSCAD happily writes an STL with a
non-manifold object, and a sliced mesh with gaps is a failed print, not a cosmetic problem.

## Validation, not eyeballing

`tools/check_case.py` (added in F2) loads the exported meshes with trimesh and asserts:

- every mesh is watertight and a single component,
- the board volume, as a box with the measured dimensions, fits inside the cavity with the intended
  clearance,
- no wall intersects the board volume, the speaker or the battery bay,
- the minimum wall thickness measured on the mesh matches the parameter.
