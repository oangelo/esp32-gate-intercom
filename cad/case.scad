// ESP32 Gate Intercom - enclosure, revision 2
// Parametric case for a Waveshare ESP32-S3-AUDIO-Board. Printed in ASA (ADR-009).
//
// STATUS: revision 2, step 1 - the FORM and the fit, not the features yet.
// This file has: the capsule profile, the crown on the front face, the cavity, the base/lid
// split, and the board, speaker and buck as ghosts to prove they fit. Still to come, in this
// order, each one reviewed before the next:
//   1. speaker pocket, grille field and drip lip (lid, lower half)
//   2. button flat land and the O22 cutout (lid, upper half)
//   3. microphone acoustic ports in the back wall, membrane vent, cable gland (base)
//   4. joint: lid lip, gasket groove, four M3 heat-set bosses
//   5. mounting ears and the buck standoffs
// Every number below is measured or derived; the source of each is docs/dimensions.md.
//
// Frame: X = width, Y = depth (0 at the apex of the front face, CASE_D at the back plate),
// Z = height (0 at the floor). The case stands upright in use.
//
// PRINT ORIENTATION: both parts print lying down, with the case's Y as the printer's Z.
// The base prints on its back plate (cavity opening up, standoffs vertical, gland and vent
// holes vertical) and the lid prints on its face (cavity opening up, the speaker bore vertical
// instead of a 43 mm ceiling to bridge). The flat lands that step 2 spot-faces into the front
// face are what gives the lid its bed contact.
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
//   openscad -D 'part="probe_grille"' ...                                     # must be EMPTY
//   openscad -D 'part="probe_button"' ...                                     # must be EMPTY
//
// Everything is selected through `part`, one selector for every view. The translucent views need
// --render: without it the PNG export draws the shell as opaque and the internals disappear, which
// makes two views that must differ come out byte-identical. Compare with md5 and with
// --summary all, never by looking at the picture.
//
// Convention: millimetres. Variable names are ASCII only (the parser breaks on accents).

// --------------------------------------------------------- measured (docs/dimensions.md)
board_dia    = 57.63;   // board is ROUND. The vendor DXF says 58.00; caliper TODO item 1
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
                        // section | exploded | screwplan | fitcheck | fitcheck_parts |
                        // fitcheck_internal | fitcheck_joint | probe_grille | probe_button
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
show_m4       = true;   // [true,false]  the two M4 into the wall (a marker: not cut yet)

// DECIDED (2026-09-24): the Waveshare goes in ASSEMBLED, as one cylinder -- board, black body with
// the speaker inside, acrylic band and cover, all screwed together, and its own acoustic chamber and
// microphone ducting come with it. The case is built around that, which is what the depth above and
// the unit placement below are.
//
// The case stays CLOSED: the front is solid over the unit with a recessed grille field drilled through
// it (the sound leaves through ours and then the unit's), and the back plate has nothing in it at all --
// that face is mortared flat against the wall. The microphones breathe the cavity, whose only way out is
// that grille field.
//
// Height, and why the model uses 47.00: the assembled product measures 49.70 in the vendor STEP,
// which includes the three rubber feet (2.70) stuck on the grille face. With the unit's grille face
// forward, those feet would press against the front wall, so they come off and the unit is 47.00.
// The other sources, for the record: the drawing on the product page says 43.70 + 5.10 = 48.80; the
// DXF says 44.30 to the bottom of the body and 47.00 to the bottom of the O52 disc; and 37.60 is
// PCB top to body bottom. docs/dimensions.md says the caliper wins where they disagree, and if the
// real part is 48.80 rather than 47.00 the case has 1.80 mm less margin than it thinks.
unit_dia  = 58.00;
unit_h    = 47.00;      // 49.70 measured, minus the feet; the unit's own grille is its front face
unit_face_y = 6.20;     // its grille face: clears the inner crown at the unit's rim by 1.00 mm
unit_cy   = unit_face_y + unit_h / 2;   // 29.70: unit centre on the depth axis
unit_cz   = 33.00;      // the LOWEST it can sit and still clear the rounded bottom, and low is what
                        // frees the upper half for the panel button (ADR-018)

case_w  = 66.0;         // board 57.63 + 1 mm clearance a side + 2 x 3 mm wall
case_h  = 96.0;         // 30 mm of straight side + the two O66 ends (ADR-015: capsule)
case_d  = 58.0;         // DECIDED: the assembled unit goes in whole, so this is the unit's depth
                        // 47.00 (feet peeled off) + the front gap at its rim + the back gap, plus
                        // the two walls. Was 49 when the plan was a bare board and our own chamber
