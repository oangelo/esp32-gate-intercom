// ESP32 Gate Intercom - enclosure
// Parametric case for a Waveshare ESP32-S3-AUDIO-Board with the speaker integrated
// in an acoustic chamber. Printed in ASA (see docs/decisions.md, ADR-009).
//
// STATUS: v0.0 scaffold. Every value marked TODO is a placeholder and must be
// replaced with a caliper measurement before anything is printed. See
// docs/dimensions.md for the measurement list.
//
// Usage:
//   openscad -D 'part="base"'      -o base.stl cad/case.scad
//   openscad -D 'part="lid"'       -o lid.stl  cad/case.scad
//   openscad -D 'part="assembly"'  -o assembly.stl cad/case.scad
//
// Convention: millimetres. Variable names are ASCII only (the parser breaks on accents).

// ---------------------------------------------------------------- parameters

part = "assembly";            // assembly | base | lid

// Board - TODO: measure (docs/dimensions.md items 1 to 8)
board_l      = 60.0;          // TODO item 1, longest side
board_w      = 40.0;          // TODO item 1, other side
board_t      = 1.6;           // TODO item 2, PCB thickness
comp_h_top   = 12.0;          // TODO item 4, tallest part above the PCB
bottom_h     = 3.0;           // TODO item 5, space needed under the PCB
hole_d       = 2.2;           // TODO item 3, board mounting hole diameter
hole_dx      = 52.0;          // TODO item 3, hole spacing along X
hole_dy      = 32.0;          // TODO item 3, hole spacing along Y

// Speaker - TODO: measure (docs/dimensions.md item 9)
spk_od       = 40.0;          // TODO speaker outer diameter
spk_depth    = 8.0;           // TODO speaker total depth
spk_gap      = 2.0;           // gap between speaker face and grille wall

// Microphone ports - TODO item 8
mic_d        = 3.0;           // acoustic port in front of each mic
mic_pitch    = 20.0;          // TODO distance between the two microphone holes
mic_from_front = 12.0;        // TODO distance from the front wall

// Case geometry
wall         = 3.0;           // printed wall thickness (ASA, 0.4 mm nozzle)
floor_t      = 3.0;
lid_t        = 3.0;
fit_clear    = 1.0;           // clearance around the board inside the cavity
corner_r     = 6.0;           // outer corner radius
head_clear   = 6.0;           // space above the tallest component

// Lid interface
lip_h        = 4.0;           // lid lip height that enters the base
lip_t        = 2.0;           // lip wall thickness
gasket_w     = 2.5;           // gasket cord diameter
gasket_d     = 2.0;           // groove depth

// Cable entry and mounting
gland_d      = 12.5;          // PG7 gland through hole
tab_w        = 14.0;          // mounting tab width
tab_t        = 4.0;           // mounting tab thickness
tab_hole_d   = 4.5;           // M4 clearance

// Hardware
boss_d       = 8.0;           // screw boss outer diameter (M3 heat-set insert)
boss_hole_d  = 4.2;           // heat-set insert bore
screw_l      = 12.0;          // M3 x 12 lid screws

// ---------------------------------------------------------------- derived

inner_l  = board_l + 2 * fit_clear;
inner_w  = board_w + 2 * fit_clear;
cavity_h = bottom_h + board_t + comp_h_top + head_clear;
outer_l  = inner_l + 2 * wall;
outer_w  = inner_w + 2 * wall;
base_h   = floor_t + cavity_h;
lid_extra = spk_depth + spk_gap;
lid_total = lid_t + lid_extra;
eps      = 0.01;
$fa = 2;
$fs = 0.5;

// ---------------------------------------------------------------- modules

module rounded_block(l, w, h, r) {
    // Rectangular block with rounded vertical corners, sitting on z=0
    hull() {
        for (x = [-(l / 2 - r), l / 2 - r], y = [-(w / 2 - r), w / 2 - r])
            translate([x, y, 0]) cylinder(r = r, h = h);
    }
}

module screw_boss(h) {
    difference() {
        cylinder(d = boss_d, h = h);
        translate([0, 0, -eps]) cylinder(d = boss_hole_d, h = h + 2 * eps);
    }
}

