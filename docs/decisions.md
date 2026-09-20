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

**Decision (recommendation, awaiting confirmation of where the 220 V comes from):** the 220 V to 5 V
USB-C supply lives outside the printed part. Power enters the case as 5 V through a sealed cable gland,
or through an IP67 USB-C panel socket, and never as mains.

**Why:** a mains supply inside a sealed printed box puts 220 V and condensate in the same volume, and it
adds a permanent heat source. Heat is what actually wets an outdoor enclosure: the box warms, pushes air
out, cools, and pulls humid air back in through every gap (thermal pumping). A printed ASA part is also
not a certified mains enclosure, so putting mains inside would demand a separate compartment with
barriers, a fuse and its own glands. Keeping the supply outside removes the hazard and most of the
moisture cycle in one move.

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