wall    = 3.0;
r_end   = case_w / 2;   // 33: radius of both ends
z_btm   = r_end;                       // 33: centre of the bottom semicircle
z_top   = case_h - r_end;              // 63: centre of the top semicircle
crown_s = 5.0;                         // sagitta of the front crown (convex front, ADR-015)
crown_r = (pow(r_end, 2) + pow(crown_s, 2)) / (2 * crown_s);   // 111.4

split_y = 27.5;         // base/lid joint: behind the speaker, in front of the board. The lid
                        // keeps 1.5 mm behind the speaker to retain it (step 1 of the features)
inner_d = case_d - wall;               // 55: inner face of the back plate
cav_x   = r_end - wall;                // 30: inner radius; the ends share the outside centres
cav_y0  = 3.0;                         // 3: inner apex of the crown

// The three board standoffs (r = 23.75 at -36.1, +36.1, 180 degrees) leave exactly three gaps
// against the wall: around 0 degrees (+X side), 108 degrees (upper left) and 252 degrees (lower
// left). Every joint boss and every mounting ear has to live in one of those three gaps, because
// the board's 57.63 fills the rest of the back plate. Nothing else fits behind it.
//
// With the bottom end round, the cavity narrows fast below z = 33 (at z = 8 it is only +-16.6),
// so the board also has to sit high enough that its 57.63 clears the curve: at its centre height
// of 37 mm the clearance is 1 mm a side, and it is the sides, not the floor, that decide.

// The inner face of the front is the crown, so it recedes as it goes out: at the speaker's
// radius (21.65) it sits at y = 5.18 instead of 3.00. A flat speaker face has to clear that,
// which is why it starts at 5.5 and why step 1 spot-faces a flat seat into the crown.
spk_cy   = 15.75;       // speaker front face at 5.50, then half its depth (bare-parts ghost)
board_cy = 30.60;       // board front face at 30.00: 4 mm behind the speaker (bare-parts ghost)
board_cz = 37.0;        // board centre height (bare-parts ghost)
spk_cz   = 26.0;        // speaker centre height (bare-parts ghost)

eps = 0.01;
$fa = 2;
$fs = 0.4;

// --------------------------------------------------------- features: grille (lid, lower half)
// The unit brings its own grille behind the disc face, and the case's front is CLOSED over it: a
// recessed field of through holes, so the sound leaves through ours and then through the unit's. The
// same holes are the microphones' air path -- the unit listens through its own cover (eight O1 holes),
// whose air volume is the cavity, which the grille holes connect to the outside. No hole in the back
// plate: that face is mortared flat against the wall.
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
unit_pad_r    = 23.0;   // clear of the vendor's O1 holes (r <= 8.9) and of the O58 edge
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
btn_cz      = 76.0;     // button centre. Constraints, all three: below the cavity's ceiling (93) with
                        // the land; above the unit's top edge at 62 and clear of the seat's rim at
                        // 59.5 by 1.5 mm; and the switch's body (O22, 30 deep) has to live between
                        // them -- it ends up at 61.5, so it clears the unit by 0.5 mm and the ceiling
                        // by a lot. If the unit measures 48.80 instead of 47.00, this is where the
                        // margin goes first: the unit's top edge moves to 63.

// ------------------------------------------------------------------- helpers

module prism_xz(depth, y0 = 0) {
    // Extrude a 2D shape drawn in (x = width, y = height) along the case's Y (depth).
    translate([0, y0 + depth, 0]) rotate([90, 0, 0]) linear_extrude(height = depth) children();
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
    // Same shape, offset inwards by the wall: radius r_end - wall, same end centres.
    union() {
        translate([-cav_x, z_btm]) square([2 * cav_x, z_top - z_btm]);
        translate([0, z_btm]) circle(r = cav_x);
        translate([0, z_top]) circle(r = cav_x);
    }
}