module case_base() {
    difference() {
        rounded_block(outer_l, outer_w, base_h, corner_r);

        // main cavity
        translate([0, 0, floor_t])
            rounded_block(inner_l, inner_w, base_h, corner_r - wall);

        // gasket groove in the rim
        translate([0, 0, base_h - gasket_d])
            difference() {
                rounded_block(outer_l - wall, outer_w - wall, gasket_d + eps, corner_r - wall * 0.5);
                rounded_block(outer_l - wall - 2 * gasket_w - 2 * wall, outer_w - wall - 2 * gasket_w - 2 * wall,
                              gasket_d + 2 * eps, corner_r - wall);
            }

        // board standoffs (three, so the board cannot rock)
        for (p = [[-(inner_l / 2 - 5), -(inner_w / 2 - 5)],
                  [ (inner_l / 2 - 5), -(inner_w / 2 - 5)],
                  [ 0,                 (inner_w / 2 - 5)]])
            translate([p[0], p[1], floor_t - eps])
                cylinder(d = 4, h = bottom_h + eps);

        // cable gland, on the bottom face, at the back
        translate([0, inner_w / 2, -eps])
            cylinder(d = gland_d, h = floor_t + 2 * eps);

        // mounting tabs holes
        for (x = [-1, 1])
            translate([x * (outer_l / 2 + tab_w / 2 - 1), 0, -eps])
                cylinder(d = tab_hole_d, h = tab_t + 2 * eps);
    }

    // screw bosses in the four corners
    for (x = [-1, 1], y = [-1, 1])
        translate([x * (inner_l / 2 - boss_d / 2 + 1), y * (inner_w / 2 - boss_d / 2 + 1), floor_t])
            screw_boss(base_h - floor_t - 1);

    // mounting tabs
    for (x = [-1, 1])
        translate([x * (outer_l / 2 + tab_w / 2 - 1), 0, 0])
            difference() {
                rounded_block(tab_w, tab_t * 2.5, tab_t, 1.5);
                translate([0, 0, -eps]) cylinder(d = tab_hole_d, h = tab_t + 2 * eps);
            }
}

module case_lid() {
    difference() {
        union() {
            rounded_block(outer_l, outer_w, lid_t, corner_r);

            // lid lip that enters the base
            translate([0, 0, -lip_h])
                difference() {
                    rounded_block(outer_l - wall * 2 - 0.4, outer_w - wall * 2 - 0.4, lip_h + eps, corner_r - wall);
                    rounded_block(outer_l - wall * 2 - 0.4 - 2 * lip_t, outer_w - wall * 2 - 0.4 - 2 * lip_t,
                                  lip_h + 2 * eps, corner_r - wall - lip_t);
                }

            // speaker chamber wall on the inside
            translate([0, -(inner_w / 2 - spk_od / 2 - 2), -lid_extra])
                difference() {
                    cylinder(d = spk_od + 2 * wall, h = lid_extra + eps);
                    translate([0, 0, -eps]) cylinder(d = spk_od, h = lid_extra + 2 * eps);
                }
        }

        // speaker grille: a ring of holes, downward facing wall
        for (a = [0:30:330])
            rotate([0, 0, a])
                translate([0, -(inner_w / 2 - spk_od / 2 - 2), -lid_extra - eps])
                    translate([(spk_od / 2) * 0.6, 0, 0])
                        cylinder(d = 3.0, h = lid_extra + 2 * eps);

        // centre hole of the grille
        translate([0, -(inner_w / 2 - spk_od / 2 - 2), -lid_extra - eps])
            cylinder(d = 6.0, h = lid_extra + 2 * eps);

        // microphone ports at the front of the lid
        for (x = [-1, 1])
            translate([x * mic_pitch / 2, inner_w / 2 + wall / 2 - mic_from_front * 0 + 0, -eps])
                cylinder(d = mic_d, h = lid_t + 2 * eps);

        // lid screw holes
        for (x = [-1, 1], y = [-1, 1])
            translate([x * (inner_l / 2 - boss_d / 2 + 1), y * (inner_w / 2 - boss_d / 2 + 1), -eps])
                cylinder(d = 3.4, h = lid_t + 2 * eps);
    }
}

// ---------------------------------------------------------------- assembly

if (part == "base") {
    case_base();
} else if (part == "lid") {
    case_lid();
} else {
    // preview: base with the lid above it, plus the board volume as a ghost
    color("grey") case_base();
    translate([0, 0, base_h + 20]) color("darkgrey") case_lid();
    translate([0, 0, floor_t + bottom_h]) color("green", 0.4) cube([board_l, board_w, board_t], center = true);
}
