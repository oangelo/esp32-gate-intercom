// ESP32 Gate Intercom - enclosure, revision 2
// Parametric case for a Waveshare ESP32-S3-AUDIO-Board. Printed in ASA (ADR-009).
//
// STATUS: revision 2 - the form, the fit and the openings are cut. This file has the capsule profile,
// the crown on the front face, the cavity, the joint at y = 8 with its half-lap (the lid's lip in the
// base's recess), the closed grille field over the unit, the button's lands and its cutout, the two
// microphone slots through the bottom, the two M3 x 12 that close the case, and the unit, speaker and
// buck as ghosts to prove they fit. Still to come, in this order, each one reviewed before the next:
//   1. the gasket itself: the foam ring is drawn now, flat on the 1.70 mm shoulder the lap leaves. No
//      groove -- at that width a groove would leave 0.35 mm of wall -- and the two screws squeeze the
//      ring from 1.00 to 0.70, which is what the joint closes by (ADR-024, ADR-017)
//   2. the microphone membranes' seats, the breathable vent and the cable gland (bottom or side)
//   3. mounting ears
// Every number below is measured or derived; the source of each is docs/dimensions.md.
//
// Frame: X = width, Y = depth (0 at the apex of the front face, CASE_D at the back plate),
// Z = height (0 at the floor). The case stands upright in use.
//
// PRINT ORIENTATION: both parts print lying down, with the case's Y as the printer's Z.
// The base prints on its back plate (cavity opening up, pillars vertical, microphone slots vertical)
// and the lid prints on its face (cavity opening up, so the grille's 49 holes come out as
// vertical holes instead of a 44 mm ceiling to bridge, and the lands that step 2 spot-faces into the
// crown give it its bed contact). The lap costs neither part a support, and with the lip flush there is
// no sideways step in either part: through its last 3 mm the base's wall goes from 3.40 to 1.70 mm and
// the lid's from 3.40 to 1.50, so both shapes only lose material as the print rises.
//
// One feature has its axis IN the bed, and it is the one that costs: the cable gland goes through the
// TOP, along the case's Z, which is the printer's Y. A boss and a hole lying in the bed plane would need
// support on one side (the print rises along -Y, so everything facing +Y hangs), so the boss carries a
// 45 degree tail on its back side and the hole a teardrop inside -- the same shapes the microphone slots
// get, for the same reason. Rule 4's one concession in the whole case is named where it is made, with
// the gland's parameters.
//
// Usage:
//   openscad -D 'part="base"'         -o build/case_base.stl  cad/case.scad
//   openscad -D 'part="lid"'          -o build/case_lid.stl   cad/case.scad
//   openscad -D 'part="assembly"'     -o cad/media/form.png   cad/case.scad   # opaque, outer form
//   openscad -D 'part="inside"'       -o cad/media/in.png     cad/case.scad   # translucent shell
//   openscad -D 'part="inside_parts"' ...                                     # rejected layout
//   openscad -D 'part="section"'      ...                                     # cutaway, review
//   openscad -D 'part="exploded"'     ...                                     # the two parts apart
//   openscad -D 'part="fitcheck"'     ...                                     # must be EMPTY
//   openscad -D 'part="fitcheck_pair"' ...                                    # must be EMPTY
//   openscad -D 'part="probe_grille"' ...                                     # must be EMPTY
//   openscad -D 'part="probe_button"' ...                                     # must be EMPTY
//   openscad -D 'part="probe_mic"'    ...                                     # must be EMPTY
//   openscad -D 'part="probe_gland"'  ...                                     # must be EMPTY
//   openscad -D 'part="probe_m4"'     ...                                     # must be EMPTY
//   openscad -D 'part="fitcheck_gasket"' ...                                   # must be EMPTY
//   openscad -D 'part="gasket"'       -o build/gasket.stl ...                 # the foam ring on its own
//
// Everything is selected through `part`, one selector for every view. The translucent views need
// --render: without it the PNG export draws the shell as opaque and the internals disappear, which
// makes two views that must differ come out byte-identical. Compare with md5 and with
// --summary all, never by looking at the picture.
//
// Convention: millimetres. Variable names are ASCII only (the parser breaks on accents).

// --------------------------------------------------------- measured (docs/dimensions.md)
board_dia    = 57.63;   // board is ROUND. The vendor DXF says 58.00, and the unit's own body calipers
                        // at 57.50 (2026-09-26), so the board sits a shade under both. Unused by any
                        // solid: the assembled unit is what goes in now
board_t      = 1.20;    // PCB thickness, vendor STEP (it is not 1.6)
board_hole_d = 4.00;    // three mounting holes, with a 4.80 ring (the vendor's M2.5 studs)
board_hole_r = 23.75;   // radius of the hole pattern from the board centre
board_hole_a = [36.1, -36.1, 180.0];   // hole angles, board frame, +Y pointing down in the case
comp_h_top   = 5.00;    // tallest part on the component side: the 2x9 header
comp_h_bot   = 4.50;    // tallest part on the solder side: the speaker header
mic_port_r   = 26.83;   // microphone acoustic port, from the board centre, component side
mic_port_a   = [47.2, 132.8];
spk_od       = 43.30;   // SPK-4020-5W, no screw holes of its own (used by the bare-parts ghosts,
spk_d        = 20.50;   // which document the hollowing-out option that was rejected)

// --------------------------------------------------------- case parameters
part    = "review";     // the one selector: review | inside | assembly | inside_parts | base | lid |
                        // gasket | section | exploded | screwplan | fitcheck | fitcheck_parts |
                        // fitcheck_internal | fitcheck_joint | fitcheck_pair | fitcheck_gasket |
                        // probe_grille | probe_button | probe_mic | probe_gland | probe_m4
                        // Default is `review`: the shell and the unit as ghosts, the planned screws whole.
                        // `assembly` is the same thing opaque, for the outer form.

// ------------------------------------------------------- what the review view draws
// The switches below belong to the `review` view (and its alias `screwplan2`) -- `part` chooses WHICH
// view, these choose WHAT it draws. They are annotated for the CUSTOMIZER: OpenSCAD's Customizer panel
// (or View > Customizer) shows them as tick boxes, and F5 redraws as you tick. An untouched file draws
// everything, exactly as before.
//
// Why they exist: the review view is the joint seen through the shell, and six solids at once is a lot
// to read. Un-tick what is in the way -- the unit to look at the pillar against the switch, the screws
// to look at the holes they will sit in, both shells to look at the marker set alone.
//
// One trap, measured: the shell is a % (background) object and `--render` does not draw those at all --
// that is exactly why the markers come out visible in the PNGs. So un-ticking the shells changes F5 (the
// preview you work in) and changes nothing in a `make review` PNG; in a PNG the shell only appears with
// `show_solid`, which draws it as an ordinary opaque object instead.
/* [The review view] */
show_lid      = true;   // [true,false]  the front shell, with its grille and the button
show_base     = true;   // [true,false]  the back tray, with the bosses and the pillars
show_solid    = false;  // [true,false]  the shell solid and opaque, instead of a % (background) object
show_unit     = true;   // [true,false]  the assembled Waveshare, as a ghost
show_screws   = true;   // [true,false]  the two M3, their pillars and the brass inserts
show_collar   = true;   // [true,false]  the unit's collar (now cut into the base; drawn green so it
                        //                reads under the shell)
show_m4       = true;   // [true,false]  the two M4 into the wall, as markers: the pockets and holes they
                        //                sit in are cut in the base (m4_pockets())
show_gland    = true;   // [true,false]  the PG7 gland on the top's boss, with its cable (a marker: the
                        //                hole and the boss are cut into the base, the gland is not)
show_gasket   = true;   // [true,false]  the joint's foam ring, on the shoulder the lap leaves (it is a
                        //                separate part: neither half carries it)

// DECIDED (2026-09-24): the Waveshare goes in ASSEMBLED, as one cylinder -- board, black body with
// the speaker inside, acrylic band and cover, all screwed together, and its own acoustic chamber and
// microphone ducting come with it. The case is built around that, which is what the depth above and
// the unit placement below are.
//
// The case is closed except for two kinds of opening, both deliberate: the front is solid over the unit
// with a recessed grille field drilled through it (the sound leaves through ours and then through the
// unit's), and the BOTTOM carries the two microphone ports, low and close behind the unit. Neither of
// the other two faces will do for the microphones: the front field is the speaker's own air path (the
// direct coupling ADR-014 exists to prevent) and the wall face is bedded flat on the gate post, so a
// port there breathes mortar, not air. The bottom is what is left, and it is what ADR-014 asked for all
// along ("on the back and low side, facing down where the geometry allows"). The two slots open into
// the 1.80 mm gap behind the unit, which is the volume the microphones breathe.
//
// Height, and why the model uses 47.30: CALIPER, 2026-09-26, on the real part, and the caliper is
// what decides wherever the vendor files disagree (docs/dimensions.md): the whole unit with its
// three rubber feet measures 50.00, the feet are 2.70 stuck on the grille face, and with the unit's
// grille face forward those feet would press against the front wall -- so they come off and the unit
// is 47.30. Diameter, same caliper: 57.50, half a millimetre under the O58 the vendor files claim.
// The vendor sources, for the record: the STEP measures 49.70 assembled (so it reads 0.30 short),
// the product page says 43.70 + 5.10 = 48.80, the DXF says 44.30 to the bottom of the body and
// 47.00 to the bottom of the O52 disc, and 37.60 is PCB top to body bottom. Everything below
// derives from the two calipered numbers, and the whole interior follows them.
unit_dia  = 57.50;
unit_h    = 47.30;      // 50.00 calipered with the feet on, minus their 2.70
unit_face_y = 6.20;     // its grille face: clears the inner crown at the unit's rim by 1.00 mm
unit_cy   = unit_face_y + unit_h / 2;   // 29.85: unit centre on the depth axis
unit_cz   = 33.40;      // = z_btm, the centre of the bottom end (33.4): the LOWEST it can sit and still
                        // clear the rounded bottom, and low is what frees the upper half for the panel
                        // button (ADR-018). Was 33.00 at a 3.0 mm wall: the skin grew 0.4 and the whole
                        // interior came with it, so the 1.25 mm gap around the unit is untouched