module crown_outer() { translate([0, crown_r, -1]) cylinder(r = crown_r, h = case_h + 2); }
module crown_inner() { translate([0, crown_r, -1]) cylinder(r = crown_r - wall, h = case_h + 2); }

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
// plate's inner face, 3 mm off the wall, which is what "rente" means here. The plate is 3 mm, so a
// O8 counterbore 1.5 mm deep on the inner face plus a low or button head M4 (2.2 mm tall) is the
// combination that works: 1.5 mm of plate left, 0.7 mm of head in the 1.8 mm gap behind the unit.
// A countersunk M4 (2.35 mm) would leave 0.65 mm of plate: it does not work in 3 mm. The numbers come
// from working the case's own clearances backwards, and one of them decides the whole layout.
//
// The joint moves to y = 8. Today it is at 27.5, which is 27.5 mm behind the front face: a screw
// through the front wall would need M3 x 30 and 17 mm of plastic to cross. At 8 the front part is a
// shallow cap, the screws are M3 x 14, and the unit is carried by the deep back part. Everything
// already modelled survives the move: the seat is at 6.25, the grille field spans 3.0 to 6.25, the
// button's lands sit at 1.2 and 4.5 -- all inside 8 -- and the switch's 30 mm body passes through
// into the back part's cavity, which is open air at (0, 76).
//
// The "lábio" is a half-lap: the base's skirt, at full radius, laps over the lid's stepped rim.
// lap_step 1.6 leaves 1.4 mm of skirt and 1.4 mm of rim, both still above the 1.2 mm rule, and the
// outer surfaces stay flush so the seam is a corner the water has to turn.
joint_y  = 8.0;         // PROPOSED: was 27.5
lap_d    = 3.0;         // lap length
lap_step = 1.6;         // radial step
lap_gap  = 0.2;         // clearance on the lap; the gasket is a 1 mm closed-cell ring on the shoulder
gasket_y = 4.5;         // PROPOSED: the shoulder where the foam ring sits (at the dome's brim)
lap_proud = 0.4;        // the base's skirt stands proud of the lid's surface: a drip lip

// The screws, and why they are NOT spread evenly around the loop:
//  - the ring is 3 mm thick (wall) and the case is 66 wide, so a screw head needs 6.3 mm: there is
//    nowhere in the ring for a countersink, at any angle;
//  - so a screw has to go through the lid's shell (3.1 mm thick, a 1.65 mm countersink leaves 1.45)
//    into material BEHIND it, and that material can only be a boss standing inward from the wall;
//  - a boss standing inward collides with the unit (O58 in a O60 cavity: a 1 mm annulus) everywhere
//    the unit is widest, which is the whole lower half. The unit's circle is what sets it: a boss
//    needs ~5 mm of width and the room for it only appears at z >= 47 and, cleanly, above z = 62;
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
// and 270 degrees lands on x = 0 too -- so only Z moved, from 7/59 to 24/72. Two things improve and
// one gets slightly worse. Better: the pair is now symmetric about the case's own centre (48), so
// the hanging weight reaches the screws as shear instead of loading one of them with a moment -- at
// 7 and 59 their centre sat at 33, below the mass. Better again: at 24 the screw is 9 mm off the
// unit's axis, so its head is nowhere near the collar's O60.4 (which is what retired the collar's
// M4 windows, ADR-020) while still landing in the 1.8 mm gap behind the unit, and at 72 it is clear
// ABOVE the unit (top edge 62) and below the switch's body (y = 31.2), so it is reachable with the
// unit already installed. Worse: 48 mm between them instead of 52, a little less leverage against
// tipping -- the price of the symmetry, and a small one.
m4_z = [case_h / 4, case_h - case_h / 4];   // 24 and 72: the quarter points
m4_x = 0.0;                                 // the centre line
screw_m4_d = 4.5;       // clearance for M4 (nylon plug in the masonry)
pocket_m4  = 1.50;      // REVIEW 2: 1.5 mm deep is what the corrected note says: 1.5 mm left

// ------------------------------------------------- REVIEW 3: socket head screws into brass inserts
// (2026-09-25, third review.) Two changes, both from the user's review of review 2, and together they
// replace the rib:
//   - the fastener is a SOCKET HEAD CAP SCREW (ISO 4762 / DIN 912), stainless A2 into a brass insert
//     (ADR-017), not the countersunk one. Its head is CYLINDRICAL, O5.5 x 3.0, so the lid gets a
//     cylindrical counterbore with the head down inside it: nothing stands proud of the case;
//   - the rib becomes a round PILLAR standing off the back plate, carrying the brass insert that the
//     screw bites. No self-tapping into a rib.
//
// Where the pair goes: the unit's circle (O58, centre (0, 33)) and the switch's body (O22, centre
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
m3b_wallin_y = crown_r - sqrt(pow(crown_r - wall, 2) - pow(m3b[0], 2));   // 4.50, its inner face
m3b_seat_y   = m3b_face_y + m3b_head_h;                                    // 4.66, the head's seat
// Worked end to end: the shank runs from m3b_seat_y to 16.66, the insert spans 8.00 to 13.00 (all
// 5 mm of it bitten) and the pillar's blind hole ends at 18.00, 1.34 mm clear of the tip.
//
// The collar on the floor (the "lábio"): it locates the unit's O58 body -- and as of review 3 it is
// CUT into the base, not a drawing. Both of its new numbers come from the cavity's own width: the
// inner radius is cav_x = 30.0 and the unit is O58, so the gap all the way round is EXACTLY 1.0 mm.
// A 2.3 mm wall (the old O63) had nowhere to go; the collar spends the millimetre instead: 1.0 mm of
// collar on 0.2 mm of clearance. 58.4 + 2 x 1.0 = 60.4 outside, so its outer 0.2 mm sits INSIDE the
// cavity's wall and fuses with it. Deliberate, not sloppy: that fusion is what backs a 1.0 mm ring,
// which on its own would be the thinnest unsupported thing in the case (rule 3 asks for 1.2).
lip_bore  = 58.4;       // the unit's own O58 plus 0.2 a side: rule 6's "tight fit"
lip_wall  = 1.00;       // the collar's thickness: the whole of the gap, see above
lip_od    = lip_bore + 2 * lip_wall;   // 60.4
lip_h     = 5.00;       // how far up it goes. 1.80 of that is the gap behind the unit, 3.20 is skirt
                        // over the unit's own body, and the skirt is the point: with 0.4 mm of total
                        // clearance the unit can cock by atan(0.4/3.2) = 7.1 degrees where 1.75 mm of
                        // collar let it cock by 12.9. It stays clear of the base/lid joint at 27.5.
