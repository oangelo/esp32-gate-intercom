# ESP32 Gate Intercom - build helpers
# Everything runs on a plain openscad install; no other dependency for the model itself.

SCAD  ?= cad/case.scad
BUILD ?= build

.PHONY: all check stl base lid display render section fit exploded inside_render screwplan review clean

all: check

## Compile the whole model and surface any warning or error
check:
	@mkdir -p $(BUILD)
	@openscad -D 'part="assembly"' -o $(BUILD)/check.stl $(SCAD) > $(BUILD)/openscad.log 2>&1 \
		|| { cat $(BUILD)/openscad.log; exit 1; }
	@grep -iE 'warning|error' $(BUILD)/openscad.log || echo "clean compile"

## Export both printed parts
stl: base lid gasket

base:
	@mkdir -p $(BUILD)
	@openscad -D 'part="base"' -o $(BUILD)/case_base.stl $(SCAD) > $(BUILD)/base.log 2>&1 \
		|| { cat $(BUILD)/base.log; exit 1; }
	@grep -iE 'warning|error' $(BUILD)/base.log || echo "build/case_base.stl clean"

lid:
	@mkdir -p $(BUILD)
	@openscad -D 'part="lid"' -o $(BUILD)/case_lid.stl $(SCAD) > $(BUILD)/lid.log 2>&1 \
		|| { cat $(BUILD)/lid.log; exit 1; }
	@grep -iE 'warning|error' $(BUILD)/lid.log || echo "build/case_lid.stl clean"

## The joint's foam ring: not printed, but its outline is what gets cut or bought.
gasket:
	@mkdir -p $(BUILD)
	@openscad -D 'part="gasket"' -o $(BUILD)/case_gasket.stl $(SCAD) > $(BUILD)/gasket.log 2>&1 \
		|| { cat $(BUILD)/gasket.log; exit 1; }
	@grep -iE 'warning|error' $(BUILD)/gasket.log || echo "build/case_gasket.stl clean"

## Xvfb display for headless PNG rendering (do not use xvfb-run, it hangs OpenSCAD)
display:
	@pgrep -f 'Xvfb :77' > /dev/null || (Xvfb :77 -screen 0 1280x1024x24 > /dev/null 2>&1 & sleep 1)

## Render a preview PNG into cad/media/
render: display
	@mkdir -p cad/media
	@DISPLAY=:77 openscad -D 'part="assembly"' -o cad/media/case_preview.png \
		--viewall --autocenter --imgsize=1200,900 $(SCAD) > $(BUILD)/render.log 2>&1 \
		|| { cat $(BUILD)/render.log; exit 1; }
	@ls -la cad/media/case_preview.png

## Render the cutaway, which is the review view: the assembled unit inside the shell.
## Fixed camera, because --viewall hides proportions on a part this size.
section: display
	@mkdir -p cad/media
	@DISPLAY=:77 openscad -D 'part="section"' -o cad/media/case_section.png \
		--imgsize=1400,1000 --camera=-175,-150,145,0,29,48 $(SCAD) > $(BUILD)/section.log 2>&1 \
		|| { cat $(BUILD)/section.log; exit 1; }
	@ls -la cad/media/case_section.png
	@python3 tools/annotate_render.py cad/media/case_section.png cad/media/case_section_anotado.png --view section

## Prove the ghosts touch neither a wall nor each other, and that the openings are open.
## Everything except nothing: all of these must print "empty".
fit:
	@for p in fitcheck fitcheck_parts fitcheck_internal fitcheck_joint fitcheck_pair fitcheck_gasket probe_grille probe_button probe_mic probe_gland probe_m4; do \
		printf '%-22s ' $$p; \
		openscad -D "part=\"$$p\"" -o $(BUILD)/$$p.stl $(SCAD) 2>&1 \
			| grep -q 'top level object is empty' && echo 'empty: no interference' || echo 'GEOMETRY: interference, look at it'; \
	done