case_w  = 66.8;         // the cavity's O60 plus 2 x 3.4 of wall. Was 66.0 at a 3.0 wall: the case grew
                        // 0.8 across so the joint's lip could sit flush with its surface (ADR-024),
                        // which leaves the board 1.19 mm of clearance a side instead of 1.00
case_h  = 30.0 + case_w;   // 96.8: 30 mm of straight side + the two ends (ADR-015: capsule)
case_d  = 58.7;         // the unit's depth 47.30 (feet peeled off) + the front gap at its face (6.20)
                        // + the back gap (1.80) + the plate (3.40) = 58.70, so it follows unit_h one
                        // for one. Was 58.0, then 58.4 when the shell grew to 3.4. DECIDED: the
                        // assembled unit goes in whole. Was 49 when the plan was a bare board and our
                        // own chamber
wall    = 3.4;          // was 3.0. The extra 0.4 a side is what lets the lap's lip sit FLUSH with the
                        // case's own surface instead of standing 0.40 proud as a ridge on the outside
                        // (the user's call: "fica feio"). It also takes the base's rim at the lap from
                        // 1.30 to 1.70 mm. The cavity does not move: still O60, 1.25 mm around the
                        // O57.5 unit (ADR-020)
wall_front = 3.0;       // the FRONT wall stays 3.0, so the crown's inner surface, the grille field's
                        // depth and the unit's seat keep the geometry they were designed with. At 3.4
                        // the inner crown would recede to 6.50 at the unit's rim and the seat's own
                        // plane (6.25) would end up inside the wall -- which is exactly how the
                        // fitcheck caught this: 1.30 mm3 of the unit's ghost buried in the lid
r_end   = case_w / 2;   // 33.4: radius of both ends
z_btm   = r_end;                       // 33.4: centre of the bottom semicircle
z_top   = case_h - r_end;              // 63.4: centre of the top semicircle
crown_s = 5.0;                         // sagitta of the front crown (convex front, ADR-015)
crown_r = (pow(r_end, 2) + pow(crown_s, 2)) / (2 * crown_s);   // 114.06

// The joint is `joint_y` (8.0), defined with the lap further down, because that is where its three
// numbers come from. It used to be 27.5 here, as `split_y`: a flat contact, and neither the lip nor
// the screws of review 3 would work there.
inner_d = case_d - wall;               // 55.30: inner face of the back plate
cav_x   = r_end - wall;                // 30: inner radius; the ends share the outside centres
cav_y0  = wall_front;                  // 3.0: inner apex of the crown, at the front wall's thickness
crown_in = crown_r - wall_front;       // 111.06: its radius, so the front wall is 3.0 and not the shell's

// The three board standoffs (r = 23.75 at -36.1, +36.1, 180 degrees) leave exactly three gaps
// against the wall: around 0 degrees (+X side), 108 degrees (upper left) and 252 degrees (lower
// left). Every joint boss and every mounting ear has to live in one of those three gaps, because
// the board's 57.63 fills the rest of the back plate. Nothing else fits behind it.
//
// With the bottom end round, the cavity narrows fast below z = 33.4 (at z = 8 it is only +-16.0),
// so the board also has to sit high enough that its 57.63 clears the curve: at its centre height
// of 37.4 mm the clearance is 1 mm a side, and it is the sides, not the floor, that decide.

// The inner face of the front is the crown, so it recedes as it goes out: at the speaker's
// radius (21.65) it sits at y = 5.54 instead of 3.40. A flat speaker face has to clear that,
// which is why it starts at 5.65 and why step 1 spot-faces a flat seat into the crown.
spk_cy   = 15.90;       // speaker front face at 5.65, then half its depth (bare-parts ghost)
board_cy = 30.60;       // board front face at 30.00: 4 mm behind the speaker (bare-parts ghost)
board_cz = 37.40;       // board centre height (bare-parts ghost)
spk_cz   = 26.40;       // speaker centre height (bare-parts ghost)

eps = 0.01;
$fa = 2;
$fs = 0.4;

// --------------------------------------------------------- features: grille (lid, lower half)
// The unit brings its own grille behind the disc face, and the case's front is CLOSED over it: a
// recessed field of through holes, so the sound leaves through ours and then through the unit's. The
// microphones no longer share this field: they have their own two ports through the back plate (the
// microphone block further down), which is what stops the speaker from firing straight into them.
grille_od    = 44.0;    // the field, inside the unit's own O46 grille area
grille_rec   = 0.80;    // recess behind the crown's apex: makes the drip lip and a flat print face
grille_hole  = 2.0;     // hole diameter
grille_pitch = 4.5;     // hole pitch; the grid is clipped to a circle of 4 cells
grille_tilt  = 15.0;    // holes tilted so their outer end is lower and water runs out
// The unit is held axially by two things: this flat seat in the lid (the disc's face presses on it)
// and the pads on the back plate pushing it forward. With the front closed over the unit, nothing can
// come forward any more, so the seat's only job is to be flat and to stop the speaker leaking sideways.
unit_seat_d   = 53.0;   // seat diameter: the disc's O52 plus a shoulder
unit_pad_d    = 8.0;
unit_pad_r    = 23.0;   // clear of the vendor's O1 holes (r <= 8.9) and of the O57.5 edge
unit_pad_h    = 1.75;   // the gap behind the unit is 1.80: 0.05 mm of relief so the fit check still
                        // proves the unit clears. In the build a 1 mm foam pad goes here, which also
                        // seals the disc against the seat: that seal is what keeps the speaker out of
                        // the cavity the microphones breathe.

// --------------------------------------------------------- features: button (lid, upper half)
// A bought 22 mm panel switch (ADR-018) seals against a FLAT land, and the front face is convex:
// so the cutout gets a spot-faced land outside (for the switch gasket) and another inside (for the
// nut), which also keeps the wall between them a uniform 3.3 mm.
btn_cut     = 22.0;     // the switch's own cutout
btn_land    = 29.0;     // outer land diameter: gasket + enough to be flat. NOT 31: with the centre at
btn_land_in = 30.0;     // 76 the inner land tops out at 91 and the cavity's ceiling is at 93, so the
                        // wall above the hole keeps 2 mm of material instead of reaching zero
btn_land_y  = 1.20;     // outer land plane: 1.2 mm into the crown at its apex
btn_land_in_y = 4.50;   // inner land plane: uniform 3.3 mm of wall between the two
btn_cz      = 76.4;     // button centre. Constraints, all three: below the cavity's ceiling (93.4) with
                        // the land; above the unit's top edge at 62.15 and clear of the seat's rim at
                        // 59.9 by 1.5 mm; and the switch's body (O22, 30 deep) has to live between
                        // them -- it ends up at 61.9, so it clears the unit by 0.25 mm and the ceiling
                        // by a lot. That 0.25 is the tightest margin in the case: the caliper settled
                        // the unit's height at 47.30 (2026-09-26), and it is this margin that moves
                        // first if the real part ever measures longer.

// ------------------------------------------------------------------- helpers

module prism_xz(depth, y0 = 0) {
    // Extrude a 2D shape drawn in (x = width, y = height) along the case's Y (depth).
    translate([0, y0 + depth, 0]) rotate([90, 0, 0]) linear_extrude(height = depth) children();
}

module prism_xy(h, z0 = 0) {
    // Extrude a 2D shape drawn in (x = width, y = depth) along the case's Z (height). The gland's boss
    // is this kind of prism: its own axis is the case's Z, so its cross-section is the case's XY.
    translate([0, 0, z0]) linear_extrude(height = h) children();
}

module outline_outer() {
    // A capsule: semicircle at each end, two straight sides, 30 mm of straight between them.
    union() {
        translate([-r_end, z_btm]) square([case_w, z_top - z_btm]);
        translate([0, z_btm]) circle(r = r_end);
        translate([0, z_top]) circle(r = r_end);
    }
}

module outline_inner() {
    // Same shape, offset inwards by the wall: radius r_end - wall = cav_x (30), same end centres.
    outline_offset(wall);
}

module outline_offset(d) {
    // The capsule offset INWARDS by d -- d negative grows it OUTWARDS -- the ends' radius reduced by
    // d with the same end centres. outline_inner() is this at d = wall. The lap uses it twice: at
    // lap_step, for the lip's inner edge, and at -lap_proud, for the lip's outer surface.
    union() {
        translate([d - r_end, z_btm]) square([2 * (r_end - d), z_top - z_btm]);
        translate([0, z_btm]) circle(r = r_end - d);
        translate([0, z_top]) circle(r = r_end - d);
    }
}

module crown_outer() { translate([0, crown_r, -1]) cylinder(r = crown_r, h = case_h + 2); }
module crown_inner() { translate([0, crown_r, -1]) cylinder(r = crown_in, h = case_h + 2); }

module body() {
    intersection() {
        prism_xz(case_d) outline_outer();
        crown_outer();
    }
}

module cavity() {
    intersection() {
        prism_xz(inner_d - cav_y0, cav_y0) outline_inner();
        crown_inner();
    }
}

