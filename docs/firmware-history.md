# Firmware history

Only builds that went to the device are listed. Every row was verified on hardware, and each one
changed behaviour, not just code. The lesson repeated most often: after an OTA, confirm
`device_info.compilation_time` before interpreting any test, because with rollback enabled a crashing
build silently comes back on the *previous* firmware and the fix looks broken.

## UDP stack (retired)

| Build (compilation_time) | Change | What it proved |
|---|---|---|
| 2026-09-18 11:22:19 | Bring-up: BOOT button plays a tone through the native media player | Button, GPIO0, script and I2S path all fine; the board was still silent |
| 2026-09-18 12:33 | `tca9555` block plus a switch on EXIO8 to enable the amplifier | **First audible sound this board ever produced.** The enable is on the expander, not a GPIO |
| 2026-09-18 13:06 | UDP full duplex (`i2s_audio_udp`) with the amplifier enable | Mic and speaker at the same time, verified with counters and with a TTS phrase heard at the gate |
| 2026-09-18 13:57:08 | Two direction switches (mic / speaker) mapped onto the component audio modes | All four states verified on the device API. Note: the first OTA of this build reported success while the device kept running the previous one |
| 2026-09-19 12:38:18 | Speaker gain 0.25 in the component (the HA volume slider is linear, so 90 percent was -0.9 dB) plus a semaphore join in `stop()` | Distortion fixed by ear; the join did **not** hold, the board crashed on the first switch toggle |
| 2026-09-19 13:07:09 | No more restarts for direction changes: runtime flags, ring buffer in internal RAM, generation counter, ownership on the audio task | Four switch states, zero crashes, no rollback. The crash class was removed instead of narrowed |
| 2026-09-19 13:33:53 | Direction switches publish their state on connect (they are `optimistic: false`) | The panel can no longer show "off" while audio flows. Last UDP build; its ELF is kept for symbolicating crashes |

## intercom-api stack (current line)

| Build | Change | What it proved |
|---|---|---|
| 2026-09-19 15:52:51 | Migration to the pinned `samuelthng/intercom-api` fork: `i2s_audio_duplex` + `esp_aec` + `intercom_api`, voice assistant and wake word removed, AEC with the hardware TDM reference | The stack builds and runs; the TDM reference was not the answer for echo |
| 2026-09-19 16:16:39 | ES8311 volume and unmute re-applied after the stream starts | The codec can come up muted when its registers are written before the MCLK exists, which reads exactly like "the AEC cancels everything" in a measurement |
| 2026-09-19 16:28:22 | AEC reference switched to the codec-agnostic delay buffer, plus a `codec_dump` service | ES7210 registers readable live: 24 dB analog mic gain confirmed, TDM actually off |
| 2026-09-19 16:46:33 | AEC mode `voip_low_cost` in the YAML and in the select's `initial_option`, `restore_value: false` | **42 to 47 dB of echo suppression**, against about 0 dB in `sr_low_cost`. Mode was the lever, not the reference |
| 2026-09-19 17:30:29 | `send_frame_complete()` on the audio send path (a partial socket write was silently truncating a frame) | Real bug, real fix, but not the cause of the framing holes: it stayed as a correctness fix |

## Home Assistant side

| Artifact | Version | Change |
|---|---|---|
| `intercom_native` | 2.1.4 | Fork integration installed; device discovered; card registered as a Lovelace resource |
| `tcp_client.py` patch | - | Receiver-side resync with a strict per-type plausibility rule. A corrupted frame no longer ends the call (proven in production: a bad header mid-call and the call continued for another 26 s) |
| `intercom_native` | 2.1.5 | Session bound to its websocket connection, 90 s grace window, `session_status` as the resume ping, card listens for reconnect |
| card `intercom-card.js` | 2.1.6 | Screen wake lock while in a call, re-acquired on `visibilitychange`, released in both cleanup paths |

## Known open defect

A frame that declares `len=1024` and carries exactly 620 bytes less (or more) of audio, 4 to 5 times per
two minutes, in silence as well as during playback. Measured on the raw stream, always exactly 620
bytes, so it is not socket slack. Cause not yet identified; the client now resynchronises instead of
dropping the call, which is why it is not urgent. The next step, when someone picks it up, is to
instrument the transmit path on the ESP (log the declared length and the bytes actually written per
frame) and correlate with a raw capture.
