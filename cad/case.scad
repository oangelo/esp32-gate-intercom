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
part    = "inside";     // the one selector: inside | assembly | inside_parts | base | lid |
                        // section | exploded | screwplan | fitcheck | fitcheck_parts |
                        // fitcheck_internal | probe_grille | probe_button
                        // Default is `inside`: the shell semi-transparent, the unit visible in it.
                        // `assembly` is the same thing opaque, for the outer form.

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
// Not cut yet: this block is the plan, and the render view `screwplan` draws it. The numbers come
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
// of the unit's way: the gap behind the unit is 1.80 mm, so each head sits in a 1.7 mm pocket in
// the plate's inner face. Three of them, on a 26 mm radius around the unit's axis at 60/180/300
// degrees, which interleaves them with the unit's own three standoffs at 0/120/240.
screw_m4_r = 26.0;
screw_m4_a = [60, 180, 300];
screw_m4_d = 4.5;       // clearance for M4 (nylon plug in the masonry)
pocket_m4  = 1.70;      // pocket depth in a 3 mm plate: 1.3 mm left

module screw_markers() {
    // PROPOSED positions only: rods along Y, nothing cut. Red = lid to base, blue = base to wall.
    for (p = screw_m3)
        color("red", 0.9) translate([p[0], -3, p[1]]) rotate([-90, 0, 0])
            cylinder(d = screw_m3_d, h = case_d + 6);
    for (a = screw_m4_a)
        color("blue", 0.9) translate([screw_m4_r * cos(a), -3, 33 + screw_m4_r * sin(a)])
            rotate([-90, 0, 0]) cylinder(d = screw_m4_d, h = case_d + 6);
}

// ------------------------------------------------------------------- the two parts

module base() {
    // Back tray: closed. The back plate goes against the wall, so nothing goes through it -- no
    // acoustic window, no gland, no vent. What it carries is the three pads that push the unit
    // forward onto the seat. The gland and the vent still live here in name only: they move to a
    // side or to the bottom (step 3).
    difference() {
        intersection() { body(); keep_above(split_y); }
        cavity();
    }
    unit_pads();
}

module lid() {
    // Front shell: the closed grille field over the unit's own grille, and the button.
    difference() {
        intersection() { body(); keep_below(split_y); }
        cavity();
        unit_seat_cut();
        grille_cut();
        button_cut_hole(btn_cut);
        button_lands_cut();
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
} else if (part == "probe_grille") {
    // Against the LID (not against `wall`, which is the un-cut shell): empty means every hole of the
    // field is open through the front wall. The probe is 1.0 mm smaller than the cut, so it does not
    // ride on the hole's wall.
    intersection() { lid(); grille_hole_cut(grille_hole - 1.0); }
} else if (part == "probe_button") {
    intersection() { lid(); button_cut_hole(btn_cut - 1.0); }
} else {
    translucent("unit");
}