module keep_above(y0) { translate([-500, y0, -500]) cube([1000, 1000, 1000]); }
module keep_below(y0) { translate([-500, y0 - 1000, -500]) cube([1000, 1000, 1000]); }

module sector_xz(r_in, r_out, a0, a1, cz, y0, h, n = 24) {
    // A wedge of an annulus, drawn in the (x, z) plane around (0, cz) and extruded along Y.
    prism_xz(h, y0) translate([0, cz]) polygon(concat(
        [[r_in * cos(a0), r_in * sin(a0)]],
        [for (i = [0:n]) [r_out * cos(a0 + (a1 - a0) * i / n), r_out * sin(a0 + (a1 - a0) * i / n)]],
        [[r_in * cos(a1), r_in * sin(a1)]]));
}

// ------------------------------------------------- the unit's seat and the grille (lid)

module unit_seat_cut() {
    // Spot-faces the inner face of the front flat, so the unit's grille disc has a plane to sit on.
    // 0.05 mm behind the ghost's face: without it the two surfaces are coplanar and the boolean
    // intersection grows slivers instead of reporting a clean empty.
    translate([0, unit_face_y + 0.05, unit_cz]) rotate([-90, 0, 0])
        cylinder(d = unit_seat_d, h = 20);
}

module grille_hole_cut(d) {
    // Same axes for the cut and for the probe, only the diameter changes: 5x5 cells clipped to a
    // circle, tilted so the outer end is lower than the inner one (ADR-018: water runs out). 10 mm
    // of length, because in front of the seat the wall is up to 6.2 mm thick.
    for (ix = [-4:4], iz = [-4:4])
        if (ix * ix + iz * iz <= 16)
            translate([ix * grille_pitch, -1, unit_cz + iz * grille_pitch])
                rotate([-(90 - grille_tilt), 0, 0]) cylinder(d = d, h = 10);
}

module grille_cut() {
    // The field is a spot-face: it gives the drip lip around it and, when the lid prints lying on its
    // face, a flat area instead of one line of contact.
    translate([0, grille_rec - 25, unit_cz]) rotate([-90, 0, 0]) cylinder(d = grille_od, h = 25);
    grille_hole_cut(grille_hole);
}

module unit_pads() {
    // Three pads, 120 degrees apart, pushing the unit's cover forward onto the seat. They are the only
    // thing holding it now: the front is closed over the unit, so it can no longer come out forward.
    for (a = [0:120:240])
        translate([unit_pad_r * cos(a), inner_d - unit_pad_h, unit_cz + unit_pad_r * sin(a)])
            rotate([-90, 0, 0]) cylinder(d = unit_pad_d, h = unit_pad_h + eps);
}

// ---------------------------------------------------------- button land and cutout (lid)

module button_cut_hole(d) {
    translate([0, btn_land_y - 8, btn_cz]) rotate([-90, 0, 0])
        cylinder(d = d, h = 8 + (btn_land_in_y - btn_land_y) + 1);
}

module button_lands_cut() {
    // Two flat spot-faces: the switch gasket seals on the outer one, the nut clamps on the inner
    // one, and the wall between them is a uniform 3.3 mm.
    translate([0, btn_land_y - 25, btn_cz]) rotate([-90, 0, 0]) cylinder(d = btn_land, h = 25 + eps);
    translate([0, btn_land_in_y, btn_cz]) rotate([-90, 0, 0]) cylinder(d = btn_land_in, h = 25);
}

// ------------------------------------------------- PROPOSED: the joint and the screws (2026-09-25)
// Not cut yet: this block is the plan, and the render view `screwplan` draws it.
// CORRECTED (2026-09-25), on review: no boss on the back plate's outer face. The head seats on the
// plate's inner face, 3 mm off the wall, which is what "rente" means here. The plate is 3.4 mm now (it
// was 3.0), so a O8 counterbore 1.5 mm deep on the inner face plus a low or button head M4 (2.2 mm
// tall) is the combination that works: 1.9 mm of plate left, 0.7 mm of head in the 1.8 mm gap behind
// the unit. A countersunk M4 (2.35 mm) would leave 1.05 mm of plate -- 0.65 when the plate was 3.0 --
// which is still under rule 3's 1.2, so the counterbore stays the way to go. The numbers come
// from working the case's own clearances backwards, and one of them decides the whole layout.
//
// The joint moves to y = 8 (CUT 2026-09-26). At 27.5 it is 27.5 mm behind the front face: a screw
// through the front wall would need M3 x 30 and 17 mm of plastic to cross. At 8 the front part is a
// shallow cap, the screws are M3 x 12 -- the length the BOM already lists and the one the holes below
// are cut for -- and the unit is carried by the deep back part. Everything already modelled survives
// the move: the seat is at 6.25, the grille field spans 3.0 to 6.25, the button's lands sit at 1.2 and
// 4.5 -- all inside 8 -- and the switch's 30 mm body passes through into the back part's cavity, which
// is open air at (0, 76).
//
// The "lábio": a half-lap, in the form the user asked for, with the LID carrying the lip and the BASE
// the recess it drops into, all the way round the joint's contour. The first proposal here had it the
// other way round -- the base's skirt lapping over the lid's rim -- and that does not work at lap_d
// 3.0: the lap's forward end then lands exactly where the crown's own surface reaches the case's full
// 33 mm radius (x = 33 at y = 5.0), so the lid's shell there thins to a feather between the crown and
// the cut. Carrying the lip on the LID puts the whole lap BEHIND the joint plane, in the straight
// sided part of the case, and the crown is never involved.
//
// A true tongue and groove -- a ring standing out of one face into a groove in the other -- does not
// fit this case. The groove needs two walls, 1.2 + 1.4 + 1.2 = 3.8 mm, against the 3.4 mm shell (and the
// 0.4 that the shell did grow went OUTWARD, on the user's call, to make the lip flush -- see ADR-024), and the
// wall cannot be thickened inwards at the joint because the Ø57.5 unit is 1.25 mm from the cavity at that
// height (ADR-020). The half-lap SPENDS the wall instead of adding to it: 1.5 mm of lip and 1.7 mm of
// rim, 0.2 mm of radial clearance between them (rule 6's tight fit), both above rule 3's 1.2 mm.
//
// The lip sits FLUSH: lap_proud is 0.0, and it was 0.40, which stood the lip 0.40 mm proud of the case
// as a ridge on the outside. The user's call, 2026-09-26 ("fica feio"), and the price is paid by the
// wall: 3.0 to 3.4, so the case grew 0.8 mm across (66.8 x 96.8) and the lip's own outer surface IS the
// case's surface. Nothing protrudes and nothing steps -- the parting line is the only thing to see.
//
// What that gives up is the drip shadow the 0.40 was doing: water now runs straight across the parting
// line instead of falling off an overhang 1.90 mm outboard of the mouth of the gap. What is left to stop
// it is the mouth itself -- 0.20 mm, which water enters by capillary action -- and then the whole
// 3.00 mm of lap to climb and the shoulder at the joint plane, where the foam ring goes (ADR-017). If
// the film at the mouth ever shows up as a problem in use, a 0.40 mm deep rain groove on the parting
// line buys the break back without a ridge; it is not cut because it was not asked for.
//
// The shoulder is 1.70 mm now -- the wall is 3.4 and the recess spends 1.70 -- and still too narrow to
// groove: a 1.00 mm groove would leave 0.35 mm of wall on each side. So the ring lies flat on it and
// the two screws squeeze it. Drawn as of 2026-09-26 (gasket()): 1.70 mm wide, 1.00 mm of closed-cell
// silicone foam, squeezed 30 percent (ADR-017) -- so the joint's closed gap is 0.70, the lid ends up
// that far forward of the printed plane, and the lip reaches 2.30 into the recess instead of 3.00.
joint_y   = 8.0;        // CUT 2026-09-26: was 27.5, and the M3 x 12 screws already cut assume it
lap_d     = 3.0;        // how far the lip reaches back past the joint plane
lap_step  = 1.5;        // the lip's own thickness: the outer 1.5 mm of the lid's 3.4 mm wall
lap_gap   = 0.2;        // radial clearance: the base's rim keeps the inner 1.7 mm and the lip slides on
lap_proud = 0.0;        // FLUSH: the lip does not stand off the case's surface. Was 0.4 -- see above
gasket_y  = joint_y;    // the foam ring's shoulder, now the face at the joint plane itself: the lap
                        // moved the sealing face off the dome's brim and onto this 1.70 mm annulus
gasket_od = lap_step + lap_gap;   // 1.70: the ring's outer edge IS the rim's outer edge, so what
                                  // separates it from the lip is the lap's own 0.20 mm
gasket_id = wall;       // 3.40: and its inner edge is the case's inner surface
gasket_t  = 1.00;       // free thickness. Closed-cell silicone foam (ADR-017), cut to a ring or bought
gasket_squash = 30;     // percent of it the two screws take out (ADR-017: about 30 percent)
gasket_gap = gasket_t * (1 - gasket_squash / 100);   // 0.70: the joint's CLOSED gap, i.e. how far the
                        // lid ends up forward of the printed joint plane, with the ring squeezed in
                        // between. Nothing bottoms out for it: the 3.00 mm lip reaches 2.30 into the
                        // base's 3.00 mm recess once closed. That is the price of a flat ring -- and
                        // the reason there is no groove, which ADR-024 answers at 1.70 mm.