m4_head_d = 8.0;        // the M4 head, seated in its pocket on the plate's inner face

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
            // them clear if either one moves. It bites the collar itself, not base(): base() still has
            // the whole back plate solid -- the M4 pockets are markers, not cuts -- so a head would
            // always meet it.
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
    // A plain ring now, with no windows in it. It had two (a O9 on each M4 axis) while the wall screws
    // sat on the 26 mm radius around the unit's axis: an O8 head reaches r = 30, past lip_bore's 29.2,
    // so the ring would have stood on the screw heads. The screws are at 24 and 72 as of ADR-021, and
    // 24 is 9 mm off that axis -- far inside the bore -- so there is nothing left to clear.
    translate([0, inner_d - lip_h, unit_cz]) rotate([-90, 0, 0])
        difference() {
            cylinder(d = lip_od, h = lip_h + eps, $fn = 128);
            translate([0, 0, -1]) cylinder(d = lip_bore, h = lip_h + 2, $fn = 128);
        }
}

// ------------------------------------------------------------------- the two parts

module base() {
    // Back tray: closed. The back plate goes against the wall, so nothing goes through it -- no
    // acoustic window, no gland, no vent. What it carries is the three pads that push the unit
    // forward onto the seat, and (review 3) the two pillars the lid screws into and the collar that
    // locates the unit. The gland and the vent still live here in name only: they move to a side or
    // to the bottom (step 3).
    difference() {
        union() {
            difference() {
                intersection() { body(); keep_above(split_y); }
                cavity();
            }
            m3_pillars();
            unit_collar();
        }
        m3_pillar_holes();
    }
    unit_pads();
}

module lid() {
    // Front shell: the closed grille field over the unit's own grille, the button, and the two
    // counterbored holes whose screws pull it down onto the base's pillars.
    difference() {
        union() {
            difference() {
                intersection() { body(); keep_below(split_y); }
                cavity();
            }
            m3_lid_boss();
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
    // the body's face, measured in the vendor STEP, and the body below it is the O58. Modelling it as
    // a plain O58 cylinder overstated the front material by up to 2.9 mm and made the fit check lie.
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
    // bites these: at 24 the screw is 9 mm off the unit's axis and the collar lives at 29.2, so they do
    // not meet -- and that check is what keeps it that way if either one moves.
    color("darkorange", 0.95)
        m4_points() translate([0, inner_d - pocket_m4, 0])
            rotate([-90, 0, 0]) cylinder(d = m4_head_d, h = pocket_m4);
}

module wall_markers() {
    // The two M4 into the masonry, as screws: a head seated in the 1.5 mm pocket on the plate's inner
    // face and a shank that carries on through the plate and into the wall behind it. The upper one is
    // above the unit, in free air; the lower one sits behind the unit (inside its O58 footprint, which
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
    // the unit also a % it vanished. Opaque, it still lets the collar's rim read -- O63 against its O58 --
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
} else if (part == "probe_grille") {
    // Against the LID (not against `wall`, which is the un-cut shell): empty means every hole of the
    // field is open through the front wall. The probe is 1.0 mm smaller than the cut, so it does not
    // ride on the hole's wall.
    intersection() { lid(); grille_hole_cut(grille_hole - 1.0); }
} else if (part == "probe_button") {
    intersection() { lid(); button_cut_hole(btn_cut - 1.0); }
} else {
    // Default, so opening this file shows where the planned screws go. In one piece: a cutaway was not
    // readable.
    review_view();
}
