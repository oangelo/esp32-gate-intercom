# Design decisions

Short records of decisions that were expensive to reach. Each one cost at least one afternoon of
hardware time, so they are written down before they get re-litigated.

## ADR-001: ESPHome instead of ESP-IDF

**Decision:** build the device firmware with ESPHome, not with ESP-IDF/ESP-ADF.

**Why:** the House already runs ESPHome devices, the same codec pair (ES7210 + ES8311) is already
proven on the network, ESPHome has native drivers for both chips, and the intercom functionality lives
in a maintained third-party component. ESP-IDF would mean re-implementing the audio pipeline for no
gain at this stage.

## ADR-002: full duplex with hardware AEC, not half-duplex squelch

**Decision:** keep real full duplex and cancel the echo in the firmware. Half-duplex squelch (mute the
mic while the speaker plays) was explicitly rejected as the main plan.

**Why:** the board ships an echo-cancellation reference path in copper: the ES8311 analog output is
attenuated and filtered into the ES7210 MIC3 input, in a schematic block literally labelled "AEC"
(Korvo-2 topology). Squelch would throw that away and make the intercom walkie-talkie style. Measured
result after using it: 42 to 47 dB of suppression.

## ADR-003: AEC mode is the lever, not the reference path

**Decision:** run `esp_aec` with `mode: voip_low_cost`, and keep the delay-buffer reference
(`use_tdm_reference: false`).

**Why:** measured on the same stimulus, interleaved A/B: `sr_low_cost` gave roughly **0 dB** of
suppression (unstable, one run at -78 dB and the next at -52 dB), while `voip_low_cost` gave **42 to
47 dB**, repeatedly. `sr_low_cost` is the speech-recognition line: it is tuned to preserve speech even
over echo, so it is not a canceller for an intercom. The TDM/MIC3 hardware reference measured no
better than the codec-agnostic delay buffer, which is why the simpler one is kept.

Rule extracted: mode and mic gain are runtime entities (select and number). Sweep them before
rebuilding anything.

## ADR-004: direction switches must not restart the stream

**Decision:** mic and speaker on/off is a pair of runtime flags read by the audio task, never a stream
restart.

**Why:** every restart went through a stop/start path where the main loop tore down sockets, I2S
handles and the ring buffer while the audio task was still inside them. That produced use-after-free
crashes with two different symbolised signatures (`lwip_recvfrom` and `RingBuffer::available`), and
the board came back from the crash either on the previous firmware slot or with a dead stream. Two
attempts failed first (a semaphore join alone, then ownership plus a join flag). What worked: no
restart, ring buffer in internal RAM owned by the task, and a generation counter so a late cleanup
never touches state the new task owns.

## ADR-005: the receiver resynchronises instead of hanging up

**Decision:** on an implausible frame header, the Home Assistant client discards bytes until it finds
a plausible header and continues. It does not raise.

**Why:** the protocol has no magic word and no CRC, so one truncated send desynchronises the stream
permanently (audio bytes read as a header: absurd lengths such as 41728). The original client treated
that as fatal, which is why calls died 6 to 20 s after starting. The plausibility rule must be strict
per message type: a loose rule accepts garbage (`type=106` passed the first version of the test).

## ADR-006: a session survives a network gap, and resumes the same call

**Decision:** the intercom session is bound to the websocket connection that created it, with a grace
window of 90 s. When the client reconnects it resumes the same call instead of starting a new one.

**Why:** the main use case is the phone, off-site, over the mobile network. Home Assistant drops any
client that fails to answer its ping for 27.5 s, and a 30 s mobile blip was ending calls. The session
must never be torn down on websocket close, and a stale cleanup must never end a newer call.

## ADR-007: the card keeps its own page awake

**Decision:** the browser card requests a screen wake lock while in a call, and re-acquires it on
`visibilitychange`.

**Why:** the card captures the microphone in an AudioWorklet but sends from the main thread. With the
screen off or the page backgrounded, the browser throttles the main thread and the uplink collapses
(measured 8.2 frames/s against a full rate of 31/s). The same throttling explains the dead hangup
button and the `No PONG received after 27.5 seconds` line: one cause, two symptoms.

## ADR-008: no camera on the gate board

**Decision:** the gate board stays audio-only. If a second camera angle is wanted, it is a separate IP
camera feeding Frigate.

**Why:** the board's camera interface shares pins with the display interface (PCLK/XCLK are switched
through the TCA9555 EXIO6), JPEG encoding on the ESP32-S3 is done in software and would compete with
the AEC that is already validated, and the board sits at -73 to -80 dBm at the gate, where adding video
to full-duplex audio invites packet loss. A camera already covers the gate through Frigate.

## ADR-009: printed parts are ASA, not ABS and not PETG

**Decision:** every printed part that lives outside is printed in **ASA**. ABS and PETG are not
acceptable for the enclosure.

**Why:** ABS degrades under UV: it yellows, chalks and loses impact strength. PETG is easy to print but
softens around 80 °C, so a dark box in the sun creeps and warps. ASA is the FDM material for outdoor
service (Tg around 105 °C, good UV and moisture resistance).

Consequences for the CAD and the print: ASA needs an enclosed printer and a warm chamber, wants a bed
around 100 to 110 °C, prints with little or no part cooling, and shrinks more than PLA, so the design
carries clearances for that. A molded ABS or PC junction box from a vendor is a different case: it is
injection molded with UV stabilisers and remains a valid option.

## ADR-010: enclosure rules for the gate

**Decision:** the enclosure is a plastic (ASA printed, or a molded ABS/PC box), never metal. The
microphone sits behind a hydrophobic membrane, the speaker grille faces **down or forward with a drip
lip** (see ADR-014: the speaker ended up on the front face), and there is a cable gland, not an open hole.

**Why:** the board already sits at -73 to -80 dBm; a metal box kills 2.4 GHz. A microphone behind a
small port with a hydrophobic membrane resists water without blocking sound, a downward-facing grille
stops water pooling in the speaker, and insects get in through anything larger than a pinhole. An
external antenna on the board's IPEX1 connector (enabled by moving an onboard 0R resistor) is worth
more for link reliability than any enclosure choice.

## ADR-011: the battery is a nice-to-have with a trap

**Decision:** the Li-ion cell stays optional, and it only earns its place if the router and the Home
Assistant host are also on battery backup.

**Why:** the cell keeps the ESP32 alive during a power cut (ETA6098 charger with power path, system
battery switch on SW1), but if the router and the Home Assistant host go down with the mains, the
device stays up with nobody to talk to, and the only thing gained is a Li-ion cell sitting in a
sun-heated box. Two further traps: reading battery voltage in Home Assistant requires soldering a 0R
resistor on GPIO1, which is the same pin as the camera HREF signal, and an OTA started while running
on battery alone can brown out mid-flash and be reverted by the bootloader.

## ADR-012: vendor CAD is referenced, not redistributed

**Decision:** the Waveshare mechanical drawing (STEP, DXF, PDF) is not committed to this repository.
The dimensions extracted from it live in `docs/dimensions.md`, with the source URL and file hash.

**Why:** this repository is public, and the vendor CAD is not ours to redistribute. Documenting the
numbers keeps the design reproducible without shipping someone else's files.

## ADR-013: this repository stays free of credentials and internal addresses

**Decision:** no keys, passwords, tokens or internal IP addresses in any tracked file. Values come from
`secrets.yaml` (untracked) or appear as placeholders.

**Why:** the repository is public. The ESPHome API encryption key and the OTA password in particular
grant access to the device to anyone who can reach it.

## ADR-014: acoustic layout - speaker forward, microphones at the back and low

**Decision:** the speaker faces the person arriving at the gate, and the microphone ports are on the
back and low side (facing down where the geometry allows), on the opposite side of the case from the
speaker.

**Why:** the microphones and the speaker were on opposite faces of the vendor's cylinder, and keeping
them far apart physically is worth more than any firmware tuning, because the echo path is direct
acoustic coupling rather than a software problem. The measured baseline is unattenuated coupling: a
tone at -13.7 dBFS on the DAC came back at -7.7 dB peak on the microphone (2026-09-19), which is why the
AEC has to work so hard. Every decibel the geometry removes is a decibel the AEC does not have to fight,
and it can be measured after the case is mounted. Water does not enter a downward-facing port by
gravity, so the acoustic decision and the rain decision point the same way.

## ADR-015: the front profile is a capsule

**Decision:** the front face is a capsule: a semicircle on top, two parallel straight sides, a
semicircle on the bottom. The speaker grille occupies the upper semicircle and the illuminated round
button sits in the middle of the straight section.

**Why:** it keeps the round language of the reference product while standing vertically at the gate, and
a round bottom sheds water better than a square corner.

**Amendment (2026-09-26) — the two open items above are closed, and neither needed the caliper.** The
straight section is **30.00 mm** (`case_h = 30.0 + case_w`), and the crown's radius is **114.06**, derived
rather than measured: `crown_r = (r_end² + crown_s²) / (2 × crown_s)`, with `r_end = case_w / 2 = 33.40`
and a sagitta `crown_s = 5.00`. So the case's width and its crown follow from the board's body diameter
alone, and that diameter came in at **57.50 by caliper** — against the DXF's 58.00 and the STEP's
57.63 × 56.54, both of which run high (`dimensions.md` keeps the comparison). The photograph is no longer
needed: the STEP carries the package and the vendor DXF carries the outline.

## ADR-016: mains conversion stays outside the printed enclosure

**Decision (confirmed 2026-09-25: 5 V is fed in directly, single stage):** the conversion to 5 V happens
outside the printed part. Power enters the case as 5 V through a sealed cable gland, or through an IP67
USB-C panel socket, and never as mains. The 12 V to 5 V buck module that the two-stage chain below put
inside the case is therefore out, and the case is modelled without it.

**Why:** a mains supply inside a sealed printed box puts 220 V and condensate in the same volume, and it
adds a permanent heat source. Heat is what actually wets an outdoor enclosure: the box warms, pushes air
out, cools, and pulls humid air back in through every gap (thermal pumping). A printed ASA part is also
not a certified mains enclosure, so putting mains inside would demand a separate compartment with
barriers, a fuse and its own glands. Keeping the supply outside removes the hazard and most of the
moisture cycle in one move.