// The screws, and why they are NOT spread evenly around the loop:
//  - the ring is 3.4 mm thick (wall) and the case is 66.8 wide, so a screw head needs 6.3 mm: there is
//    nowhere in the ring for a countersink, at any angle;
//  - so a screw has to go through the lid's shell (3.4 mm thick, a 1.65 mm countersink leaves 1.75)
//    into material BEHIND it, and that material can only be a boss standing inward from the wall;
//  - a boss standing inward collides with the unit (O57.5 in a O60 cavity: a 1.25 mm annulus) everywhere
//    the unit is widest, which is the whole lower half. The unit's circle is what sets it: a boss
//    needs ~5 mm of width and the room for it only appears at z >= 47 and, cleanly, above z = 62.2;
//  - the back plate cannot take the joint's screws either: it is mortared against the wall.
// So six M3 in the upper two thirds, and the bottom of the loop holds on the mortar and the lap.
screw_m3 = [[27.5, 48], [-27.5, 48], [24, 66], [-24, 66], [13, 88], [-13, 88]];
screw_m3_d = 3.4;       // clearance hole through the lid, self-tapping pilot in the base's boss
screw_m3_sink = 1.65;   // countersunk head, flush with the dome (ISO 10642 / DIN 7991)

// The base to the wall. These go through the back plate from inside, so their heads must stay out
// of the unit's way: the gap behind the unit is 1.80 mm, so each head sits in a 1.5 mm pocket in
// the plate's inner face.
// WHERE (user's call, 2026-09-26): a quarter of the case's height up from the floor and a quarter
// down from the top, on the centre line. In X they were already there -- the old 26 mm radius at 90
// and 270 degrees lands on x = 0 too -- so only Z moved, from 7/59 to 24.2/72.6. Two things improve and
// one gets slightly worse. Better: the pair is now symmetric about the case's own centre (48.4), so
// the hanging weight reaches the screws as shear instead of loading one of them with a moment -- at
// 7 and 59 their centre sat at 33.4, below the mass. Better again: at 24.2 the screw is 9.2 mm off the
// unit's axis, so its head is nowhere near the collar's O60.4 (which is what retired the collar's
// M4 windows, ADR-020) while still landing in the 1.8 mm gap behind the unit, and at 72.6 it is clear
// ABOVE the unit (top edge 62.15) and below the switch's body (y = 31.2), so it is reachable with the
// unit already installed. Worse: 48.4 mm between them instead of 52, a little less leverage against
// tipping -- the price of the symmetry, and a small one.
m4_z = [case_h / 4, case_h - case_h / 4];   // 24.2 and 72.6: the quarter points
m4_x = 0.0;                                 // the centre line
screw_m4_d = 4.5;       // clearance for M4 (nylon plug in the masonry)
pocket_m4  = 1.50;      // REVIEW 2: 1.5 mm deep is what the corrected note says: 1.9 mm left

// ------------------------------------------------- REVIEW 3: socket head screws into brass inserts
// (2026-09-25, third review.) Two changes, both from the user's review of review 2, and together they
// replace the rib:
//   - the fastener is a SOCKET HEAD CAP SCREW (ISO 4762 / DIN 912), stainless A2 into a brass insert
//     (ADR-017), not the countersunk one. Its head is CYLINDRICAL, O5.5 x 3.0, so the lid gets a
//     cylindrical counterbore with the head down inside it: nothing stands proud of the case;
//   - the rib becomes a round PILLAR standing off the back plate, carrying the brass insert that the
//     screw bites. No self-tapping into a rib.
//
// Where the pair goes: the unit's circle (O57.5, centre (0, 33.4)) and the switch's body (O22, centre
// (0, 76)) leave a corridor on either side of the centre line. REVIEW 2 put the screw at (17, 68);
// with a O8.2 boss around it on the lid's inner face the gap to the switch's O30 nut flange drops to
// 0.09 mm, which is contact. The pair moves to (18, 67): 1.4 mm to that flange, 3.0 mm to the unit's
// collar, 8.9 mm to the cavity's side wall, and the pillar's own O8 clears the switch's body by
// 5.1 mm.
m3b        = [18.0, 67.0];
m3b_d      = 3.40;      // clearance hole for M3 through the lid's boss
m3b_head_d = 5.70;      // counterbore: the DIN 912 M3 head is O5.5 x 3.0, plus 0.05 a side
m3b_head_h = 3.20;      // counterbore depth: 3.0 of head and 0.2 of recess, so the head ends up
                        // INSIDE the crown. The wall is only 3.04 here, so the counterbore breaks
                        // through it on its own circle: the seat is the boss below, not the wall.
m3b_boss_d = 8.20;      // the lid's internal boss: 1.25 mm of wall around the counterbore (rule 3)
m3b_boss_h = 3.00;      // leaves 2.84 mm of material under the head, which is what the head clamps
m3b_shank  = 12.0;      // M3 x 12 socket head, the length the BOM already lists
// The pillar: it stands off the back plate (y = inner_d) to the joint plane, 47 mm long. The base
// prints lying on its back plate, so the case's Y is the printer's Z -- the pillar prints as a plain
// vertical column, with no support and no bridged hole.
m3b_pil_d  = 8.00;
m3b_pil_y  = joint_y;
m3b_ins_d  = 4.00;      // blind hole for the insert (BOM: M3 heat-set insert, 4.6 OD x 5 long)
m3b_ins_l  = 5.00;
m3b_ins_h  = 10.0;      // hole depth: 5.0 of insert plus 5.0 of relief for the M3 x 12's tip

// The three numbers the counterbore is built from, all read off the crown at the screw's own x. The
// front face is a cylinder, so its surface is a function of x alone and is the same at any z:
m3b_face_y   = crown_r - sqrt(pow(crown_r, 2) - pow(m3b[0], 2));          // 1.46, the crown itself
m3b_wallin_y = crown_r - sqrt(pow(crown_in, 2) - pow(m3b[0], 2));        // 4.47, its inner face
m3b_seat_y   = m3b_face_y + m3b_head_h;                                    // 4.66, the head's seat
// Worked end to end: the shank runs from m3b_seat_y to 16.66, the insert spans 8.00 to 13.00 (all
// 5 mm of it bitten) and the pillar's blind hole ends at 18.00, 1.34 mm clear of the tip.
//
// The collar on the floor (the "lábio"): it locates the unit's O57.5 body -- and as of review 3 it is
// CUT into the base, not a drawing. Both of its new numbers come from the cavity's own width: the
// inner radius is cav_x = 30.0 and the unit is O57.5 by the caliper, so the gap all the way round is
// 1.25 mm. A 2.3 mm wall (the old O63) had nowhere to go; the collar spends the whole gap instead:
// 1.25 mm of collar on 0.2 mm of clearance. 57.9 + 2 x 1.25 = 60.4 outside, so its outer 0.2 mm still
// sits INSIDE the cavity's wall and fuses with it. Deliberate, not sloppy: that fusion is what backs
// the ring, which on its own would be the thinnest unsupported thing in the case (rule 3: 1.2 mm).
lip_bore  = 57.9;       // the unit's own O57.5 plus 0.2 a side: rule 6's "tight fit"
lip_wall  = 1.25;       // the collar's thickness: the whole of the gap, see above
lip_od    = lip_bore + 2 * lip_wall;   // 60.4: unchanged, so it keeps fusing with the cavity's wall
lip_h     = 5.00;       // how far up it goes. 1.80 of that is the gap behind the unit, 3.20 is skirt
                        // over the unit's own body, and the skirt is the point: with 0.4 mm of total
                        // clearance the unit can cock by atan(0.4/3.2) = 7.1 degrees where 1.75 mm of
                        // collar let it cock by 12.9. It stays clear of the base/lid joint (now at 8.0).
m4_head_d = 8.0;        // the M4 head, seated in its pocket on the plate's inner face

// --------------------------------------------- features: microphone ports (base, step 3 of the list)
// The two ports, CUT through the BOTTOM of the base, close behind the unit. This is the third face they
// have been on and the first one that survives the mounting. They started on the front, sharing the
// speaker's grille field -- the direct acoustic coupling ADR-014 exists to prevent. ADR-022 moved them
// to the back plate, which is the one face this case cannot use: the plate is bedded flat on the gate
// post (ADR-010, ADR-021), so a port there breathes mortar, and ADR-022 left exactly that open.
// ADR-014 had the answer from the start: "on the back and low side, facing down where the geometry
// allows".
//
// SHAPE: a thin slot, and the printing rules decide that as much as the water does. The base prints
// lying on its back plate, so the case's depth is the printer's Z: a slot whose long axis runs along
// the depth prints as a VERTICAL slit, same cross section from the first layer to the last, with
// nothing to bridge and nothing to support under it. A round hole through the bottom, or a slot lying
// across the width, is a horizontal tunnel in the print whose ceiling is a BRIDGE over the opening --
// 8.00 mm for the slot here and over 40 for one laid across, which rule 4 forbids. Facing down and
// 1.20 wide, the slot also sheds rain and refuses insects, but the seal is the MEMBRANE, not the
// geometry: capillary pressure holds a film in a 1.20 mm slot against only 12 mm of water head, and the
// material is 4.7 mm thick. NO SEAT: the membrane is an adhesive-backed patch and the bottom is a Ø66.8
// cylinder, so a 9 mm patch follows that curve to within 0.31 mm and needs no flat land cut for it. A
// Ø9 x 1 mm spot face was here and is out (2026-09-26, on review); see the note under the parameters.
//
// WHERE: at the microphones' own x (r = 26.83 at 47.2 degrees in the board's frame -- ADR-018's
// measured numbers), one each side, running along the depth across the collar's band and into the gap
// behind the unit. Each slot's last 0.80 mm opens straight into that 1.80 mm gap (the slot ends at
// 54.30, the unit's back face is at 53.50); the rest opens into the 1.25 mm annulus between the unit
// and the cavity wall, which the collar's own 0.20 mm clearance connects to the same gap. The two slots
// are 19.2 mm2 of open area against the 6.3 mm2 of the eight Ø1 holes they feed, so the slots are not
// the restriction in the path (ADR-022's reasoning, unchanged), and both of them cut a 1.20 mm notch
// in the collar's ring, one each side of the bottom.
mic_slot_x   = mic_port_r * cos(mic_port_a[0]);   // 18.23: the microphones' own x, mirrored below
mic_slot_w   = 1.20;    // across the width. 1.20 and not 0.80: below 0.90 the two lines that form the
                        // slot's walls (0.45 each at a 0.4 nozzle) meet in the middle and it prints shut
