# ESP32 Gate Intercom - build helpers
# Everything runs on a plain openscad install; no other dependency for the model itself.

SCAD  ?= cad/case.scad
BUILD ?= build

.PHONY: all check stl base lid display render clean

all: check

## Compile the whole model and surface any warning or error
check:
	@mkdir -p $(BUILD)
	@openscad -D 'part="assembly"' -o $(BUILD)/check.stl $(SCAD) > $(BUILD)/openscad.log 2>&1 \
		|| { cat $(BUILD)/openscad.log; exit 1; }
	@grep -iE 'warning|error' $(BUILD)/openscad.log || echo "clean compile"

## Export both printed parts
stl: base lid

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

clean:
	rm -rf $(BUILD)