## Translucent shell, the assembled unit inside (the chosen layout) and the bare parts (rejected).
## --render is not optional here: without it the PNG export draws the shell opaque, the internals
## vanish, and the two images come out byte-identical (which is how this was caught).
inside_render: display
	@mkdir -p cad/media
	@DISPLAY=:77 openscad -D 'part="inside"' --render -o cad/media/case_inside.png \
		--imgsize=1400,1000 --camera=170,-230,150,0,29,48 $(SCAD) > $(BUILD)/inside.log 2>&1 \
		|| { cat $(BUILD)/inside.log; exit 1; }
	@DISPLAY=:77 openscad -D 'part="inside_parts"' --render -o cad/media/case_inside_parts.png \
		--imgsize=1400,1000 --camera=170,-230,150,0,29,48 $(SCAD) > $(BUILD)/inside_parts.log 2>&1 \
		|| { cat $(BUILD)/inside_parts.log; exit 1; }
	@md5sum cad/media/case_inside.png cad/media/case_inside_parts.png
	@python3 tools/annotate_render.py cad/media/case_inside.png cad/media/case_inside_anotado.png --view unit
	@python3 tools/annotate_render.py cad/media/case_inside_parts.png cad/media/case_inside_parts_anotado.png --view parts

## Render the two printed parts pulled apart, to review them together
exploded: display
	@mkdir -p cad/media
	@DISPLAY=:77 openscad -D 'part="exploded"' -o cad/media/case_exploded.png \
		--imgsize=1400,1000 --camera=170,-230,150,0,0,48 $(SCAD) > $(BUILD)/exploded.log 2>&1 \
		|| { cat $(BUILD)/exploded.log; exit 1; }
	@ls -la cad/media/case_exploded.png

## Render the under-review joint and screw plan: the shell semi-transparent, the unit inside, and
## the two screw sets as rods.  --render because of the translucent shell (see inside_render).
screwplan: display
	@mkdir -p cad/media
	@DISPLAY=:77 openscad -D 'part="screwplan"' --render -o cad/media/case_screwplan.png \
		--imgsize=1400,1000 --camera=-175,-150,145,0,33,48 $(SCAD) > $(BUILD)/screwplan.log 2>&1 \
		|| { cat $(BUILD)/screwplan.log; exit 1; }
	@ls -la cad/media/case_screwplan.png
	@python3 tools/annotate_render.py cad/media/case_screwplan.png cad/media/case_screwplan_anotado.png --view screw

clean:
	rm -rf $(BUILD)

## The review view (which is also the file's own default): the two screws, their pillars, the brass
## inserts and the unit's collar, whole, with the shell in as a background object. Three angles,
## because one angle always hides one of the two screws.  --render: see inside_render.
review: display
	@mkdir -p cad/media
	@DISPLAY=:77 openscad -D 'part="review"' --render -o cad/media/case_review_a.png \
		--imgsize=1400,1000 --camera=170,-230,150,0,29,48 $(SCAD) > $(BUILD)/review_a.log 2>&1 \
		|| { cat $(BUILD)/review_a.log; exit 1; }
	@DISPLAY=:77 openscad -D 'part="review"' --render -o cad/media/case_review_b.png \
		--imgsize=1400,1000 --camera=-170,-230,150,0,29,48 $(SCAD) > $(BUILD)/review_b.log 2>&1 \
		|| { cat $(BUILD)/review_b.log; exit 1; }
	@DISPLAY=:77 openscad -D 'part="review"' --render -o cad/media/case_review_c.png \
		--imgsize=1400,1000 --camera=-150,280,170,0,29,48 $(SCAD) > $(BUILD)/review_c.log 2>&1 \
		|| { cat $(BUILD)/review_c.log; exit 1; }
	@ls -la cad/media/case_review_a.png cad/media/case_review_b.png cad/media/case_review_c.png