mic_slot_l   = 8.00;    // along the depth -- the printer's Z, so it prints as a vertical slit
mic_slot_top = 13.0;    // how far the cut reaches up: past the collar's bore (10.44 at this x), so the
                        // slot is open through the wall AND the collar, not a pocket in either
mic_slot_cy  = 50.30;   // the slot's centre along the depth. The collar spans 50.30 to 55.30 and the
                        // unit's back face is at 53.50, so the slot crosses the collar's band (where
                        // its 0.20 mm clearance reaches the same gap) and its back end lands at 54.30,
                        // 0.80 mm inside the gap behind the unit
// DROPPED (2026-09-26, on review): the Ø9 x 1 mm spot face that ADR-022 had as the membrane's land.
// Two reasons. It bought nothing: the membrane is an adhesive-backed patch and the bottom is a Ø66.8
// cylinder, so a 9 mm patch conforms to that curve (0.31 mm of sag) with nothing to peel its edge --
// nothing slides past the bottom of a case on a post. And it went in WRONG on one side: the seat was a
// cylinder along the surface's own normal and mic_points() mirrors the slot on X without mirroring that
// rotation, so the left seat was cut 67 degrees off its normal and left almost no mark -- which is
// exactly how the review found it, a recess on one port and none on the other. What is cut now is a
// plain prism along the depth, which mirrors by construction.

// ------------------------------------------------------ features: cable gland (base, the top)
// The 5 V entry, and the cable route with it: a PG7 through the TOP of the case, on the unit's own axis
// (0, 29.85). That is exactly where the pigtail wants to be -- the unit's USB-C is on that axis at its
// top edge, pointing up (its centre in the vendor's frame is (0, -24.60), which in the case's own frame
// is z = 58.30, right at the top of the unit) -- so the cable leaves the gland and drops straight into
// the port, with no bend inside the cavity and nothing to tie it to. That is the whole argument for the
// top over the bottom: geometry, not looks (ADR-025).
//
// Two things make the top awkward, and both are answered here rather than worked around:
//
//  1. The top is the capsule's upper semicircle: a cylinder of radius r_end whose AXIS runs along the
//     case's depth, so it is straight in Y and curved in X (0.9 mm of sag over +-9 mm). Nothing flat
//     lands on it, so the gland gets a raised boss, and the face it stands on is turned square to the
//     case's Z.
//  2. Both parts print lying down, so the case's Z is the printer's Y and this whole feature lies IN the
//     bed plane, horizontally. Three consequences, all handled below: the boss's own back side faces
//     straight down (a 90 degree overhang) and gets a 45 degree tail; the hole's roof would be a
//     12.50 mm bridge (rule 4 allows 10) and gets a teardrop; and the locknut's seat inside, which has
//     to be a PAD raised on the cavity's curved ceiling rather than a spot-face cut into it -- there is
//     no material over the arch to cut -- gets the same teardrop for the same reason.
gland_cz      = case_h;                 // 96.80: the apex of the top's cylinder, where the boss stands
gland_cy      = unit_cy;                // 29.85: on the unit's axis, straight above the USB-C
gland_proud   = 3.00;                   // how far the boss's flat stands above that apex
gland_flat_z  = gland_cz + gland_proud; // 99.80: the face the gland's gasket lands on
gland_root_z  = 94.00;                  // where the boss's prism is buried. At z = 94 the case's own
                                        // surface is 12.93 mm wide in X, wider than the boss's 11, so
                                        // the base face hides inside the material: the sides simply
                                        // emerge from the shell and no ledge is left around them
gland_boss_d  = 22.00;                  // its diameter. A PG7's sealing washer is about O16, so this
                                        // leaves 3 mm of land -- and 2.16 mm of material between the
                                        // hole's own teardrop (which reaches 8.84) and the flat's edge,
                                        // above rule 3's 1.2
gland_boss_r  = gland_boss_d / 2;       // 11.00
gland_tail    = 50.0;                   // the tail's half-angle, off the case's Y on the +Y (back)
                                        // side. It is the print that sets it: the printer builds this
                                        // run with the case's Y as its vertical, the boss's back side
                                        // faces down, and 50 leaves the worst surface 40 degrees off
                                        // vertical against rule 4's 45
gland_tail_a  = 90 - gland_tail;        // 40: where the tail's two lines touch the circle, off +Y
gland_tail_y  = gland_cy + gland_boss_r * (cos(gland_tail_a) + sin(gland_tail_a) / tan(gland_tail));
                                        // 44.21: the tail's point, in the case's frame, 14.36 out from
                                        // the axis
gland_d       = 12.50;                  // the PG7's thread O.D.: the hole cut through boss and shell
gland_round   = 1.20;                   // how deep the hole stays ROUND from the flat inwards. The
                                        // gasket's ring seals on that face, and a teardrop opening
                                        // would reach O17.7 -- past the washer -- so the round collar
                                        // stays. It is the case's one deliberate concession to rule 4:
                                        // 12.50 mm of bridge over 1.2 mm of depth, against the rule's
                                        // 10. The alternative was a wider seal, not a leak
gland_tear    = 45.0;                   // from there in, the hole is a teardrop with its sides at this
                                        // angle to the hole's axis, tip pointing -Y (the print's up for
                                        // this run is the case's -Y, so the overhang is on that side)
gland_nut_d   = 17.00;                  // the locknut's seat inside: O17 across the flats
gland_nut_cut = 1.25;                   // how deep, and it is the ceiling's own curve that sets it: over
                                        // +-8.5 mm the O30 ceiling falls 1.23 mm, so this is within
                                        // 0.02 mm of flat for the whole seat. What is left above it
                                        // runs 2.15 mm at the rim to 3.4 at the centre, and through the
                                        // hole itself the material is 7.65 mm -- the boss's 3, the
                                        // shell's 3.4 and the ceiling's rise, which is what a PG7's
                                        // 6 mm of thread wants
gland_nut_z   = z_top + cav_x - gland_nut_cut;   // 92.15: the seat's plane

module screw_markers2() {
    // REVIEW 3, drawn only, nothing cut here: the two screws, their pillars and their inserts. All of
    // them are the SAME solids the fit check below bites into, so what you look at and what the boolean
    // tests cannot drift apart. The pillar goes translucent so the brass insert in its top reads
    // through it. The collar is NOT here: it has its own switch, since it is a marker too.
    color("blue", 0.35)  m3b_points() m3_pillar();
    color("gold", 0.95)  m3b_points() m3_insert();
    color("red", 0.95)   m3b_points() m3_screw();
}

fc = "all";             // narrows fitcheck_joint: all | screw | neighbours | collar

module fitcheck_joint() {
    // The review-3 joint, by boolean instead of by eye. Three questions, one volume, and `fc` narrows
    // it to one of them when the answer is not empty:
    //  1. "screw": the screw's OWN solid against both printed parts: the counterbore, the shank hole
    //     and the pillar's blind hole all have to swallow it, with the lid's boss in the way and with
    //     the insert sharing the hole it is pressed into;
    //  2. "neighbours": the pillar and the boss against the unit, the collar, and the switch's body
    //     behind the panel (its O30 flange is the same obstruction, being what button_lands_cut
    //     spot-faces away);
    //  3. "collar": the collar is cut material now, so its own clearance is a real question -- 0.2 mm
    //     all round the unit -- with the M4 heads along for the ride to keep them off it.
    if (fc == "all" || fc == "screw")
        intersection() {
            m3b_points() m3_screw();
            union() { base(); lid(); }
        }
    if (fc == "all" || fc == "neighbours")
        intersection() {
            union() { m3_pillars(); m3b_points() m3_boss(); }
            union() { ghost_unit(); unit_collar(); switch_body(); button_lands_cut(); }
        }
    if (fc == "all" || fc == "collar")
        intersection() {
            // The collar is no longer a drawing, so its clearance is a real question: 0.2 mm round the
            // unit, which is what lip_bore is for. The M4 heads ride along: they are at 24 and 72 now
            // (ADR-021), far from a ring that lives at r = 29.2-30.2, and including them is what keeps
            // them clear if either one moves. It bites the collar itself rather than base(), which the
            // collar is part of: against base() this check would meet by construction and say nothing.
            // (The pockets are cut now, ADR-021's amendment, so a head does seat in one.)
            unit_collar();
            union() { ghost_unit(); m4_heads(); }
        }
}

module screw_markers() {
    // The plan as bare rods along each screw's axis: review 2, two M3 (lid into the base's ribs) and two
    // M4 (base into the wall). Red = lid to base, blue = base to wall. They run the whole depth of the case
    // on purpose -- they are the axis, not the screw -- which is why review_view() draws the screws whole.
    for (s = [m3b, [-m3b[0], m3b[1]]])
        color("red", 0.9) translate([s[0], -3, s[1]]) rotate([-90, 0, 0])
            cylinder(d = screw_m3_d, h = case_d + 6);
    for (z = m4_z)
        color("blue", 0.9) translate([m4_x, -3, z])
            rotate([-90, 0, 0]) cylinder(d = screw_m4_d, h = case_d + 6);
}