**Settled chain (2026-09-21):** two stages, both from the shelf, because a potted 5 V mains unit is scarce
while a 12 V one is a commodity — an **IP67 potted 220 V to 12 V driver outside** the printed part (the
gate's electrical box, or strapped to the post; its own IP rating does the weatherproofing), then a
**12 V to 5 V 3 A buck module inside the case**, then a **USB-C pigtail into the board's USB-C** so the
charger path and the input protection stay as Waveshare designed them. 12 V is also the better voltage to
run over any distance between the 220 V point and the gate, which settles the cable loss before it starts.
Parts, sizes and the power budget: `hardware/bom.md`. **Adopted 2026-09-25:** the single stage — a
certified 5 V supply outside (its own IP65 box, or the gate's own 5 V point), 5 V through the gland —
trades one more enclosure for one fewer part and needs the 5 V point close enough that the run does not
sag. It also deletes the buck module, its heat and its connector from inside the case, which is space the
unit now uses.

## ADR-017: moisture strategy - sealed, vented, coated

**Decision:** the case is sealed at every intentional opening and the moisture strategy has three layers:
a breathable membrane vent to equalise pressure, hydrophobic acoustic membranes over the microphone ports
and behind the speaker grille, and conformal coating on the board. Outer walls 3 mm with four or more
perimeters, a smooth gasket land, silicone gasket at about 30 percent compression, and stainless A2
fasteners into brass inserts. The target is rain and splash, not immersion: IP67 is not claimed for an FDM
part.

**Why:** the failure mode outdoors is not the rain that lands on the box, it is thermal pumping. The box
heats in the sun, expels air, then cools and pulls humid air back in through every gap, once per day,
forever. The vent removes the pressure differential that drives that cycle; the hydrophobic membranes keep
water out of the two acoustic paths without blocking sound; the coating is the insurance for the day the
first two are defeated. Layer lines are capillary paths, so wall thickness, perimeters and a smooth gasket
land matter as much as the gasket itself. Acetone smoothing works on ASA but is less predictable than a 2K
clear coat or a silicone spray, so the sealing step is specified as a coating.

**Amendment (2026-09-26):** the joint's gasket is drawn now, as its own part — a **1.70 mm wide** ring of
closed-cell silicone foam, **1.00 mm** free and squeezed to **0.70** (the 30 percent above), lying flat on
the lap's shoulder. Its dimensions, its seat and the boolean that proves them are in ADR-024's "The ring
itself". The **vent** is cut too: a Ø4.00 hole through the case's -X wall, at mid-height on that side, with
its membrane stuck over it — its position and the reasons for it are ADR-026.

## ADR-018: button above, speaker grille below (reverses the front face of ADR-015)

**Decision:** on the front face of the capsule the illuminated button sits in the upper half and the
speaker grille in the lower half. ADR-015 had the grille in the upper semicircle with the button in the
middle of the straight section; this record replaces that arrangement. Everything else in ADR-015 (a
capsule profile, a round bottom that sheds water) stands.

**Why:** it is the arrangement chosen from the concept render, and it is the better one for a person
standing at the gate. The button lands at hand height, and its lit ring is the element at eye level,
which is what someone arriving after dark looks for; the perforated field below reads unmistakably as a
speaker. ADR-014 is untouched by the swap — the microphones stay on the back and low side, so speaker and
microphones remain on opposite faces of the case, which is the part of that decision that matters for the
echo path.

**Consequences, all of them for the print:**

- **Water.** The front face is a convex vertical capsule, so rain runs down it, and with the grille in the
  lower half the water now reaches the grille. The grille is therefore a recessed field of holes behind a
  drip lip, holes drilled with a downward angle, with the hydrophobic membrane behind it (ADR-017). A
  flat perforated field flush with the lower face is not acceptable.
- **Acoustic separation.** The speaker moved lower and forward while the microphones stay high at the back,
  so the direct coupling path changed. The pre-case baseline was a tone at -13.7 dBFS on the DAC coming
  back at -7.7 dB peak on the microphone (2026-09-19). The same measurement has to be repeated with the
  case mounted and the number recorded in F4; if the geometry made the AEC's job harder, the grille goes
  back up and this ADR is superseded.
- **The button is an external panel switch, wired, not a plunger.** The front button is a bought 22 mm
  metal momentary switch (red, IP65, LED rated 3-9 V, so it runs off 5 V with its own built-in
  resistor), mounted through the case wall and wired to the board inside the same case. The tactile
  switches on the PCB are left alone and their positions stop mattering. A plunger acting on the
  board's BOOT switch was rejected: it would tie the board's position to the button's position and add a
  mechanism for a part that already exists as a panel item with its own IP65 gasket. Wiring: the
  contacts go between GPIO0 and GND, which is what the on-board BOOT switch does, so the firmware keeps
  its gate-bell input unchanged and the existing pull-up holds the line high when released. GPIO0 is a
  strapping pin, so the loop stays short and inside the case, with a 1 k series resistor and 100 nF to
  GND at the board end against contact noise; a long cable to a remote button would risk a boot into
  download mode and is not part of this design. The LED takes the same 5 V rail that feeds the board.
  The cutout is 22 mm; the head diameter and the body depth behind the panel come from the part, and the
  seller's listing carries no drawing, so both are measured on arrival.
- **The cutout needs a flat land, and the front face is convex.** A panel switch seals with its gasket
  compressed between the nut and a *flat* panel, so the capsule's curved face cannot be the sealing
  surface: the geometry carries a spot-faced flat boss around the Ø22 mm cutout, flush or slightly
  recessed, with enough diameter for the switch gasket and a smooth surface (layer lines are leak paths,
  ADR-017). The boss also gives the water running down the face something to drip from instead of
  creeping into the cutout. Silicon grease or a smear of neutral silicone on the gasket is the
  belt-and-braces step at assembly.
- **Why the button above the grille pays off twice.** The upper half of the capsule holds the button,
  the lower half holds the speaker chamber, so the ~30 mm the switch needs behind the panel sits in a
  volume the speaker would otherwise have contested. The ADR-015 arrangement (grille up) would have put
  the speaker chamber exactly where the switch body has to go.
- **The LED ring.** The board's seven RGB LEDs are on the solder side, so whichever way the board is
  mounted they face the inside of the case. The plan is the board lying flat at the bottom with the
  components down — which is also what the acoustic ports require (measured: they open on the component
  side) — leaving the LED ring facing up, where it can serve as a status light behind the button or a
  diffuser.
- **The microphone ports follow the board, not the face.** With the board flat and its components down,
  both acoustic ports point at the floor: two Ø3 to Ø4 mm openings at r = 26.8 mm and ±47.2° / 132.8° in
  the board's own frame (see `docs/dimensions.md`), each behind its own hydrophobic membrane.

## ADR-019: the joint is two screws into inserts on pillars off the back plate

**SUPERSEDED IN PART by ADR-031 (2026-10-04): the inserts are no longer on pillars off the back plate —
they are pressed into gussets grown off the cavity's side walls. The screw, its counterbore, the boss on
the lid's inner face, the M3 x 12 and the pair's position at (18, 67) are all unchanged; the pillar, and
the 47 mm of it that stood between the insert and the plate, are out. What follows is the record of the
joint as it was built.**

**Decision:** the lid is held to the base by **two M3 x 12 socket head cap screws** (ISO 4762, head
Ø5.5 x 3.0, stainless A2 into the brass inserts of ADR-017), in the corridor between the unit and the
panel switch, at (18, 67) and its mirror on X. Each screw enters through a **cylindrical counterbore**
cut from the crown's own surface so its head ends up inside the case with nothing standing proud, then
crosses a boss on the lid's inner face (the surface the head clamps) and bites **all 5 mm** of the
insert pressed into a **round pillar** that stands off the back plate to the joint plane. The
countersunk head of the first proposal and the rib of the second are gone.

**Why:** the countersunk head needs 1.65 mm of depth and the wall under the crown is 3.04 mm, so a
counterbore deep enough to bury a head always broke through, and the rib — which had to run out to the
side wall for want of standing room — cannot exist in that corridor, where the cavity's wall is
12.6 mm away. The socket head is 3.0 mm tall: too tall for the wall, so the lid carries a boss exactly
there and the head clamps that instead of the wall. The pillar is what the rib was trying to be: it
carries the insert, and since the base prints lying on its back plate, the pillar is a **vertical
column** with no support under it and a vertical blind hole, not a ceiling to bridge. Measured
clearances, all from the model: 1.4 mm to the switch's Ø30 flange (the reason the pair moved off
(17, 68), where it came out as contact), 3.0 mm to the unit's collar, 5.1 mm to the switch's body,
8.9 mm to the cavity's side wall. `fitcheck_joint` proves the whole arrangement by boolean, and
`-D 'fc="screw"'` / `-D 'fc="neighbours"'` splits it when the answer is not empty.

## ADR-020: the collar is 1.25 mm of wall and 5 mm tall

**SUPERSEDED by ADR-029 (2026-09-28): the collar is out.** On the first print of the base the ring's bore was
too tight to take the unit at all — 0.20 mm a side, and a closed 360 degree hoop has nothing to give — and the
back end of the unit is located by a second band of arcs now. What follows is the record of how the ring was
dimensioned and why; none of it survives in the model.

**Decision:** the ring on the floor that locates the unit's body is **cut material as of review 3**,
not a drawing. The bore is **Ø57.9** (the unit plus 0.2 mm a side, rule 6's tight fit), the wall is
**1.25 mm** and it stands **5.00 mm** off the floor, so its outer Ø60.4 still overlaps the cavity's wall by
0.2 mm and fuses with it. *Amended 2026-09-26: the bore was Ø58.4 and the wall 1.00 mm against a Ø58 unit.
The caliper put the unit's body at **Ø57.5** (`docs/dimensions.md`), so the gap around it is 1.25 mm and
the collar spends the whole of it. Ø60.4 outside is unchanged, so the fusion is too.*

**Why:** none of those numbers are free. The cavity's inner radius is `cav_x = 30.0` and the unit is Ø57.5
by caliper, so the gap between them is **1.25 mm** all the way round — and the previous Ø63 collar (2.3 mm
of wall) had nowhere to go: it would have cut into the wall. The collar spends the gap instead. The outer
0.2 mm landing inside the wall is deliberate: it is what backs the ring, which standing free would be the
thinnest unsupported thing in the case (rule 3 asks for 1.2). The height is what makes the fit
"hold": of the 5.00 mm, 1.80 is the gap behind the unit and 3.20 is skirt over the unit's own body, which
drops the unit's free cocking from atan(0.4/1.75) = 12.9° to atan(0.4/3.2) = 7.1°. `fitcheck_joint` covers
it as `-D 'fc="collar"'`: the collar against the unit, empty. It bites `unit_collar()`, not `base()`,
because the collar is part of `base()`: against the base that check would meet by construction and say
nothing. `m4_heads()` rides along in it, which is what keeps the heads off the ring if either moves. (The
M4 pockets themselves are cut as of ADR-021's amendment; before that a head met the whole back plate.)

**Superseded in part** by ADR-021: this ADR first carried a **Ø9 window** on each M4 axis, cut into the
ring, because the wall screws sat on the 26 mm radius around the unit's axis and an Ø8 head reaches r = 30,
past the bore's 29.2 — a plain ring would have stood on the screw heads. ADR-021 moved the screws to 24 and
72, and 24 is 9 mm off that axis, far inside the bore, so the windows were retired and the ring is plain
again. Everything else above stands.

## ADR-021: the two wall screws sit a quarter up and a quarter down the case

**Decision:** the two M4 that hold the base to the masonry go on the **centre line**, at **a quarter of the
case's height above the floor and a quarter of it below the top** — z = 24 and z = 72 of 96 — instead of on
the 26 mm radius around the unit's axis at 90° and 270° (z = 7 and z = 59).

**Why:** the user asked for the quarter points, and the geometry agrees with him. In X nothing moved: the
old 26 mm radius at 90°/270° already landed on x = 0, so only Z changed. What the change buys is symmetry —
the pair is now centred on the case's own centre (48), so the hanging weight arrives at the screws as shear
instead of loading one of them with a moment. The earlier note had already made that argument for 7 and 59,
and 7 and 59 only half kept it: their midpoint sat at 33, below the mass. It also cleans up two joints. At
24 the screw is 9 mm off the unit's axis, well inside the collar's bore at 29.2, so the collar's Ø9 windows
could go (ADR-020). At 72 it is above the unit (whose top edge is at 62) and below the switch's body (which
ends at y = 31.2), so that screw can be driven with the unit already installed. The one thing that gets
worse is the spacing: 48 mm between the screws instead of 52, so slightly less leverage against the case
tipping off its own top edge. That is the price of the symmetry and it is small; the flat contact with the
wall and the mortar take the rest.

Both still sit in a 1.5 mm pocket in the plate's inner face — the gap behind the unit is 1.80 mm, which is
why the pocket has to stay shallow — and both still clear the unit's three standoffs. The pockets
themselves are still markers: cutting them is part of "the rest of the joint" in `cad/README.md`.

**Amendment (2026-09-26):** they are **cut** now (`m4_pockets()` in `cad/case.scad`). They were the last cut
item with a decision already behind it, so they went in with the gland (ADR-025); nothing about the decision
changed. The cut is exactly what the numbers above describe, taken from the plate's inner face: Ø8.00 × 1.50
for the head, then Ø4.50 on through the 3.40 of plate, which leaves **1.90 mm** of it (rule 3). `probe_m4`
is what proves both holes are open end to end, and the measured STL reads the mouth at r = 4.00, its floor
1.50 behind it, and nothing but the hole at the plate's back face. The two pockets and their holes took
**210.7 mm³** off the base (65536.06 → 65325.39 mm³).

## ADR-022: the microphone ports go through the back plate, low and behind the microphones

**Decision:** the case carries **two Ø4 mm ports** through the **back plate**, at the microphones' own
positions — `r = 26.83 mm` at `±47.2° / 132.8°` in the board's frame (ADR-018's measured numbers), which
puts both of them at **z = 17.3** in the case, one either side of x = 0: low, and behind the microphones.
On the outside each port gets a **Ø9 × 1 mm spot face** as the flat seat for a stick-on hydrophobic
membrane (ADR-017). `probe_mic` proves both are open through the plate's 3 mm.

**Why:** this retires the "nothing goes through the back plate" reading that ADR-010, ADR-017 and the
roadmap had settled on, and the reason is acoustic rather than geometric. With the case closed except for
the front grille, the microphones' only air path was the same Ø44 field the speaker fires through — a
direct coupling path between speaker and microphone, which is the one thing ADR-014 exists to prevent
(the measured pre-case baseline is a tone at -13.7 dBFS on the DAC coming back at -7.7 dB peak on the
microphone). The ports open into the 1.80 mm gap behind the unit instead, which is the volume the
microphones actually breathe: the unit's own back cover carries eight Ø1 holes at r = 5.5 to 8.9 between
that gap and its chamber. Two Ø4 holes are also far more open area than the eight Ø1 holes they feed, so
they are not the restriction in the path, and at z = 17.3 they sit as far from the speaker as this case
goes. The spot face is what makes the membrane work: it gives it a flat, flush seat 9 mm across and keeps
its edge out of the way of anything that slides past.

**Open, and it is a mounting question rather than a CAD one:** these two ports face the wall the case is
fixed to, so bedding the plate flat on mortar buries them and the microphones fall back to listening
through the grille. The plate has to stand a few millimetres off the wall in front of them, or that area
has to stay clear — the two M4 at x = 0, z = 24.2 and 72.6 leave the lower corners free, so the fix can live
there. Steps 3 and 5 (gland, vent, mounting ears) should settle it before anything is printed.

**Superseded by ADR-023:** the answer to that open question is that the plate is *not* going to stand
off the wall, and the ports moved to the bottom of the case as thin slots. The mounting ears of step 5 were
dropped the same way, on review: the two M4 through the back plate ARE the fixing, and nothing is added to
the sides (ADR-027).

## ADR-023: the microphone ports go through the bottom of the case, as thin slots

**Decision:** the two microphone ports are cut through the **bottom** of the base, close behind the unit,
as **slots of 1.20 × 8.00 mm** instead of holes — one each side at the microphones' own x (±18.23 mm),
running along the case's depth from y = 46.30 to 54.30, with `mic_slot_top` (13.00) taking each cut past
the collar's bore so it is a through opening in the shell **and** the collar. Nothing else is cut: the
**Ø9 × 1 mm spot face** that ADR-022 carried as the membrane's land is **out** (see the amendment below),
and the membrane is stuck straight on the bottom's curve. `probe_mic` proves the path rather than the
mouth: a rod narrower and shorter than the slot, running from outside the wall to inside the cavity,
must intersect the base in nothing.

**Why:** ADR-022 moved the ports to the back plate and left one question open, and the answer kills the
back plate. The plate is bedded flat on the gate post (ADR-010, ADR-021), so a port there breathes
mortar, not air, and the microphones fall back to listening through the speaker's grille — the direct
coupling ADR-014 exists to prevent. ADR-014 also asked for the bottom from the start ("on the back and
low side, facing down where the geometry allows"). The shape is a printing decision as much as a water
one: the base prints lying on its back plate, so the case's depth is the printer's Z, and a slot running
along that depth prints as a **vertical slit** with the same cross section at every layer, nothing to
bridge and nothing to support. A round hole through the bottom, or a slot lying across the width, is a
horizontal tunnel in the print whose ceiling is a bridge (8.00 mm for the slot here against rule 4's
limit of 10). The slot is 1.20 wide and not 0.90 because below about 0.90 the two lines that form its
walls meet and it prints shut. Two slots are 19.2 mm² of open area against the 6.3 mm² of the eight Ø1
holes they feed, so the slots are not the restriction in the path — ADR-022's acoustics hold unchanged —
and 19.2 mm² of slit facing the ground is exposed to less rain than 25 mm² of Ø4 hole facing a wall. The
seal is still the membrane, not the geometry: capillary pressure holds a film in a 1.20 mm slot against
only 12 mm of water head, and the material there is 4.70 mm thick.

**Accepted, and it is the price of cutting through the bottom:** the wall is 4.70 mm at that x, not 3.00,
because the slot passes through the collar as well as the shell; the two slots cut a 1.20 mm notch on
each side of the collar's ring, so the ring is no longer closed, though it still locates the Ø57.5 unit
and each of its arcs still holds on the 0.20 mm of outer face that fuses into the cavity's wall. The
slot's centre along the depth (`mic_slot_cy`, 50.30) also decides how deep into the unit's own volume it
reaches, and the answer is deliberate: 0.80 mm of it opens straight into the gap behind the unit, whose
back face is at 53.50, so the microphones keep a path even if the unit ends up tight against the collar.
Those three numbers were 50.00, 53.20 and a Ø58 unit until the caliper of 2026-09-26 moved the depth chain
by 0.30 mm (`docs/dimensions.md`).

*The collar is out as of 2026-09-28 (ADR-029), so the price named above is gone with it: the slot is a plain
prism through the wall now, and the annulus around the unit reaches the gap behind it outright instead of
through the collar's 0.20 mm clearance. `mic_slot_top` (13.0) and `mic_slot_cy` (50.30) are unchanged — the
first still clears the cavity's own surface at that x, the second is what puts the slot's last 0.80 mm in the
gap — and `probe_mic` still proves both open.*

**Amended in the same review — the Ø9 × 1 mm spot face is out, on the user's call.** It was the
membrane's flat land, carried over from ADR-022 without asking whether the bottom needed one, and it
bought nothing: the membrane is an adhesive-backed patch and the bottom is a Ø66.8 cylinder, so a 9 mm
patch follows that curve to within 0.31 mm, and there is nothing at the bottom of a case on a post to
peel its edge — which was the second half of ADR-022's reason for the seat on the flat plate. Two
things come out of dropping it. The cut is a plain prism along the depth, which mirrors on X by
construction. And the seat had gone in **wrong on one side**, which is how the review caught it: a
recess on one port and none on the other. `mic_face_cut` built the seat as a cylinder along the
surface's own normal, and `mic_points` mirrors the slot on X without mirroring that rotation — so the
left seat was cut 67 degrees off its normal and left almost no mark, and the right one was the only one
that read. The lesson for this file: anything whose cut is a **rotation** needs the mirror inside the
loop, and the slot's prism needs nothing.

**The patch is drawn (2026-09-26), and nothing about it is cut:** `mic_membrane_marker()` puts the two
membranes in the review view as a **5.00 × 12.00** patch, 0.30 thick, **0.30 mm layer of the case's own
surface** rather than a flat tile — so what the drawing shows is the curve the membrane has to conform to
and not a disc floating over a cylinder. That is the whole content of this item: "the membranes' seats"
asked for a seat, and ADR-023's answer is that there is none to cut. Measured on the render: y = 44.30 to
56.30 (its 12.00 along the depth), x from 15.73 to 20.73 each side, z following the bottom's arc from 3.60
to 7.21, 21.5 mm³ each.

## ADR-024: the joint is a half-lap - the lid's lip into the base's recess

**Decision (user's call, 2026-09-26):** the two halves no longer meet on a flat plane. The **lid** carries
a **lip** -- the outer `lap_step` (1.50 mm) of its shell, carried `lap_d` (3.00 mm) back past the joint
plane and **flush** with the case's own surface (`lap_proud` 0.00, amended the same day: see below) -- and
the **base** carries the matching **recess**: the outer `lap_step + lap_gap` (1.70 mm) of its wall removed
over the same 3.00 mm, leaving it a **1.70 mm rim** that the lip slides over with **0.20 mm** of radial
clearance all
the way round the contour. The joint plane stays at **y = 8.00**, where the M3 x 12 of ADR-019 already
were: at 27.5 a screw through the front wall would have needed M3 x 30 and 17 mm of plastic to cross, and
the screws themselves are unchanged, on the user's call. `fitcheck_pair` is the boolean that proves the
lap: the two parts against each other must be empty, with one `eps` either side of the joint plane taken
out of the test because the plane itself is a contact and not an interference -- CGAL returns a
zero-thickness sheet there (0.000 mm³, 62.51 mm wide, 0.000 mm deep, measured on the STL).

**Why a lap and not a tongue and groove:** a ring standing out of one face into a groove in the other
needs the groove to have **two** walls -- 1.20 + 1.40 + 1.20 = 3.80 mm, against a 3.40 mm shell -- and the
wall cannot be thickened inwards at the joint, because at y = 8 the Ø57.5 unit is 1.25 mm from the cavity
(ADR-020) and there is no material to borrow. The half-lap **spends** the wall instead of adding to it and
leaves both remaining walls above rule 3's 1.20 mm. It also costs **no local step**: the 0.40 mm a side the
shell grew (3.00 to 3.40, amended below) is uniform over the whole case -- 66.80 x 96.80 everywhere --
which is not what a flange would cost.

**Why on the lid and not on the base:** the first proposal had the base's skirt lapping over the lid's
rim, and it does not survive the crown. The lap's forward end at `lap_d` 3.00 lands at y = 5.00, which is
exactly where the crown's own surface reaches the case's full 33 mm radius; the lid's shell between the
crown and the cut would thin to a **feather** there. Carrying the lip on the lid puts the whole lap behind
the joint plane, in the case's straight-sided part, and the crown is never involved.

**Amended the same day -- the lip is flush, not proud:** the first cut stood the lip `lap_proud` 0.40 mm
clear of the case's surface, and that 0.40 mm *was* the design: a **drip shadow**, an overhang whose edge
throws the film of water 1.90 mm outboard of the mouth of the joint's 0.20 mm gap. The user's call,
2026-09-26, was that it reads as a **ridge** on the outside ("fica feio"), and the price is paid by the
wall: **3.00 to 3.40**, so the case grew 0.8 mm across and the lip's own outer surface **is** the case's
surface. Nothing protrudes and nothing steps; the parting line is the only thing to see there. What that
gives up is the shadow -- water now runs straight across the parting line instead of falling off an
overhang -- and what is left to stop it is the mouth itself (0.20 mm, which water enters by capillary
action), the whole 3.00 mm of lap to climb, and the shoulder at the joint plane, where the foam ring goes
(ADR-017). A 0.40 mm deep **rain groove** on the parting line would buy the break back without a ridge; it
is not cut because it was not asked for.
The shell grew rather than the lip shrinking for a second reason: the recess spends 1.70 mm of the base's
wall, and against a 3.00 mm shell that left a **1.30 mm** rim -- legal, but the narrowest thing in the
design and the part that locates the two halves. At 3.40 the rim is **1.70 mm**.

**Why there is no gasket groove, yet:** the lap moves the sealing face off the dome's brim and onto the
1.70 mm annulus at the joint plane, and 1.70 mm is still too narrow to groove -- a 1.00 mm groove would
leave 0.35 mm of wall on each side. The foam ring therefore lies **flat** on that shoulder and the two
screws squeeze it. Cutting a groove is deferred, not dropped; if it comes back it comes back with a wider
shoulder, which means a thinner lip.

**The ring itself (2026-09-26):** it is drawn now, as its own part (`gasket()` in `cad/case.scad`,
`part="gasket"` for the STL, `make gasket`): **1.70 mm wide** — its outer edge is the rim's own outer
edge, its inner edge the case's inner surface, so the lap's 0.20 mm is all that separates it from the lip
— and **1.00 mm** of closed-cell silicone foam, squeezed **30 percent** as ADR-017 asks. That squeeze is
what sets the joint's **closed gap**: **0.70 mm**, i.e. how far the lid ends up forward of the printed
joint plane once the two screws are home, with the 3.00 mm lip reaching **2.30 mm** into the recess and
nothing bottoming out. It is a separate part and belongs to neither half, so it is unioned into nothing.

**Amendment (2026-09-26, the user's call): it is printed in TPU 95A, not cut from foam.** A printed ring
springs back instead of taking a set, it is the one material already on the shelf, and the same geometry
serves: 1.70 wide, 1.00 thick, squeezed to 0.70. Print it **soft** — the 1.70 mm of ring fits about two
0.45 mm lines, so 2 walls, 10 to 20 % infill (none at all leaves a soft hollow tube) and 2 top/bottom layers
so the two seal faces come out solid — because the 30 % squeeze is the design's own number (ADR-017)
and the material has to deliver it, not the other way round: a *solid* TPU ring would need far more force
to reach 30 % than two M3 screws can put into printed ASA. If a solid print is wanted, `gasket_t` drops to
0.80 and the squeeze becomes 12 percent. Proved the same way as before, by
`fitcheck_gasket`: the ring against both halves **at that closed gap** (the lid lifted 0.70, because in
the dry position the ring's space is the lid's own material) must be empty, and it is. Measured on the
STL: 63.40 × 93.40 outside, 60.00 × 90.00 inside, 1.00 thick, 431.45 mm³ — the contour's 1.70 mm band to
the last hundredth of a cubic millimetre.

**Accepted:** the base's rim is a **1.70 mm** ring inside the lap, and it only has to locate the two parts,
not to hold them. The lip adds **no** step on the outside any more (it did, 0.40 mm, until the amendment
above): with both parts at 3.40 mm through the band, neither part's print gains a sideways step at all.
Neither part pays for the lap with support or a bridge either: through the band the base's wall goes from
3.40 to 1.70 mm and the lid's from 3.40 to 1.50, so both cross sections only lose material as the print
rises. The front wall is a separate thickness (`wall_front`, 3.00) and did not grow -- see the lesson
below.

**Lesson for this file -- a thicker wall can bury a seat, and only the boolean says so:** the shell's
growth to 3.40 was written first as a single `wall` number, and that took the **front** wall with it. The
crown's inner surface then receded from y = 6.16 to 6.50 at the unit's rim (26), which is **behind** the
unit's own seat plane at 6.25 -- so the seat's flat face, the surface the unit's disc rests on, ended up
buried inside the wall, and `fitcheck` (the unit against the printed parts) is the only thing that said
so: 1.30 mm³ of interference, 0.05 mm deep, in a ring at the seat's rim. The fix is `wall_front`, a second
thickness that holds the front at 3.00 and leaves the whole front's geometry -- the grille field's depth,
the button's lands, the seat -- where it was designed. A wall thickness is not one number in a case that is
a shell **and** a face.

**Lesson for this file (it cost a full boolean round trip to find):** `prism_xz()` is a module that takes
its 2D profile as a **child**. Called with no child inside an `intersection()`, it contributes **nothing**
and silently swallows the whole intersection. The first `joint_recess_cut()` did exactly that, the recess
came out uncut, and `fitcheck_pair` reported 1181 mm³ of interference in the band. **An empty cut is not
an error in OpenSCAD**: it is geometry that quietly does not happen. Check every prism for its profile.

## ADR-025: the cable gland goes through the TOP, on a boss, above the USB-C

**Decision (2026-09-26, the user's):** the 5 V entry is a **PG7 through the top of the case**, on the
unit's own axis — (x = 0, y = 29.85), the unit's centre in the depth — standing on a **raised boss**, so
that the gland's gasket and its locknut both land on flat faces. The vent stays on the bottom or on a
side; the back plate still carries nothing at all. **That placement was moved on 2026-09-29: the gland now
sits at y = 40.44, 10.59 mm further back — see ADR-030, which also corrects this ADR's own units on the
tail's angle.**

**Why the top, and not the bottom or a side as the earlier rounds had it:** the unit's own USB-C is at the
unit's top edge, pointing **up** (its centre in the vendor's frame is (0, −24.60), which in the case's
frame is z = 58.30, and the unit's top edge is at 62.15). A gland directly above it is the shortest route
the pigtail can take, and the only one that reaches the port without a bend: put the gland on the bottom
and the cable has to climb the whole cavity and then turn through 90 degrees into a port that faces the
way it came. Nothing else has to move for it — the free space above the unit is where the cable route
already lived — and the boss takes 22 mm of the top, 3 mm above the crown of the top's own cylinder.

**What it costs, and why it is paid there:** the top is a cylinder — the capsule's upper semicircle,
radius 33.4, straight along the depth and curved in X by 0.9 mm over ±9 — so a gland cannot sit on it,
hence the boss: **Ø22**, 3.00 mm proud, its root buried at z = 94 where the shell's own surface is still
12.93 mm wide, so its sides emerge from the shell and leave **no ledge** around it. And because both parts
print lying down, the case's Z is the printer's Y: **the gland's axis lies in the bed plane**, and three
consequences follow, each answered by the shape the print wants rather than by support material:

- the boss's own back side faces straight down — a 90 degree overhang — so the boss carries a **tail** on
  its +Y side, its sides tangent to the boss's circle at 40 degrees. It is the same teardrop the microphone
  slots' walls get, and it puts the worst surface 40 degrees off vertical against rule 4's 45;
- the hole's roof would be a **12.50 mm bridge** where rule 4 allows 10, so from 1.20 mm below the flat the
  hole becomes a teardrop whose point reaches Ø17.7. The first 1.20 mm stays **round**, deliberately: that
  is the face the gland's Ø16 washer seals on, and a teardrop opening under a circular washer is a leak
  path, not a compromise. This is the case's one knowing concession to rule 4: 2.5 mm of span over 1.2 mm
  of depth, on a face that carries no load, and it is named in the parameters;
- the locknut needs a flat seat, and the cavity's ceiling is a Ø30 cylinder **arching up** over the hole
  (93.40 at the centre, 92.17 over the seat's rim) — so there is nothing to spot-face: over the arch there
  is no material to cut. The seat is a **pad** instead, a teardrop (Ø17, its point on +Y) filling the arch
  and stopping at 92.15. It leaves the nut a 2.25 mm ring to bear on, and **7.65 mm of material through
  the hole** — the boss's 3, the shell's 3.4 and the ceiling's rise — which is what the PG7's 6 mm of
  thread wants.

**Proved by boolean, not by eye:** `probe_gland` runs a rod 1 mm narrower than the hole, and 0.5 mm
narrower than its teardrop, from above the flat to below the nut's pad. Empty against the base is the
statement that flat, boss, shell, ceiling and pad make **one hole** rather than a pocket in any of them.
The measured STL agrees with the drawing: the base now reaches **z = 99.80**, the hole at its flat reads
r = 6.25 inside an edge at 11.00 with the tail out to 14.36, and the pad's seat reads 6.25 to 8.50 with
its own tail to 12.02.

**Amendment (2026-09-26 — this voids the two paragraphs above as written until now):** the hole was **not**
open at the top, and the user found it by looking at the part: *"a parte de cima do cilindro está
fechada"*. The round collar's cut was `translate([0, gland_cy, gland_flat_z + 1]) cylinder(...)`, and
`cylinder()` grows toward **+Z from its own origin** — so the collar was cut *upward*, outside the case:
the hole stopped at z = 98.60 and the **1.20 mm above it, the very face the gland's washer seals on, stayed
solid**. `probe_gland` reported empty all along because the probe's collar piece had the same mistake and
never entered that band either: an empty probe that does not span the feature it claims to test proves
nothing. Both are now placed by their **lower** end, so the cut runs 98.60 to 101.80 and the probe 98.40
to 101.80. The wrong paragraph above was itself written from a measurement read against its *label*
instead of its numbers — the radius list at the flat was `[11.0, 14.36]`, with no 6.25 in it, while
inviting the reader to see one.

**Measured after the fix, by ray-casting the exported STL along the gland's own axis (x = 0, y = 29.85 — the
axis has been at 40.44 since ADR-030, and every number here travels with it, unchanged):**
at z = 99.50, 0.30 under the flat, the axis is in the **void** — the ray crosses the hole's wall at 6.25
and the boss's outer wall at 11.00 — where that same point was in **material** before the fix. 8.00 out at
the same height is still material (one crossing, at 11.00), which is the pair that keeps the first result
from being "a hole in nothing". The axis is void again at 98.30 and 96.40, and the pad's ring is material
at 92.30. The base's volume fell **147.16 mm³** (65282.93 → 65135.77) — the collar, π × 6.25² × 1.20 =
147.26 by hand.

**Amendment (2026-09-28, the user's call — this corrects the second bullet above; superseded later the same
day, see the ramp amendment below):** the collar's 1.20 mm
was left **round**, and on a print run that is the one place the teardrop was not doing its job: a round
bore's roof is a **ceiling**, and over that band the printer was left to bridge it alone — the hole's only
bend of rule 4's 10 mm limit. The teardrop now runs into the band as well, with its tip **capped at
`gland_cap = 6.80`** from the hole's axis: the flanks keep their 45 degrees and the roof finishes on a
flat, so the tent reaches the flat and the washer keeps **1.20 mm of land** (8.00 is where its Ø16 ends) —
*"essa ponta só ajuda se ela nascer junto com a superfície e subir até o topo do cilindro, para as camadas
iniciais não precisarem de suporte"*. The cap is what settles the two requirements against each other: a
full tent's tip reaches r / cos 45 = **8.84**, which is 0.84 mm **past** the washer — the leak path that
kept the band round in the first place. The hole's **section** does not change: Ø12.50 round over its whole
length, which is what the PG7's thread passes and what the washer's seat surrounds. Only the roof moved,
and `teardrop_capped_xy()` is the shape that does it.

**Measured on the exported STL, by ray-casting along +Y (the print's vertical for this run) at z = 99.50,
0.30 under the flat:** the roof over the hole's axis sits at **6.800** from it, and is still 6.800 at
x = ±1.50 — the flat cap, **4.08 mm** wide — then **5.839** at x = 3.00 and **3.748** at x = 5.00: the 45
degree flanks, and then the bore's own crown. A round collar would read **6.25** on the axis and a full
tent **8.84**, so the three numbers say which of the three shapes is in the part. At z = 98.00, 0.60 mm
below the band, the axis reads **8.839**: the full tent still runs from there into the cavity, and the cap
is a 1.20 mm band at the mouth and nothing more. `probe_gland` was extended with the cut — its tent piece
now runs the whole hole to the flat, capped 1 mm inside the cut's own cap, so the band that used to be
left to bridge is a band the probe tests (the 2026-09-26 lesson, paid for twice). The base's volume falls
**5.10 mm³** (66109.60 → 66104.50).

**Amendment (2026-09-28, later the same day, the user's call again — the cap above is out, and this is
what replaced it):** the cap fixed the band's *shape* and not its *slope*. A roof that is flat in **Y** is a
**bridge** wherever it stands — the printer has to cross the void in one layer — and the user read it off
the part: *"o início da teardrop já exige um suporte, esse início deveria começar rente à superfície e ir
saindo até a superfície superior"*, and asked whether the hole could be **moved** so that the teardrop's
beginning started at the print plate. **It cannot, and the numbers are why:** the plate *is* the back
plate's own outer face (y = 58.70); the tent's beginning — where its flanks leave the bore — sits
r × cos 45 = **4.42 mm above the hole's axis** (y = 25.43, which is 33.27 mm above the plate), so putting
that beginning on the plate would need the hole's axis at y = **63.12**, i.e. **4.42 mm behind the back
plate** and outside the case; and at the deepest position the geometry allows at all (the bore grazing the
cavity's floor, axis at y = 49.05) the beginning is still **14.07 mm** above the plate. Moving the hole
would also break the reason it is on the top in the first place (the paragraph above: straight above the
USB-C). Support is not a question of *where* the hole sits; it is a question of the *angle* of the roof's
faces.

**So the cap is replaced by a 45 degree ramp.** The teardrop's tip is cut by a plane at 45 degrees **in Z**
— the hole's own axis, which is horizontal in the print — passing through the point where the roof stands
`gland_cap = 6.80` over the axis **at the flat's own face**. Going inward the roof rises a millimetre per
millimetre: from 6.80 at z = 99.80 to the tent's full apex of 8.84 at z = **97.76**, and from there in the
tent is whole again. It is the same surface the tent's flanks already have, in the other direction, and it
does the one thing the cap could not: as the print rises, this cut only ever **removes** material — the void
grows toward the mouth by a millimetre of Z for every millimetre of height — so **no layer of the roof is
ever laid over air**, not even for 4 mm. The mouth's face still stands at **6.80** over the axis, so the
Ø16 washer still keeps its **1.20 mm of land**, and the hole's section is unchanged: Ø12.50 round over its
whole length. `gland_roof_ramp()` is the shape now; `teardrop_capped_xy()` went out with the cap it existed
for.

**Measured on the exported STL, rays along +Y (the print's vertical for this run),** roof height over the
axis at x = 0: **6.810** at z = 99.79 (the flat's own face — 1.19 mm of land for the washer), **7.100** at
99.50, **8.000** at 98.60, **8.600** at 98.00, **8.839** at 97.70. The differences are 0.29, 0.90 and
0.60 mm over the same Z, i.e. a slope of **1.000** — the ramp, at exactly 45 degrees — and from 97.76 in,
the full tent's own tip.

**And the faces themselves, which is what a slicer looks at.** Over the hole's roof (z 92.00–99.95,
x ±10, y 19.5–30.5), auditing every face that hangs in this run by |n_y| — 1.0000 is a ceiling, 0.7071 is
exactly 45 degrees:
- the **cap** version has **4 faces flatter than 45 degrees**, the worst at |n_y| = **1.0000**: two triangles
  of pure ceiling at y = 23.05, 6.80 over the axis, at x = ±0.68, z = 99.00 and 99.40 — the 4.08 mm of flat
  the user pointed at;
- the **ramp** version has **2**, both at |n_y| = **0.7127** (44.5 degrees), and both are present in *both*
  versions: the 48-gon's own facet at the tent's tangent points (x = ±4.48), a polygon artifact half a degree
  under the rule's line. **No ceiling anywhere.**

`probe_gland` moved with the cut — its tent piece is ramped 0.5 mm inside the cut's own ramp, so it still
rides on no face of the void it tests. The base's volume falls **2.17 mm³** (66104.50 → **66102.33**): the
ramp opens the roof that the cap had closed, over the 2.04 mm of depth where the two differ.

**Two traps this pair of amendments paid for, worth keeping:** a flat roof is a bridge wherever it stands,
so "the tent covers the band" is not the same statement as "nothing over the band has to be bridged"; and
the position of a hole in the print's own vertical never changes what has to be supported — a support
question is only ever answered by the angle of the faces the print leaves hanging.

**What came after, and all of it is now drawn or cut:** the gasket ring (ADR-024's shoulder), the vent
(ADR-026), the membranes' seats (ADR-023 answered them: there is nothing to cut), and the mounting closed
with ADR-027 — no ears, because the two M4 through the back plate are the fixing. The wall screws' own
pockets and holes went in with this one — they were the only remaining cut item with a decision behind it
(ADR-021's amendment). The gland itself is drawn as a marker, exactly like the M4 screws: what is cut is
the hole, the boss and the pad.

## ADR-026: the vent goes in the middle of the -X side

**Decision (2026-09-26; the position is the user's call, and it moved the same day from the first cut at
z = 78):** the case breathes through a **Ø4.00 mm hole** in its **-X side wall**, at **z = 48.40** — the
case's own mid-height — and **y = 29.35**, the middle of its depth. A breathable membrane is **stuck over
it** from outside, exactly as the two microphone membranes are stuck over their slots (ADR-023): nothing is
cut for the membrane, and no spot-face either.

**First, what it is not:** it is not the same opening as the microphone slots, and neither replaces the
other. Those two 1.20 × 8.00 slots are the case's **acoustic** ports — they exist to let sound in, they
are covered by hydrophobic membranes whose job is to pass sound while keeping water out, and between them
they are 19 mm² of open area. This hole is the case's **pressure** path. Hanging the daily pressure cycle
on the acoustic membranes would spend the microphones' own ports on it, and the two jobs want different
membranes: an acoustic one is thin and transparent to sound, a breather flows far more air.

**Why:** ADR-017 already decided that the case is vented, and why — the failure mode outdoors is thermal
pumping, not the rain that lands on the box. This only fixes where, and three things decide it:

- **not the back plate**: that face beds flat on the post (ADR-021) and carries nothing at all except the
  wall screws' own holes;
- **mid-height, and this is a geometric argument rather than an aesthetic one**: the capsule's outline is
  straight from z = 33.40 to 63.40, so in that band the case's outer surface is a **flat plane at ±33.40**
  and the cavity's wall the same plane at ±30.00. At 48.40 the hole is therefore **square to the surface
  at both ends** and crosses a **uniform 3.40 mm** of wall — the cleanest cut in the case. In the rounded
  ends the surface curves away and the wall deepens: at the first position, z = 78, it was 3.84 and the
  outer mouth was cut on a slope. The middle of the band is also the case's mid-height and the middle of
  its depth, so the patch reads as placed rather than as an accident;
- **the -X side specifically**: the only other opening in the upper half is the gland, on the TOP and
  centred, and the button, on the front. A side is the one face with nothing on it, and it puts the vent
  and the gland as far apart as the case permits. The microphone ports are 40 mm below the new position, on
  the bottom, which is as far from them as this case gets — the microphones once shared the speaker's field
  and that was direct coupling, so nothing gets added near them if it can be avoided.

**What it costs:** nothing that has to be designed around. The hole's axis runs along the case's X, which
in the print is **in the bed plane** — the base prints on its back plate, so the case's X and Z are the
printer's X and Y — so the hole comes out as a **horizontal tunnel** whose ceiling is a **4 mm bridge**,
two fifths of what rule 4 allows, and it needs no teardrop. It is also the right orientation for rain: a
horizontal hole through a vertical wall cannot be run into, only climbed into. And because the band's wall
is a plane, the membrane's patch is a **flat disc on a flat surface** — the one membrane here that has
nothing to conform over.

**Proved by boolean, not by eye:** `probe_vent` runs a rod 1 mm narrower than the hole from inside the
cavity to outside; empty against the base is the statement that this is a hole through the wall and not a
pocket in it. Measured on the STL: r = 2.00 at both mouths, the outer one at x = −33.40 and the inner at
−30.00, with exactly **3.40 mm** of material between them; the hole took **42.5 mm³** off the base
(65325.39 → 65282.93 mm³, against the 47.9 mm³ the first, longer and sloped tunnel took).

**Amendment (2026-09-26, the user's call the same day): the patch gets a recess to sit in.** The Ø4.00 hole
is unchanged; what the mouth carries now is a **counterbore, Ø11.00 × 0.35 deep**, and the stick-on patch
drops into it. Ø10.00 of patch in a Ø11.00 pocket leaves 0.50 mm of clearance all round, and 0.35 is the
patch's own thickness, so the membrane finishes **flush with the wall** instead of standing proud on it.
Two things come out of that: the patch's edge sits inside the rim, where nothing can lift it from the
side, and the panel's surface stays smooth — which is what the user asked for, the adhesive parallel to
the surface rather than a disc stuck on top of it.

The wall under the pocket's floor goes from 3.40 to **3.05** (rule 3's floor is 1.20), and the print is
untouched: a counterbore in a **vertical** wall is just a different 2D cross-section per layer, so it adds
no overhang and no bridge — the only bridge in this opening is still the 4 mm one over the hole. Patches
are sold 0.30 and 0.35 thick; a 0.30 one lands 0.05 below flush, which is if anything better.

**Proved in two pieces now, one per step of the cut** (each 0.50 smaller in diameter than what it spans,
each placed by its own inner end): the hole's rod runs from inside the cavity out past the face, the
recess's disc sits across the counterbore's band, and `probe_vent` is empty against the base only if
cavity, 3.05 of wall, recess and out are one path. On the exported mesh the ray cast along +X at the
vent's own height settles it band by band, 3.00 mm off the axis: at |x| = 33.20 the point is in the
**recess's void** (its crossings run −33.05, −30.00, 30.00, 33.40 — the pocket's floor, then clean through
the case), while 0.40 further out, at |x| = 32.80, the same point is in **material**, and that pair *is*
the floor; at 6.00 mm off the axis, outside the Ø11.00, the same depth is material as well. The mesh's own
vertices say it in one line: a floor at |x| = 33.05 spanning r = 2.00 to r = 5.50, and the wall's face at
33.40 only from r = 5.50 outward. The base's volume fell **28.86 mm³** (65135.77 → 65106.91), which is
π × (5.50² − 2.00²) × 0.35 = 28.86 by hand.

**Still to design:** nothing. The microphone membranes' seats are answered — ADR-023 dropped the Ø9
spot-face, so there is no seat to cut and the patches are drawn on the bottom's curve — and the mounting
question closed on 2026-09-26 with ADR-027: **no ears, the two M4 through the back plate are the fixing**.

## ADR-027: no mounting ears — the case is fixed by two screws through its back plate

**Decision (2026-09-26, the user, the same day the ears were drawn):** the ears are **out**. The case is
fixed the way it was always going to be — by **two M4 through the back plate**, on the centre line at
z = 24.2 and 72.6, which is the fixing ADR-021 already cut: a **Ø8.00 × 1.50** pocket in the plate's inner
face for the head, then a **Ø4.50** hole on through, which leaves **1.90 mm** of plate. Nothing is added to
the sides, and the case stays 66.80 mm wide. Bedding the plate flat on the post is harmless now that
ADR-023 moved the microphone ports off it and down to the bottom.

**What was drawn, and why it went:** the two lugs were the ALTERNATIVE to those screws — a Ø5.00 eye on each
side at z = 14.00, for a screw into a wooden post or a cable tie round one, which is what F2's "mounting tabs
for a wall or a pole" asked for. They worked: the eye kept rule 3's material on both sides (1.20 mm inside,
2.00 mm at the tip), the print needed no bridge or teardrop at all because the eye ran along the case's Y —
the printer's Z — and `probe_ear` proved both eyes open. What they cost was **8.20 mm on each side**, taking
the case from 66.80 to 70.78 mm wide, and the back plate beds on the post anyway: the screws that were
already there do the job. The commit that drew them is `79beeca`, in the history, if the mounting ever has
to change to a pole or to a strap.

**One thing kept from that pass, because it is not about ears:** the lug's inner hub dipped about 0.2 mm into
the cavity between z = 14.56 and 17.96 — two circles of different radius crossing just above and below the
height the hand arithmetic was checked at — and the cure was to grow the added solid INSIDE the shell's own
`difference()`, so the cavity's cut passes over it. The reversal removes the feature, not the lesson.

**Proved by boolean, not by eye:** `probe_m4` is empty against the base, and the fixing is measured on the
STL at both heights: the pocket's mouth at the plate's inner face (y = 55.30) is a **Ø8.00** rim, its floor
at 56.80 shows the **Ø4.50** arriving, and the plate's back face at 58.70 shows the Ø4.50 hole alone.

---

## ADR-028: the unit is cradled by two arcs near the mouth, not by a ring around it

**Decision (2026-09-26, the user's call):** the base carries two arcs that hug the unit's cover, one on each
side, on the **±X** directions. Each spans **35 degrees** either side of its own axis direction, runs from
**y = 11.05** (the front quarter of the 50.70 deep base) to **y = 25.55**, and stands **0.25 mm** off the
cover — the same order as the collar's 0.20 at the back end. With that collar the unit is now located at
both ends instead of only at its back. They are arcs, not a full ring: the top and the bottom of the bore
keep their own clearance.

**Why:** the bore is the Ø60 of the inner capsule and the unit's cover is Ø57.50, so 1.25 mm of daylight
rings it. That is fine while the case is upright with the lid on, and it is the reason the unit stays put
nowhere: it can slide and rattle against the shell, with the speakers bolted to it, and with the lid off —
on the bench, or during a service — nothing holds it in the base at all. The three pads on the back plate
only push it forward, onto the seat in the lid. Two arcs take the daylight down to 0.25 mm where it
matters, and they cost 1.10 cm³ of filament.

**The print ramp, and why it is the keep-out and not extra geometry:** the base prints bedded on its back
plate, so the printer's Z is the case's **−Y** and the cradle's *deep* end is printed first. A pad that
started at full depth would begin life as a horizontal ledge. So the surface that faces the unit is not a
cylinder but a cylinder plus a cone: the 0.25 mm of clearance over the first 5.00 mm, then a ramp that
lifts it at **0.84 mm per mm of depth** — 40 degrees, inside the rules' 45. That ramp *is* the subtraction
that gives the cradle its inner surface, so it costs no geometry of its own. The mouth end is a plain face,
which is what a layer sitting above an empty volume wants.

**Clearances, and the three traps this feature paid for:**
- the arcs' inner surface sits at **r = 29.00** (the Ø57.50 cover plus 0.25), so `fitcheck` — the unit's
  ghost against `base()` and `lid()` — stays empty, and the unit still drops in: the bevel at the mouth
  opens it to 29.40 over its first 0.40 mm;
- the cradle must not reach into the joint's band, which the base's recess occupies to y = 11.01
  (`joint_y - eps + lap_d + 2 eps`). A first cut of this feature ran from y = 9.50, and the recess cut then
  had coincident faces to work with: CGAL returned the ring **still in place** over the whole 35 degree
  arc, and `fitcheck_pair` — the base against the lid — reported a sheet at r = 33.40. Moving the mouth
  face 0.04 mm clear of that band fixed both. Two lessons: coincident faces break a boolean quietly, and a
  check that returns a sheet is returning something;
- the subtraction's own band is 0.05 mm proud of the cradle's at both ends, for the same reason, and the
  arc's inner radius is 0.05 mm outside the keep-out so the surface facing the unit is the keep-out's own
  cylinder and not the wedge's chord.

**Alternatives rejected:** a **full semicircle** (the user's call: the top and bottom of the bore do not
need it, and it would stiffen the shell exactly where the vent and the M4 pocket have to live); a ring at
the mouth only (it would have to be interrupted for the recess and the lip, and interrupted rings locate
nothing); **felt or foam tape** stuck to the bore (it holds nothing against a sliding unit and dies of
compression set, the same reason the gasket stopped being foam); and a **third arc at the bottom** of the
bore (nothing needs it: the unit's weight already rests there, and the two arcs hold it against the
collar).

**Amended by ADR-029 (2026-09-28):** the collar this record leans on at the back end — *"with that collar the
unit is now located at both ends instead of only at its back"* — is out, and a second band of the same arcs, the
same numbers mirrored in the depth, took its place. The front band itself is untouched: the refactor that folded
both bands into one module (`unit_cradle_band`) measured it back at **r = 29.000 from y = 11.46 to 16.05** on the
exported mesh, which is this record's own number.

## ADR-029: the collar is out — the unit's back end is cradled by arcs too

**Decision (2026-09-28, on the first print of the base; the user's call):** the ring on the floor that located
the unit's back end (ADR-020's collar: **Ø60.40** outside, bore **Ø57.90**, **5.00 mm** tall) is **removed**.
What holds that end now is a **second band of arcs** — the front band's own geometry (ADR-028), **translated** to the
other end of the unit: ±**35 degrees** about the ±X directions, inner surface at **r = 29.00** (0.25 mm off the unit's cover),
hugging the unit's **last 5.00 mm** from **y = 48.30 to 53.30**, with its ramp on the **deep** side of that hug —
climbing away from the mouth and **landing on the cavity's floor at y = 55.30**. The unit is located at both ends, by
four arcs and nothing else.

**Why:** the print decided it. The collar's bore was 0.20 mm a side (rule 6's "tight fit") **and a closed 360
degree ring**: it has nowhere to flex, and 0.20 mm is inside what a printed bore holds in practice — the unit
would not enter the printed base at all. The two front arcs of ADR-028 stand 0.25 mm off and are **arcs**, stiff
wedges anchored to the wall at their ends rather than a hoop, and on that same print they took the unit and held
it. So the feature that worked is repeated where the one that failed was, at the clearance the print proved.

**The profile is the front band's, TRANSLATED along the depth — and the review caught the difference.** The first
cut of this band was that profile **mirrored**: the ramp pointing back toward the mouth, the hug at the deep end. It
was wrong, and the mistake is worth recording, because the geometry looks fine in a render and every boolean was
happy with it. The base prints bedded on **its back plate**, so the case's deep end is the **first layer printed** —
ADR-028 has that the right way round, *"the cradle's deep end is printed first"* — and a hug at the deep end
therefore begins life as a **ledge hanging over the void**. At the ±X directions that ledge is the 1.00 mm between
the hug's surface (r = 29.00) and the bore's wall (30.00); at the arc's edges it is over **6.00 mm**, because the
cavity's wall is a **plane** at ±30.00 and the plane is further from the unit's axis the further the arc turns from
±X (36.62 at 35 degrees). That is precisely the ledge ADR-028's ramp exists to avoid — put on the wrong end of the
band.

Translated, the band does what the front one does: the material **starts thin, or it lands on something**, and here
it does both — the ramp rises from the hug as the depth grows, and the band's own slab ends on the **cavity's floor**
(the plate's inner face, 55.30), so the first layer of the feature is material resting on the plate. The unit's back
end still meets a **0.40 mm lead-in bevel** at y = 48.30, the same one the front band carries at its mouth.

**What it deliberately does not touch:** the unit's **axial** location (the three pads still push it forward onto
the seat in the lid, `unit_pad_h` and the 1.80 mm gap are unchanged); the **microphone slots** (same prisms —
they used to cut a 1.20 mm notch in the collar, now they cross the wall alone); and the **vent**: the band begins at
48.30, **17 mm clear** of the vent's mouth on the -X side (y = 27.35 to 31.35). The mirrored first cut made that
clearance a live question rather than a formality, and `probe_vent` is what answers it — its rod reaches 1.60 mm
into the cavity at the vent's own angle and depth, so a band that came that far would meet it and the check would
not come back empty.

**Alternatives rejected:** a **looser collar** (0.35 or 0.40 mm a side) — it keeps the hoop's failure mode, and
it is a second print to find out, where the arcs cost the same filament and can be measured off the mesh;
keeping the collar **short, behind the unit only** — the skirt is the whole reason the ring existed (0.20 mm of
clearance over 3.20 mm of body holds the unit's cocking at 7.1 degrees where 1.75 mm lets it cock by 12.9), and
a short ring locates nothing; and a **third and fourth band** at the top and bottom of the bore — not asked for,
and every band costs the print a face.

**Traps this one paid for, and one of them is ADR-028's ledger again:**
- **the ramp goes on the deep side.** The mirrored band passed every boolean the file has — `fitcheck` and
  `fitcheck_joint` were both empty with it — and only the print orientation says otherwise. Any band of this
  feature has to be read with the bed at the **back plate**;
- the keep-out must run **past** the material's own face at the band's ends. The mirrored version's hug stopped
  exactly at 53.30, where the cradle's own slab ends, and the two faces came out coincident: `fitcheck` and
  `fitcheck_joint` both returned a zero-thickness **sheet at y = 53.300** spanning the arc (x ±28.75, z 17.27 to
  49.53) — CGAL's way of saying "these two touch". The translated band has no such face (its ramp is cut off by the
  floor), and every one of its other ends keeps the 0.50 mm of overshoot the front band carries;
- the subtraction's band stays **0.05 mm proud** of the cradle's at both ends, exactly as the front band has it.

**Proved by boolean, not by eye:** `make fit` is **twelve empty booleans** again, `fitcheck` (the unit's ghost
against both printed parts) among them — that one *is* the 0.25 mm — and `fitcheck_joint`'s third question is
asked of the four arcs now (`fc = "cradles"`, where it was `fc = "collar"`): the arcs against the unit and the M4
heads.

**Measured on the mesh**, which needed a new export: the arcs alone are `part = "cradles"` (nothing else in the
file is the arcs without the shell's own wall over the same bands), and with it a ray cast along +X at the unit's
own height (z = 33.400), from the axis outward, settles both bands:
- **front band, unchanged by the refactor:** r = **29.000 from y = 11.46 to 16.05**, then 29.359 at 16.50 and
  29.758 at 17.00 — ADR-028's own numbers to the hundredth;
- **back band:** **nothing before y = 48.30**; the lead-in bevel reads **29.400** at 48.50 (0.40 mm of it, the same
  bevel the front band has at its mouth); **r = 29.000 from 48.75 to 53.25** — the unit's last 5 mm, and the surface
  the unit will bear on; then the ramp: **29.160 at 53.50, 29.758 at 54.25, 30.556 at 55.25, and nothing at 55.50**;
- the ramp rises **1.40 mm over those 1.75 mm — 0.798 per mm, 38.6 degrees**, the same slope the front band cuts: the
  cone carries 0.50 mm of overshoot past its own band, so what it cuts is a hair under `cradle_slope`'s 40 degrees
  (the parameter now says so and quotes this measurement). Inside the rules either way — and here it **lands on the
  cavity's floor**, which is the point of the translation: the feature's own deepest material is on the plate.

**What it costs:** the base goes **66207.93 to 66109.60 mm³**. The back band **adds 952.19 mm³** and the collar took
**1050.52 mm³** away with it, so the net is **−98.33 mm³** — a tenth of a cubic centimetre *less* filament than
before, for a band that locates the unit. Both numbers are measured, by rebuilding the base with the back band
commented out (`65157.41 mm³`: no collar, front band only). The lid is not touched at all.

## ADR-030: the gland moves 10.59 mm back along +Y, and the print does not notice

**AMENDED by ADR-032 (2026-10-04): "the deepest point the part allows" here is not the deepest the part
allows. It was set by the boss's tail clearing the cavity's floor — but the tail's point is the first layer
of the boss, so what it has to clear is nothing: ADR-032 lands it exactly on the back face, which is the bed,
at gland_cy = 44.34. Everything this ADR measured about the hole's own relief is unchanged and still true;
what it got wrong is which point the print cares about.**

**Decision (2026-09-29, the user's — asked twice: "vamos mover o furo, de maneira que o início do teardrop
comece na placa de impressão", and then "quero que mova em y, na direção positiva, para as costas da base,
entendeu? claro que dá."):** the hole's axis moves off the unit's own axis, from **y = 29.85 to y = 40.44** —
10.59 mm further back along +Y, the deepest point the part allows: the boss's own tail ends at 40.44 + 14.36 =
**54.80**, which clears the cavity's floor by **0.50 mm**, the clearance the cradles keep. It is one
translation of the whole feature — hole, boss, tail and the locknut's pad — and it is a parameter
(`gland_cy`), so it is one number to move again.

**Why it stops there, and not at the back plate:** the binding constraint is not the hole but the **boss's
tail**. The bore alone could go to y = 49.05, where it grazes the plate's inner face, but the tail (14.36 mm
from the axis) would then be through the plate and out of the case's back at 63.41, 4.71 mm past its outer
face. What the hole reaches for nothing is free: the cavity's depth is 8 to 55.30 and the plate is only 3.40
thick, so the last 14.86 mm of this case is a solid wall the gland may not enter.

**What it costs: the cable route loses its plumb line.** ADR-025 put the gland on the unit's own axis because
that is the only place the pigtail reaches the USB-C with no bend. The port is still under the hole, but 10.59
mm off centre, so the run from the gland to the port is now a flight of about **17 degrees** instead of a
plumb line. That is the whole price, it is the user's call to pay, and it is recorded here rather than
argued about.

**Why the print does not notice — measured, not argued.** Four numbers, on the STL, either side of the move:
- the roof over the axis reads **6.810 / 7.100 / 8.000 / 8.600 / 8.839 mm** at z = 99.79, 99.50, 98.60, 98.00
  and 97.70 — the same numbers to the thousandth that the hole read before the move, because the relief
  travels rigidly with the hole;
- the audit of faces that hang in the roof region gives the **same 22 faces at the same angles** — worst
  |n_y| = 0.7770, then 0.7660, and the 48-gon's 0.7127 facet — with their centroids **exactly 10.59 mm**
  further along Y (38.27 → 48.86, 39.96 → 50.55);
- the base's volume is **66102.33 mm³, unchanged to the hundredth**: a translation that touched no boundary of
  the solid would leave it untouched, and it did;
- `make check` clean and `make fit` **12 of 12** empty, `probe_gland` (the hole is one hole) and `fitcheck`
  (the unit's ghost) among them.

**The finding underneath the request, since it will come back: in this feature the point of a teardrop
cannot be born at the bed.** The request is the beginning of the teardrop on the print's first layer, and the
first layer of this base *is* the back plate (y = 58.70). Both teardrops in the gland are ruled out by
arithmetic, not by taste:
- the **hole's** teardrop begins where its flanks leave the bore, r cos 45 = **4.42 mm above the axis**. For
  that to land on the bed the axis would need y = **63.12** — 4.42 mm *behind* the plate's own outer face.
  Moving the axis cannot do it, and the move has already been made to its limit. Today that beginning sits
  **22.68 mm above the bed**, where it was 33.27;
- the **boss's tail** is the other teardrop, and it is the one whose point is 3.90 mm above the bed. Its
  flanks are tangent to the boss's Ø22, which fixes the point's distance at 11/cos(angle): a *shorter* wedge
  cannot reach further, and a *longer* one does not exist — the flanks converge. To land the point on the bed
  the tangent would have to sit at **37 degrees off vertical**, which is 8 degrees past what rule 4 allows, and to
  land it flat on the bed it would have to be a buttress **36.5 mm wide** on the crown. Neither is paid for
  here.
- **One correction to the ledger, found while measuring this.** ADR-025 says the tail's sides are "tangent to
  the boss's circle at 40 degrees ... the worst surface 40 degrees off vertical against rule 4's 45". The
  audit disagrees with the units: those 22 faces sit at |n_y| = 0.766 to 0.777, which is **39 to 40 degrees
  off the horizontal** — that is **50 degrees off vertical**, five past rule 4, which is where the mild droop
  on the tail's flanks comes from. Setting the tail's tangent to 45 degrees would put it exactly on rule 4 and
  move its point from 3.90 to 4.50 mm above the bed; it changes the boss's outside silhouette, so it waits for
  the user.

## ADR-031: the insert's carrier grows off the side wall, and the pillar is gone

**Decision (2026-10-04, the user's, in two steps).** The two M3 that hold the lid no longer bite inserts in
pillars standing off the back plate. The insert is pressed into a **gusset grown off the cavity's side
wall** — the same family as the arcs that cradle the unit (ADR-028) — and the **Ø4 x 10 blind hole is bored
straight into the gusset's flat top**. There is no boss and no cone, because the top is a surface the print
lays down last and needs nothing under it.

The user's first instruction moved the base of the column to the wall: *"as pilastras, ao invés de virem das
costas da base, vão ficar apoiadas numa estrutura que cresce das laterais da base. Tipo o que foi feito para
segurar a parte frontal da unit."* The second removed the boss: *"acho que fica mais fácil tirar o cilindro e
só colocar o furo nessa peça que nasce da parede, pois assim não precisa ainda colocar o cilindro e uma coisa
nele para evitar suporte em baixo. A própria rampa, com a superfície reta no topo, e furo no topo para o
insert, já basta."* Both are right for the same reason: **a boss needs a closed far end, and a flat top does
not.** The boss's disk against open air is a 50 mm² ceiling to bridge; closing it with a cone costs a
surface; the ramp's own top is already flat, already facing -Y, and already normal to the screw.

**The carrier, one profile in (x, y) extruded across z, mirrored for the second screw:**
- the **face** at x = ±14.00, vertical. The hole is Ø4.00 at 18.00, so its edge is at 16.00 and the face
  leaves **2.00 mm** of material on that side — the wall the Ø8 pillar used to give it, and rule 3's 1.20
  with room to spare;
- the **ramp** at the cradles' own 0.84 mm out per mm of depth (ADR-028), from the face at y = 15.00 out to
  the wall (29.78, plus a 0.75 key into the shell's own material) at y = **34.68**;
- the **flat top** at y = 8.00, which IS the joint plane, with the **Ø4 x 10** hole bored into it: the insert
  spans 8.00 to 13.00, the M3 x 12's tip still has 5.00 mm of relief, and the hole's floor at 18.00 has
  **1.77 mm** of material behind it (measured);
- z = **63.50 to 70.50**: 1.50 of material above and below the hole, and **1.35 mm** to the unit's own top
  edge at 62.15 — where a carrier tall enough to hold an Ø8 boss had only 0.35.

**The lid is not touched, and neither the screw nor its position:** the counterbore, the boss on the lid's
inner face (`m3_lid_boss`, Ø8.2, the surface the head clamps), the head's seat, the M3 x 12 and the pair's
place at (18, 67) are exactly as ADR-019 left them, and the insert's axis is still Y. ADR-019 is superseded
on the pillar alone.

**Why the print does not notice — measured on the STL, and every surface is one the cradles already print:**
- the carrier reaches its wall on both sides — x = -30.53 to +30.53, exactly mirrored — with a 0.84 ramp, a
  vertical face, a flat top and vertical z faces. **Nothing it adds points at +Y**, so nothing needs support;
- the base's volume is **64952.49 mm³**, 1149.84 less than the pillar version's 66102.33. The two carriers add
  3604.96 mm³ of new material (3898.15 of them, less 293.19 the wall already occupied under their key) where
  the two Ø8 x 47.30 pillars took 4754.79: the case comes out **lighter**, and the tallest free-standing thing
  in the cavity is gone;
- rays along the STL: at the screw's own axis, material from **17.99 to 19.76** (the hole's floor and the
  ramp: 1.77 of plastic under the insert); at x = 25, **8.00 to 28.10** (the ramp's own line); at x = 14.50,
  **8.00 to 15.60** (the face's edge); across at y = 9.50, **14.00-16.00 and 20.00-31.49** on both sides —
  the face, the hole's wall, and the rim (the lap's recess starts at 31.49);
- clearances: **4.2 mm** to the switch's body at the corner (14, 70.5), **1.35 mm** to the unit's top edge;
- `make check` clean, `make fit` **13 of 13** empty, the new `probe_carrier` among them.

**A trap paid for here, and the check that now catches it: an empty intersection proves nothing about whether
the material exists.** The first cut of the carrier was built in the global frame while the pair goes in
through `m3b_points()`, so it came out displaced — and **every** fit check passed, because a carrier floating
clear of the unit and the switch interferes with nothing. The second cut had the placement right and still
passed for the wrong reason: the review marker was drawn from `m3b_points() m3_carrier()` while the pair is
`translate + mirror`, which left the second marker 12 mm inboard of its wall — what the user saw on the -x
side as *"a mesma peça ... meio transparente e transladada"*. Both are fixed (the marker takes
`m3_carriers()`, and the mirror is what makes the pair, since a gusset is not symmetric about its screw), and
`probe_carrier` now asks the opposite question by **difference**: rods and blocks that must be *inside* the
base's material, cut out of it, must come back empty. On its way in it caught itself — a ring whose deep edge
reached y = 17 where the ramp is only at 15.89 by the ring's own inner edge (x = 14.75) — which is the grade
of check this needed.

## ADR-032: the gland's tail lands its point on the back face, so the boss starts on the bed

**Decision (2026-10-04, the user's).** The gland moves **3.90 mm further back along +Y**, from gland_cy 40.44
to **44.34**, and the parameter is now `gland_cy = case_d - gland_tail_reach`: the boss's tail's point lands
**exactly on the case's back face**, which is the bed — so the boss's first layer is printed on the plate
instead of 3.90 mm above it. The instruction: *"o início dele precisa começar exatamente nas costas da base,
para evitar suporte na impressão."*

**Why ADR-030's limit was not the limit.** ADR-030 moved the gland back to bring the **teardrop's beginning**
as low in the print as the part allows, and stopped where the boss's tail cleared the cavity's floor by
0.50 mm. But the teardrop's beginning is not what the printer has to support: the relief travels rigidly with
the hole (ADR-030 proved that, and it is still true) and every face of the roof is a 45 degree surface. What
hangs is the boss's **material**: the prism runs from z = 94 to 99.80, the case's own top is at 96.80, so
3.00 mm of the boss are a cantilever, and the deepest point of that cantilever — its first layer — was the
tail's point at 54.80, **3.90 mm above the bed**. Since the bed IS the back plate (the base prints lying on
its back face at y = 58.70), landing the point there starts the whole boss on the plate: in the z band where
the plate exists (94 to 96.80) the tail is simply inside it and comes out as a buttress, and above it the
point is a first layer on the bed.

ADR-030's other argument stands untouched and is not contradicted — to land the **tent's beginning** on the
bed the axis would have to sit at y = 63.12, 4.42 mm behind the plate, because the tent stands 4.42 above
its axis — but it was answering about the wrong point: the tent is not what hangs.

**The numbers.** The tail's reach is 14.36 from the axis (its flanks 50 degrees off +Y, tangent at 40 off the
circle), so gland_cy = 58.70 - 14.36 = **44.34**: 14.49 mm behind the unit's own axis (unit_cy = 29.85),
3.90 more than ADR-030's 10.59. Measured on the STL:

- the ray along Y at the gland's own axis, above the case's top (x = 0, z = 97), reads **35.50 / 50.59 /
  58.70**: the crown, the hole, and the material ending exactly on the back face;
- the same ray at z = 95, where the plate is, reads the SAME numbers with **no crossing at 55.30**: the tail
  and the plate are one body, not two surfaces that meet;
- across X at (y = 57, z = 97) the material stops at |x| = **2.03**, which is the tail's own wedge at that
  height (predicted 2.03);
- along Z at (x = 0, y = 58.60) the material is continuous from the plate to 99.80, with no crossing at 94 or
  at 96.80 — the prism and the case are one body, and the flat is still the last thing printed — and nothing
  past 99.80;
- the bbox is y = **8.00 .. 58.70**: nothing protrudes out of the back, so the case still beds flat on the post;
- the base's volume is **64951.09 mm³**, 1.40 LESS than before, because the part of the boss that now sits
  inside the plate is absorbed by the union;
- the hole is open end to end (the axis is void at z = 95 and at z = 98.5), which `probe_gland` agrees with;
- `make check` clean, `make fit` **13 of 13** empty.

**What it costs, and what it does not.** The cable: the flight from the shell's inner mouth (z = 93.40) to
the port leans **22.4 degrees** off vertical, where it leant 16.8. Nothing else moves: the hole, its relief,
the washer's 1.20 mm of land on the flat and the flat itself are the same surfaces over a new axis. The
locknut's pad travels with it, and its teardrop's point (12.02 out) now reaches 56.36 and is buried inside
the plate — hidden, and the seat's plane at 92.15 is unchanged.

**Still open, and it is the user's call:** the tail's flanks are 40 degrees off the horizontal, 5 degrees
past rule 4 (ADR-025's own 50 degree half-angle). They now rise out of solid plate and bed over a 5.93 mm run
instead of hanging from a point in the air, so it is a much smaller thing than it was; opening the tail to 45
degrees brings it back inside the rule, widens the tail by 1.20 mm and puts the axis at 43.14 instead of
44.34 — with this parametrisation that is `gland_tail = 45` and nothing else.


