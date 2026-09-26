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
a round bottom sheds water better than a square corner. Open items, to be fixed with the caliper
numbers and a photograph of the board: the radius (driven by the board's 58 mm plus clearance) and the
height of the straight section.

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

## ADR-020: the collar is 1 mm of wall and 5 mm tall

**Decision:** the ring on the floor that locates the unit's Ø58 body is **cut material as of review 3**,
not a drawing. The bore stays at Ø58.4 (0.2 mm a side, rule 6's tight fit), the wall is **1.00 mm** and it
stands **5.00 mm** off the floor, so its outer Ø60.4 overlaps the cavity's wall by 0.2 mm and fuses with
it.

**Why:** none of those numbers are free. The cavity's inner radius is `cav_x = 30.0` and the unit is Ø58,
so the gap between them is **exactly 1.0 mm** all the way round — and the previous Ø63 collar (2.3 mm of
wall) had nowhere to go: it would have cut into the wall. The collar spends the millimetre instead. The
outer 0.2 mm landing inside the wall is deliberate: it is what backs a 1.0 mm ring, which standing free
would be the thinnest unsupported thing in the case (rule 3 asks for 1.2). The height is what makes the fit
"hold": of the 5.00 mm, 1.80 is the gap behind the unit and 3.20 is skirt over the unit's own body, which
drops the unit's free cocking from atan(0.4/1.75) = 12.9° to atan(0.4/3.2) = 7.1°. `fitcheck_joint` covers
it as `-D 'fc="collar"'`: the collar against the unit, empty. It bites `unit_collar()`, not `base()`,
because `base()` still has its back plate whole — the M4 pockets are markers, not cuts — and an M4 head
always meets that; that is also why `m4_heads()` rides along in that check.

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
has to stay clear — the two M4 at x = 0, z = 24 and 72 leave the lower corners free, so the fix can live
there. Steps 3 and 5 (gland, vent, mounting ears) should settle it before anything is printed.

**Superseded by ADR-023:** the answer to that open question is that the plate is *not* going to stand
off the wall, and the ports moved to the bottom of the case as thin slots.

## ADR-023: the microphone ports go through the bottom of the case, as thin slots

**Decision:** the two microphone ports are cut through the **bottom** of the base, close behind the unit,
as **slots of 1.20 × 8.00 mm** instead of holes — one each side at the microphones' own x (±18.23 mm),
running along the case's depth from y = 46.00 to 54.00, with `mic_slot_top` (13.00) taking each cut past
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
each side of the collar's ring, so the ring is no longer closed, though it still locates the Ø58 unit
and each of its arcs still holds on the 0.20 mm of outer face that fuses into the cavity's wall. The
slot's centre along the depth (`mic_slot_cy`, 50.00) also decides how deep into the unit's own volume it
reaches, and the answer is deliberate: 0.80 mm of it opens straight into the gap behind the unit, whose
back face is at 53.20, so the microphones keep a path even if the unit ends up tight against the collar.

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
wall cannot be thickened inwards at the joint, because at y = 8 the Ø58 unit is 1.00 mm from the cavity
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