// ------------------------------------- REVIEW 3: the joint, CUT (2026-09-25, third review)
// Everything above this point stayed a drawing. These are the cuts and the added material.

module m3b_points() {
    // The pair, mirrored on X. Every feature of the two screws is at both of these.
    for (s = [m3b, [-m3b[0], m3b[1]]]) translate([s[0], 0, s[1]]) children();
}

module m3_boss() {
    // The O8.2 seat boss as a solid: an added volume on the lid's inner face, growing inward from the
    // crown's own inner surface (m3b_wallin_y = 4.50), so it spans 4.50 to 7.50.
    translate([0, m3b_wallin_y, 0]) rotate([-90, 0, 0]) cylinder(d = m3b_boss_d, h = m3b_boss_h);
}

module m3_lid_boss() {
    // The seat for the head, added to the lid. The wall is 3.04 here and the counterbore is 3.20, so
    // the counterbore takes that wall away on its own circle: without this boss there would be
    // nothing under the head for it to clamp, and the two parts would not be held together at all.
    // O8.2 leaves 1.25 mm of wall around the counterbore. It grows INWARD, so the lid still prints
    // lying on its face with no support under it.
    m3b_points() m3_boss();
}

module m3_lid_cuts() {
    // The counterbore and the shank hole, cut from outside in. Both are measured from the crown's own
    // surface at x = m3b[0] (m3b_face_y), not from a plane, because the front is a cylinder: at any
    // other x the surface is somewhere else, so a "3.2 mm deep" pocket cut from y = 0 would come out
    // shallower at one edge of its O5.7 and the head would sit tipped.
    m3b_points() {
        translate([0, m3b_face_y - 1, 0]) rotate([-90, 0, 0])
            cylinder(d = m3b_head_d, h = m3b_head_h + 1 + eps);   // floor at m3b_seat_y
        translate([0, m3b_seat_y - eps, 0]) rotate([-90, 0, 0])
            cylinder(d = m3b_d, h = m3b_boss_h + 2);              // through the boss
    }
}

module m3_pillar() {
    // The pillar as a solid: off the back plate (5 mm of plate behind it) to the joint plane, i.e. it
    // spans m3b_pil_y to inner_d. The base prints on that back plate, so this is a vertical column: no
    // support, and its blind hole prints as a vertical hole, not a ceiling to bridge.
    translate([0, m3b_pil_y, 0]) rotate([-90, 0, 0])
        cylinder(d = m3b_pil_d, h = inner_d - m3b_pil_y);
}

module m3_pillars() { m3b_points() m3_pillar(); }

module m3_pillar_holes() {
    // The blind hole for the brass insert: O4.0 x 10. The 5 mm insert ends flush with the pillar's
    // face and the M3 x 12's tip still has 5 mm of relief under it, so the screw cannot bottom out
    // on plastic before it clamps.
    m3b_points() translate([0, m3b_pil_y - eps, 0]) rotate([-90, 0, 0])
        cylinder(d = m3b_ins_d, h = m3b_ins_h);
}

module m4_pockets() {
    // The wall screws' holes and pockets, cut from the plate's INNER face (y = inner_d = 55.30): a
    // O4.50 clearance hole on through the plate -- and on into the masonry behind it, when it is
    // drilled -- with a O8.00 pocket 1.50 deep for the head. The pocket is what keeps the head out of
    // the unit's way: the gap behind the unit is 1.80 mm and the head stands 2.20 (ADR-021), so it
    // seats in the plate and only its top 0.70 reaches the gap. The plate is 3.40 there, so the pocket
    // leaves 1.90 (rule 3). Unlike the locknut of the gland, this pocket faces a FLAT surface -- the
    // back plate's inner face -- so it is a plain counterbore, not a teardrop: both its axis and its
    // floor lie in the bed plane, and nothing about it overhangs.
    m4_points() {
        translate([0, inner_d - eps, 0]) rotate([-90, 0, 0])
            cylinder(d = m4_head_d, h = pocket_m4 + eps);
        translate([0, inner_d - eps, 0]) rotate([-90, 0, 0])
            cylinder(d = screw_m4_d, h = wall + 2 * eps);
    }
}

module m3_insert() {
    // The brass insert as a solid: M3 heat-set, 4.6 OD x 5 long (BOM). Drawn where it ENDS UP in use,
    // i.e. flush with the pillar's face, not sticking out as it does before it goes in.
    rotate([-90, 0, 0]) cylinder(d = 4.60, h = m3b_ins_l);
}

module m3_screw() {
    // The screw as a solid, end to end: DIN 912 M3 x 12, its cylindrical head down in the counterbore
    // so nothing stands proud of the crown.
    translate([0, m3b_seat_y - 3.00, 0]) rotate([-90, 0, 0]) cylinder(d = 5.50, h = 3.00);
    translate([0, m3b_seat_y - eps, 0]) rotate([-90, 0, 0]) cylinder(d = 3.00, h = m3b_shank);
}

module switch_body() {
    // What the bought 22 mm switch puts BEHIND the panel: O22, 30 mm deep from the panel face
    // (ADR-018). Nothing is cut with this -- it is a neighbour, to check the pillar and the boss.
    translate([0, btn_land_y, btn_cz]) rotate([-90, 0, 0]) cylinder(d = btn_cut, h = 30);
}

module unit_collar() {
    // The collar, now CUT into the base (review 3, second pass). A ring of rim on the floor, not a
    // raised floor: outline_inner() would have made it a slab with a hole in it (60 x 60, minus the
    // bore), a 5 mm step across the whole floor. Just the annulus -- the unit drops into lip_bore and
    // the pads carry it forward onto the seat.
    // A plain ring, with no windows in it. It had two (a O9 on each M4 axis) while the wall screws
    // sat on the 26 mm radius around the unit's axis: an O8 head reaches r = 30, past lip_bore's 29.2,
    // so the ring would have stood on the screw heads. The screws are at 24 and 72 as of ADR-021, and
    // 24 is 9 mm off that axis -- far inside the bore -- so there is nothing left to clear. The two
    // microphone slots do cut it now, a 1.20 mm notch each side of the bottom: they go through the wall
    // and the collar to reach the gap behind the unit, which is why mic_slot_top is above the bore.
    translate([0, inner_d - lip_h, unit_cz]) rotate([-90, 0, 0])
        difference() {
            cylinder(d = lip_od, h = lip_h + eps, $fn = 128);
            translate([0, 0, -1]) cylinder(d = lip_bore, h = lip_h + 2, $fn = 128);
        }
}

// ----------------------------------------------------- the microphone ports (base, step 3)

module mic_points() {
    // Where the two slots are: at the microphones' own x, mirrored on X. Children land on one slot's
    // own axis, in the case's frame, y = 0 being the case's depth origin (the apex of the front face).
    for (s = [mic_slot_x, -mic_slot_x]) translate([s, 0, 0]) children();
}

module mic_slot_cut() {
    // One prism each, cut up through the wall and through the collar that sits on it. It runs from 1 mm
    // below the bottom surface (so the cut breaks out clean whatever the wall's own thickness is) up to
    // mic_slot_top, which is above the collar's bore at this x: the slot is a through opening, not a
    // pocket. Along the depth it spans 46.30 to 54.30, 0.80 mm of that inside the gap behind the unit.
    // A prism and nothing else: the Ø9 seat that used to sit on it is gone (see the note above the
    // parameters), so this cut mirrors on X by construction, which the seat's rotated cylinder did not.
    mic_points() translate([-mic_slot_w / 2, mic_slot_cy - mic_slot_l / 2, -1])
        cube([mic_slot_w, mic_slot_l, mic_slot_top + 1]);
}

module mic_probe() {
    // A rod through the intended opening, narrower and shorter than the cut and long enough to emerge
    // inside the cavity: if its intersection with the base is empty, the slot is open end to end and
    // not a pocket through either the wall or the collar.
    mic_points() translate([-(mic_slot_w - 0.6) / 2, mic_slot_cy - (mic_slot_l - 2) / 2, -1])
        cube([mic_slot_w - 0.6, mic_slot_l - 2, mic_slot_top - 2]);
}

// --------------------------------------------------------------- the gland (base, top), CUT
// The shapes here are the print's, not the drawing's. A teardrop is a circle with the side that would
// hang replaced by two lines tangent at `tip` degrees; `tip` is 45 because that is rule 4's own limit,
// and a shallower tip (a longer tail) would put the tail's own sides past 45 degrees off vertical.
// Which side hangs is always the +Y one: the parts print with the case's Y as the printer's Z and the
// print rises along -Y, so every surface that faces +Y -- and nothing else -- needs help.

module teardrop_xy(r, tip = 45, n = 48) {
    // A circle of radius r about the origin with a point on the -Y side: the tangent lines leave the
    // circle at ±tip off -Y and meet at r / cos(tip) = 1.414 r. Mirror([0,1,0]) puts the point on +Y.
    polygon(concat(
        [[0, -r / cos(tip)]],
        [for (i = [0:n]) let (a = tip - 90 + (360 - 2 * tip) * i / n) [r * cos(a), r * sin(a)]]));
}

module gland_boss_profile() {
    // The boss's cross-section: the O22 circle plus its tail, a triangle whose two lower vertices are
    // exactly where the tail's lines touch the circle. Those lines are tangent by construction
    // (gland_tail_a = 90 - gland_tail), so the union has no corner at the join.
    union() {
        circle(r = gland_boss_r);
        polygon([[gland_boss_r * sin(gland_tail_a), gland_boss_r * cos(gland_tail_a)],
                 [0, gland_boss_r * (cos(gland_tail_a) + sin(gland_tail_a) / tan(gland_tail))],
                 [-gland_boss_r * sin(gland_tail_a), gland_boss_r * cos(gland_tail_a)]]);
    }
}

