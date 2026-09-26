# CAD

Parametric OpenSCAD for the gate intercom enclosure. Two printed parts plus the hardware that goes
through their walls:

- **base** - the back tray: **closed on the wall face**, which is the one face that carries nothing
  because it beds flat on the post, and opened through its **bottom**, where the two microphone slots
  are cut (ADR-023). It carries the three pads that push the unit forward onto the seat, and (step 3)
  the mounting ears.
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
Those same holes are the speaker's air path out, and the microphones have their own way in: **two thin
slots, 1.20 × 8.00 mm, through the BOTTOM of the base** close behind the unit, one each side at the
microphones' own x, each under a hydrophobic membrane stuck straight on the bottom's curve (ADR-023,
which moved them off the back plate — that face beds flat against the post — and dropped the Ø9 spot
face that was meant as the membrane's land). Keeping the two apart is the point — the microphones used
to share the speaker's field, which is direct coupling.
The base keeps three pads that push the unit onto a spot-faced seat in the lid. Case depth went from 49
to 58.70 — 58 when the unit went in, 58.4 when the shell grew to 3.4 mm, and the last 0.30 from the
caliper's height — and the unit sits low (centre at 33.4) to free the upper half for the button at 76.4.
`make fit` proves the unit clears both printed parts, that the two parts clear each other across the lap
(`fitcheck_pair`), and — through the probes (`probe_grille`, `probe_button`, `probe_mic`, `probe_gland`,
`probe_m4`, `probe_vent`) — that the openings are open through the walls, by boolean instead of by eye.

The lid-to-base joint is cut as of review 3: two M3 x 12 socket head screws (ISO 4762, stainless A2,
into brass inserts per ADR-017) pull the lid down onto two pillars that stand off the back plate, in
the corridor between the unit and the panel switch. Each screw's counterbore is cut from the crown's
own surface at the screw's x, and the lid's boss under it (`m3_lid_boss`) is what the head clamps --
the wall alone is 3.04 mm there and the counterbore is 3.20, so the wall on its own would leave the
head with nothing to pull against. `fitcheck_joint` answers the whole thing by boolean, and `-D
'fc="screw"'` / `-D 'fc="neighbours"'` splits it when the answer is not empty.

The joint itself is a **half-lap** as of this review (ADR-024): the lid carries a lip and the base the
recess it drops into, all the way round the contour, so the two halves can no longer be shifted sideways
against each other and no longer meet on a bare flat plane. The lip is the outer 1.50 mm of the lid's
3.40 mm shell, reached 3.00 mm back past the plane and **flush** with the case's surface; the recess takes
the outer 1.70 mm of the base's wall over the same 3.00 mm and leaves a 1.70 mm rim, so the two are
**0.20 mm apart** all round. Nothing protrudes any more: the first cut stood the lip 0.40 mm proud as a
**drip shadow**, the user's call was that the ridge reads badly ("fica feio"), and the case grew 0.8 mm
across instead -- its own surface is what a film of water runs down, and the mouth of the 0.20 mm gap is
the first line against it, ahead of the 3.00 mm of lap and the shoulder where the foam ring sits.
`fitcheck_pair` proves the lap by boolean -- the two parts against each other, minus one `eps` either side
of the joint plane, which is a contact and not an interference.
Neither part pays for the lap with support: through its last 3 mm the base's wall goes 3.40 to 1.70 mm and
the lid's 3.40 to 1.50, so both shapes only lose material as the print rises.

The collar that locates the unit is cut too, and it is where the case's own width shows: the cavity is
Ø60 inside and the unit calipers at Ø57.5, so the ring has **1.25 mm** to spend. It spends it — 1.25 mm of
wall on 0.2 mm of clearance, 5 mm tall, its outer 0.2 mm fused into the cavity's wall (ADR-020).
`-D 'fc="collar"'` isolates that check.

The two wall screws sit on the centre line at the quarter points of the height, z = 24.2 and z = 72.6
(ADR-021), so the pair is symmetric about the case's own centre and the hanging weight arrives at them as
shear. In X they were already on x = 0; only Z moved, from 7/59.

Everything that view draws is switchable, without editing the file: OpenSCAD's **Customizer** panel
(the `show_*` block at the top of `case.scad`) gives a tick box each for the lid, the base, the unit,
the screws, the collar and the M4, plus `show_solid` for the shell drawn opaque instead of as a
background object. All of them default to on, so an untouched file opens exactly as it always did.
Note that the shells are background (`%`) objects and `--render` does not draw those, which is why the
markers show up in the PNGs: in a PNG the shell appears only under `show_solid`.

Still to come: the mounting ears. Everything else on that list is cut as of 2026-09-26. The joint's gasket
is drawn as its own part — `part="gasket"` or `make gasket`: 1.70 mm wide, 1.00 mm of closed-cell silicone
foam squeezed to 0.70, flat on the shoulder the lap leaves, proved by `fitcheck_gasket` (ADR-024's "The ring
itself"). The vent is a Ø4.00 hole high on the -X side, a horizontal tunnel with a 4 mm bridge for a ceiling,
proved by `probe_vent`, with a breathable membrane stuck over it (ADR-026). The gland's top is cut (ADR-025):
a Ø22 x 3.00 boss with a 50 degree tail, a Ø12.50 hole whose first 1.20 mm stay round for the gasket's
washer and which then becomes a teardrop into the cavity, and a pad under the locknut. The pigtail
leaves the gland and drops straight into the unit's USB-C, which points up at the unit's top edge.
`probe_gland` is what proves that opening is one hole. The two wall screws are cut as well, since ADR-021
had them decided: a Ø8.00 x 1.50 pocket in the plate's inner face for the head and a Ø4.50 hole on through
the 3.40 of plate, which leaves 1.90 of it, proved by `probe_m4`.

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
    make fit       # prove the ghosts touch no wall and the openings are open; must be empty seven times

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
