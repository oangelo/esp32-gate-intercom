# CAD

Parametric OpenSCAD for the gate intercom enclosure. Two printed parts plus the hardware that goes
through their walls:

- **base** - the back tray: **closed**, because this face is mortared flat against the wall. It carries
  the three pads that push the unit forward onto the seat, and (step 3) the mounting ears.
- **lid** - the front shell: the **closed grille** over the unit's own grille, the spot-faced seat the
  unit's disc presses on, and the flat land and O22 cutout for the panel button.

## Files

| File | What it is |
|---|---|
| `case.scad` | The whole enclosure. One file, parameters at the top, `part` selects what to export |
| `media/` | Renders used for validation and for the documentation |

Status of `case.scad`: **revision 3, steps 1 and 2 done, re-cut around the assembled unit.** Roadmap
item 5 was decided the other way on 2026-09-24: the Waveshare goes in whole, as it arrives, so the lid
no longer builds its own speaker chamber — its front stays **closed** over the unit's grille and just
drills the sound holes (a O44 recessed field of O2 holes, the unit's own grille right behind them).
Those same holes are the microphones' air path: the unit listens through eight O1 holes in its own
cover, that air volume is the cavity, and the cavity's only way out is the grille. The base keeps three
pads that push the unit onto a spot-faced seat in the lid. Case depth went from 49 to 58 and the unit
sits low (centre at 33) to free the upper half for the button at 76.
`make fit` proves the unit clears both printed parts, and the probes (`probe_grille`, `probe_button`)
prove the openings are open through the walls, by boolean instead of by eye.

The lid-to-base joint is cut as of review 3: two M3 x 12 socket head screws (ISO 4762, stainless A2,
into brass inserts per ADR-017) pull the lid down onto two pillars that stand off the back plate, in
the corridor between the unit and the panel switch. Each screw's counterbore is cut from the crown's
own surface at the screw's x, and the lid's boss under it (`m3_lid_boss`) is what the head clamps --
the wall alone is 3.04 mm there and the counterbore is 3.20, so the wall on its own would leave the
head with nothing to pull against. `fitcheck_joint` answers the whole thing by boolean, and `-D
'fc="screw"'` / `-D 'fc="neighbours"'` splits it when the answer is not empty.

The collar that locates the unit is cut too, and it is where the case's own width shows: the cavity is
Ø60 inside and the unit is Ø58, so the ring has exactly **1.0 mm** to spend. It spends it — 1 mm of wall
on 0.2 mm of clearance, 5 mm tall, its outer 0.2 mm fused into the cavity's wall (ADR-020).
`-D 'fc="collar"'` isolates that check.

The two wall screws sit on the centre line at the quarter points of the height, z = 24 and z = 72
(ADR-021), so the pair is symmetric about the case's own centre and the hanging weight arrives at them as
shear. In X they were already on x = 0; only Z moved, from 7/59.

Everything that view draws is switchable, without editing the file: OpenSCAD's **Customizer** panel
(the `show_*` block at the top of `case.scad`) gives a tick box each for the lid, the base, the unit,
the screws, the collar and the M4, plus `show_solid` for the shell drawn opaque instead of as a
background object. All of them default to on, so an untouched file opens exactly as it always did.
Note that the shells are background (`%`) objects and `--render` does not draw those, which is why the
markers show up in the PNGs: in a PNG the shell appears only under `show_solid`.

Still to come: the gland and the membrane vent and the mounting ears (bottom or side, never the back),
the cable route to the unit's USB-C, and the rest of the joint (the gasket groove and the M4 pockets).

## Rules for this design

1. **No hardcoded dimensions.** Every number lives in the parameter block at the top, with a comment
   pointing at its source in `docs/dimensions.md`. If a measurement changes, one variable changes.
2. **ASA, not ABS and not PETG.** Outdoors, in the sun, on a gate post (ADR-009).
3. **Wall 3 mm minimum**, 3 perimeters at 0.4 mm. Nothing thinner than 1.2 mm anywhere except a gasket
   groove.
4. **No support material.** No overhang beyond 45 degrees and no bridge longer than 10 mm.
5. **Both parts print lying down**, with the case's depth as the printer's Z: the base on its back plate
   and the lid on its face. That is what makes the lid's grille holes print as vertical holes instead of
   a 44 mm ceiling to bridge, and it depends on the flat lands that step 2 spot-faces into the front
   face.
6. **Clearances are for FDM and for ASA shrinkage**: 0.2 mm for a tight fit, 0.3 mm for sliding,
   0.5 mm for loose. Heat-set inserts instead of printed threads. The board takes M2.5 inserts (its own
   mounting holes are 4.00 mm); the case joint and the ears take M3 and M4.

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

    make check     # compile the model and surface any warning or error
    make stl       # export build/case_base.stl and build/case_lid.stl
    make render    # PNG preview into cad/media/ (starts its own Xvfb display)
    make review    # the review view at three angles: screws, pillars, inserts, collar
    make section   # cutaway render, the review view: the assembled unit inside
    make inside_render  # translucent shell: the unit inside, and the rejected bare-parts layout
    make exploded  # the two printed parts pulled apart
    make fit       # prove the ghosts touch no wall and the openings are open; must be empty six times

`make check` must be clean before any export is taken seriously: OpenSCAD happily writes an STL with a
non-manifold object, and a sliced mesh with gaps is a failed print, not a cosmetic problem.

**Renders that show the inside of a shell must pass `--render`, and the shell must be a `%` object.**
Measured on this model: a white shell with `color(..., 0.15)` produced zero pixels of the internal
colours in the PNG, in preview and with `--render`, while the `%` (background) modifier with `--render`
kept all of them. `make inside_render` does both and prints the md5 of the two images, because two
views that must differ and come out byte-identical mean the render path ate the difference, not that
the selector is wrong.

## Validation, not eyeballing

`make fit` answers the interference question with a boolean, not with a picture: it intersects the wall
(the body minus the cavity) with each ghost volume, and an empty result means the part clears every wall.
A non-empty result comes with the ghost's name, and `-D 'fitwhich="speaker"'` narrows it to one part. That
is how the first real error in this file was found: the flat face of the speaker met the curved inner face
of the front, 0.2 mm of interference at the rim, invisible in a render.

Still to come in F2: `tools/check_case.py`, which loads the exported meshes with trimesh and asserts that
each is watertight and a single component, that the board volume fits inside the cavity with the intended
clearance, that no wall intersects the board, the speaker or the battery bay, and that the measured wall
thickness matches the parameter.