module gland_boss() {
    // The boss itself: that profile extruded from inside the shell up to the gland's flat. Its base is
    // buried at gland_root_z, so its sides emerge from the case's own surface and no ledge is left.
    translate([0, gland_cy, 0]) prism_xy(gland_flat_z - gland_root_z, gland_root_z) gland_boss_profile();
}

module gland_hole_cut(d = gland_d, round_h = gland_round, tear = gland_tear) {
    // The gland's hole in two steps: a plain round collar for the first round_h down from the flat --
    // the gasket's ring seals on that face, and a teardrop opening would reach O17.7, past the washer --
    // and a teardrop from there into the cavity, which is what keeps the roof printable. Cut as one
    // difference, so between them they are the hole.
    translate([0, gland_cy, gland_flat_z + 1]) cylinder(d = d, h = round_h + 1);
    translate([0, gland_cy, gland_nut_z - 2])
        prism_xy(gland_flat_z - round_h - gland_nut_z + 2) teardrop_xy(d / 2, tear);
}

module gland_nut_pad() {
    // The locknut's seat, and it has to be ADDED, not cut: the cavity's ceiling is a O30 cylinder
    // arching up over the hole (93.40 at the centre, 92.17 over the seat's rim), so there is nothing to
    // spot-face -- a flat face there means material, a pad that fills the arch and stops at 92.15. It is
    // a teardrop with its point on +Y, for the same reason the boss has its tail there: this pad's own
    // back side would hang. What the nut sees is a seat 2.25 mm wide round the hole, on a pad 1.25 mm
    // thick at its centre, and 7.65 mm of material through the hole.
    translate([0, gland_cy, gland_nut_z]) prism_xy(2.00) mirror([0, 1, 0])
        teardrop_xy(gland_nut_d / 2, gland_tear);
}

module gland_probe() {
    // A rod through the intended opening, 1 mm narrower than the cut and 0.5 mm narrower than its
    // teardrop, from above the flat to below the nut's seat: if its intersection with the base is
    // empty, the hole is open end to end -- flat, boss, shell, ceiling and seat -- and no face of the
    // seat swallowed it. It is two pieces with 0.2 mm of clearance either side of where the cut's own
    // round collar ends, so nothing rides on a coplanar face.
    translate([0, gland_cy, gland_flat_z + 1]) cylinder(d = gland_d - 1, h = gland_round + 1.2);
    translate([0, gland_cy, gland_nut_z - 0.5])
        prism_xy(gland_flat_z - gland_round - 0.2 - gland_nut_z + 0.5)
            teardrop_xy(gland_d / 2 - 0.5, gland_tear);
}

module m4_probe() {
    // The wall screws' way through, as a rod 1 mm narrower than the hole: it starts in the cavity, in
    // the air 3.5 mm clear of the pocket's mouth, crosses the pocket's floor and the plate, and ends
    // outside the case. Empty against the base means both cuts are there and line up.
    m4_points() translate([0, inner_d - pocket_m4 - 2, 0]) rotate([-90, 0, 0])
        cylinder(d = screw_m4_d - 1, h = pocket_m4 + wall + 4);
}

module gland_marker() {
    // The bought PG7 and its cable, as markers: what the printed parts have to accept, drawn where it
    // will sit. The thread passes through the hole, the flange's washer lands on the flat, the locknut
    // comes up inside onto the pad's seat, and the cable leaves straight up.
    color("orange", 0.85) {
        translate([0, gland_cy, gland_flat_z]) cylinder(d = 16.0, h = 3.50);         // the body's flange
        translate([0, gland_cy, gland_flat_z]) cylinder(d = 12.0, h = 9.00);         // its thread, outside
        translate([0, gland_cy, gland_flat_z + 9.00]) cylinder(d = 5.00, h = 26.0);  // the cable
    }
    color("gold", 0.85) translate([0, gland_cy, gland_nut_z]) cylinder(d = gland_nut_d, h = 2.40);
}



module joint_lip() {
    // The LID's lip: the lap band as an added ring, its outer surface the case's own (lap_proud is 0.0,
    // so nothing stands proud and nothing steps), its inner surface lap_step in, which makes the ring
    // 1.50 mm thick. Clipped by crown_outer() only as a guard: the crown reaches the case's full radius
    // at y = 5.0 and the whole band is behind that, so the clip never bites unless joint_y is ever moved
    // forward of 5.0.
    intersection() {
        prism_xz(lap_d + eps, joint_y - eps)
            difference() { outline_offset(-lap_proud); outline_offset(lap_step); }
        crown_outer();
    }
}

module joint_recess_cut() {
    // The BASE's side of the lap: the outer lap_step + lap_gap of its wall over the same band. What is
    // left is a 1.70 mm rim that the lip slides over with 0.20 mm of clearance all the way round. A 2D
    // difference extruded in the band, cut from the base: the recess is exactly the material that has
    // to go, and nothing else in the band is touched (the pillars are 11 mm inboard of it, the collar
    // is 39 mm further back).
    difference() {
        intersection() { body(); prism_xz(lap_d + 2 * eps, joint_y - eps) outline_outer(); }
        prism_xz(case_d, 0) outline_offset(lap_step + lap_gap);
    }
}

module gasket(t = gasket_t, inset = 0) {
    // The foam ring itself (ADR-017), drawn where it seals: flat on the shoulder the lap leaves -- the
    // base's 1.70 mm rim at the joint plane -- with the two screws squeezing it from 1.00 to the 0.70
    // the joint closes by. It is a SEPARATE part and belongs to neither half: it is cut from a sheet or
    // bought as a ring, which is why nothing here is unioned into base() or lid(), and why its own
    // printability is not a question. Its outer edge is the rim's own outer edge and its inner edge the
    // case's inner surface, so it is 1.70 mm wide and clears the lip by exactly the lap's 0.20 mm.
    //   t     -- thickness, from the rim's face forward (the default is the free one; the fit check
    //            asks for the squeezed 0.70, because that is the gap it has to fit in);
    //   inset -- a hair smaller in both directions, for checks whose surfaces would otherwise be
    //            coplanar with the metal they sit on. CGAL returns a zero-thickness sheet for those,
    //            and a sheet is not nothing.
    prism_xz(t, gasket_y - t)
        difference() { outline_offset(gasket_od + inset); outline_offset(gasket_id + inset); }
}

// ------------------------------------------------------------------- the two parts

module base() {
    // Back tray: closed on the wall face -- the one face that cannot carry anything, because the case
    // is bedded flat on the post -- and opened instead through its BOTTOM, where the two microphone
    // slots pierce the wall just behind the unit (step 3 of the feature list), and through its TOP,
    // where the cable gland does (ADR-025). What it carries is the three pads that push the unit forward
    // onto the seat, the two pillars the lid screws into, the collar that locates the unit, the recess
    // the lid's lip drops into (the lap), the boss the gland sits on and the pad its locknut bears on.
    // The vent still lives here in name only: it goes on the bottom or on a side.
    difference() {
        union() {
            difference() {
                intersection() { body(); keep_above(joint_y); }
                cavity();
            }
            m3_pillars();
            unit_collar();
            gland_boss();
            gland_nut_pad();
        }
        m3_pillar_holes();
        mic_slot_cut();
        gland_hole_cut();
        m4_pockets();
        joint_recess_cut();
    }
    unit_pads();
}

module lid() {
    // Front shell: the closed grille field over the unit's own grille, the button, the two
    // counterbored holes whose screws pull it down onto the base's pillars, and the lip -- the outer
    // lap_step of its shell carried lap_d back past the joint plane, flush with the case's own
    // surface. The unit's seat and the grille are both at 6.25 or in front of it, so an 8.0 joint
    // leaves every feature of the front on the lid.
    difference() {
        union() {
            difference() {
                intersection() { body(); keep_below(joint_y); }
                cavity();
            }
            m3_lid_boss();
            joint_lip();
        }
        unit_seat_cut();
        grille_cut();
        button_cut_hole(btn_cut);
        button_lands_cut();
        m3_lid_cuts();
    }
}

// ------------------------------------------------------------------- ghosts (review only)

module ghost_board() {
    // Board standing up, its own +Y (microphones, 2x9 header) pointing down: the microphones
    // end up low and the components face the back plate (ADR-014).
    translate([0, board_cy, board_cz]) rotate([-90, 0, 0])
        cylinder(d = board_dia, h = board_t, center = true);
}

module ghost_speaker() {
    translate([0, spk_cy, spk_cz]) rotate([-90, 0, 0])
        cylinder(d = spk_od, h = spk_d, center = true);
}

module ghost_unit() {
    // The assembled Waveshare, one cylinder in two steps: the grille disc (O52) sits 2.90 mm proud of
    // the body's face, measured in the vendor STEP, and the body below it is the O57.5. Modelling it as
    // a plain O57.5 cylinder overstated the front material by up to 2.9 mm and made the fit check lie.
    translate([0, unit_face_y + 1.45, unit_cz]) rotate([-90, 0, 0])
        cylinder(d = 52.00, h = 2.90, center = true);
    translate([0, unit_face_y + 2.90 + (unit_h - 2.90) / 2, unit_cz]) rotate([-90, 0, 0])
        cylinder(d = unit_dia, h = unit_h - 2.90, center = true);
}

module ghosts(which = "parts") {
    // Internal volumes, drawn almost solid so they read through the translucent shell.
    if (which == "parts" || which == "both") {
        color("green", 0.9) ghost_board();
        color("orange", 0.9) ghost_speaker();
    }
    if (which == "unit" || which == "both") {
        color("gold", 0.9) ghost_unit();
    }
}

module wall() {
    // The shell: the body minus the cavity. Intersecting it with a ghost has to yield NOTHING.
    difference() { body(); cavity(); }
}

module ghosts_pairwise() {
    // Ghost against ghost: the parts must not fight each other either. This pair is what the rejected
    // layout (bare board in front of a bare speaker) had to satisfy; the unit that was actually chosen
    // is one body, so it has nothing to fight.
    intersection() { ghost_board(); ghost_speaker(); }
}

module m4_points() {
    // Where the two wall screws are, and every feature of them: a quarter of the height up, a quarter
    // down, on the centre line. Children land in that frame (y = 0 at the plate's inner face).
    for (z = m4_z) translate([m4_x, 0, z]) children();
}

module m4_heads() {
    // Just the two M4 heads, seated in their pockets on the plate's inner face. The collar's fit check
    // bites these: at 24.2 the screw is 9.2 mm off the unit's axis and the collar lives at 29.2, so they
    // do not meet -- and that check is what keeps it that way if either one moves.
    color("darkorange", 0.95)
        m4_points() translate([0, inner_d - pocket_m4, 0])
            rotate([-90, 0, 0]) cylinder(d = m4_head_d, h = pocket_m4);
}

module wall_markers() {
    // The two M4 into the masonry, as screws: a head seated in the 1.5 mm pocket on the plate's inner
    // face and a shank that carries on through the plate and into the wall behind it. The upper one is
    // above the unit, in free air; the lower one sits behind the unit (inside its O57.5 footprint, which
    // is why the pocket has to be shallow: the gap there is 1.80 mm and the head is 1.50).
    m4_heads();
    color("darkorange", 0.95)
        m4_points() translate([0, inner_d, 0])
            rotate([-90, 0, 0]) cylinder(d = screw_m4_d, h = 22);
}

module review_view() {
    // What you see when you open this file, and what part = "review" / "screwplan2" renders: the joint in
    // one piece, with nothing cut away. Everything it draws is switchable from the Customizer -- the
    // show_* block at the top of the file -- and with the switches untouched this is the view exactly as
    // it always was.
    //
    // The shell goes in as a % (background) object, which does not occlude, so the markers -- drawn after
    // it, opaque -- stay visible straight through it. One background object only: --render culls the rest
    // (measured here the hard way). `show_solid` is the way out of that: the same shell drawn opaque, for
    // looking at the outer form and for checking the markers against a real surface.
    // The unit as the ordinary ghost, NOT a % one: --render only carries one background object, and with
    // unit also a % it vanished. Opaque, it still lets the collar's rim read -- O60.4 against its O57.5 --
    // as a ring around it, which is what the lap looks like from the front.
    if (show_lid || show_base) {
        if (show_solid) {
            if (show_base) color("grey", 0.85) base();
            if (show_lid)  color("silver", 0.85) lid();
        } else {
            %union() { if (show_base) base(); if (show_lid) lid(); }
        }
    }
    if (show_unit)   ghosts("unit");
    if (show_screws) screw_markers2();
    if (show_collar) color("green", 0.85) unit_collar();
    if (show_m4)     wall_markers();
    if (show_gland)  gland_marker();
    if (show_gasket) color("magenta", 0.85) gasket();
}

module translucent(which) {
    // The shell goes in as a % (background) object, NOT as color(..., alpha). Measured on this very
    // model, a white shell at alpha 0.15 produced zero pixels of the internal colours in the PNG,
    // in preview and with --render; the % modifier with --render keeps all three colours visible
    // (green 4.4 percent of the frame, red 5.3, orange 1.2 in a test rig).
    %union() { base(); lid(); }
    ghosts(which);
}

// ------------------------------------------------------------------- output
//
// One selector, `part`, for everything. A -D does override the file's own assignment (tested with a
// two-line file). What does NOT work is trusting the PNG export to show a translucent shell: without
// --render it renders opaque, the internal volumes vanish, and two views that must differ come out
// byte-identical.

if (part == "base") {
    base();
} else if (part == "lid") {
    lid();
} else if (part == "gasket") {
    // The foam ring on its own, for cutting or buying: 1.70 mm wide, 1.00 mm thick, and its shape is
    // the case's own contour between the rim's edges.
    gasket();
} else if (part == "assembly") {
    // Opaque, for the outer form.
    base();
    lid();
    ghosts("unit");
} else if (part == "inside") {
    // The review view now: the shell translucent, the assembled unit inside it.
    translucent("unit");
} else if (part == "inside_parts") {
    // The layout that was rejected (bare board, bare speaker, our own chamber), kept as the record.
    translucent("parts");
} else if (part == "screwplan2" || part == "review") {
    // REVIEW 2, whole: the view the file opens with (part = "review"), and the same under its own name so
    // a target can render it. No cutaway.
    review_view();
} else if (part == "screwplan") {
    // The under-review plan: the shell semi-transparent (as the default view), the unit inside, and
    // the two screw sets as rods. Review only: nothing here is cut.
    translucent("unit");
    screw_markers();
} else if (part == "section") {
    // Cutaway. Base, lid and the ghost are all cut at the same plane, so the half that remains
    // shows the real stack. The proposed screws are drawn in, to check them against the unit.
    difference() {
        union() {
            color("grey") base();
            color("silver") lid();
            ghosts("unit");
            screw_markers();
        }
        translate([-200, -60, -60]) cube([200, 400, 400]);   // cut away X > 0
    }
} else if (part == "exploded") {
    // The two printed parts pulled apart, with the unit they hold.
    color("silver") base();
    color("grey") translate([0, -58, 0]) lid();
    ghost_unit();
} else if (part == "fitcheck") {
    // The unit against the PRINTED parts, not against `wall`: wall is the un-cut shell, so it would
    // report the front wall where the lid's seat and window have already taken the material away.
    // The unit spans the split, so both parts are in the test.
    intersection() { union() { base(); lid(); } ghost_unit(); }
} else if (part == "fitcheck_parts") {
    intersection() { wall(); ghosts("parts"); }
} else if (part == "fitcheck_internal") {
    ghosts_pairwise();
} else if (part == "fitcheck_joint") {
    // REVIEW 3: the screw against both printed parts, and the pillar and the boss against their
    // neighbours. Must be empty.
    fitcheck_joint();
} else if (part == "fitcheck_pair") {
    // The two parts against each other, minus the joint plane they legitimately share: must be empty.
    // The plane itself is a contact and not an interference -- the base's shell and the lid's are both
    // cut at joint_y, so CGAL hands back a zero-thickness sheet there (0.000 mm3, 62 mm wide, no depth)
    // -- so one eps either side of it is taken out of the test. What is left is every real overlap:
    // above all the lap, where the lip sits inside the base's recess with 0.20 mm to spare.
    intersection() {
        base();
        lid();
        union() { keep_above(joint_y + eps); keep_below(joint_y - eps); }
    }
} else if (part == "probe_grille") {
    // Against the LID (not against `wall`, which is the un-cut shell): empty means every hole of the
    // field is open through the front wall. The probe is 1.0 mm smaller than the cut, so it does not
    // ride on the hole's wall.
    intersection() { lid(); grille_hole_cut(grille_hole - 1.0); }
} else if (part == "probe_button") {
    intersection() { lid(); button_cut_hole(btn_cut - 1.0); }
} else if (part == "probe_mic") {
    // Against the BASE, like probe_grille is against the lid: empty means both microphone slots are open
    // from outside the case into the cavity, wall and collar both. The probe is narrower and shorter
    // than the cut and spans the whole depth of the wall, so it proves the opening end to end.
    intersection() { base(); mic_probe(); }
} else if (part == "probe_gland") {
    // Against the BASE as well. Empty means the gland's hole is open end to end -- the boss's flat, the
    // shell, the cavity's ceiling and the locknut's pad -- and that the teardrop, in the round collar,
    // in the pad and in the shell at once, is one continuous opening rather than a pocket in any of them.
    intersection() { base(); gland_probe(); }
} else if (part == "probe_m4") {
    // Against the BASE. Empty means both wall screws have a way through: the head's pocket in the
    // plate's inner face, then the O4.50 clearance hole through the 3.40 of plate and out the back.
    // The rod is 1 mm narrower than the hole and spans the pocket's floor as well, so a pocket cut
    // without its hole -- or a hole without its pocket -- cannot pass this.
    intersection() { base(); m4_probe(); }
} else if (part == "fitcheck_gasket") {
    // The ring against both halves AT THE JOINT'S CLOSED GAP: the lid lifted the 0.70 the ring is
    // squeezed to, because in the dry, printed position that space is simply the lid's own material.
    // Empty then means the seat is real -- the ring lands on the base's rim, clears the lip by the
    // lap's 0.20 mm, and the lip still reaches 2.30 into the recess -- and that the ring is squashed
    // and not crushed. Its own 0.01/0.02 inset is what keeps its surfaces off the ones it sits on:
    // a contact between coplanar faces is a zero-thickness sheet to CGAL, not nothing, which is why
    // fitcheck_pair takes an eps either side of joint_y as well.
    intersection() {
        translate([0, -eps, 0]) gasket(gasket_gap - 2 * eps, eps);
        union() { base(); translate([0, -gasket_gap, 0]) lid(); }
    }
} else {
    // Default, so opening this file shows where the planned screws go. In one piece: a cutaway was not
    // readable.
    review_view();
}
