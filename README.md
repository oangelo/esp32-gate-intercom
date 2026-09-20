# ESP32 Gate Intercom

Two-way audio intercom for a house gate, built on a **Waveshare ESP32-S3-AUDIO-Board** and
integrated with **Home Assistant**. The far end is a phone, off-site, over the internet.

The gate device is the one that has to survive weather, so the enclosure in `cad/` is designed to be
**3D printed in ASA**, sealed, with the speaker integrated in an acoustic chamber.

## Status

Working, verified on hardware:

- Full-duplex audio between the gate and a Home Assistant client (browser card / phone).
- Acoustic echo cancellation on the device: `esp_aec` in `voip_low_cost` mode, measured 42 to 47 dB of
  echo suppression on a 600 Hz stimulus (the `sr_low_cost` mode cancels nothing and was rejected).
- Per-direction mic/speaker switches that do **not** restart the audio stream (runtime flags), which
  removed a class of crashes in the I2S/UDP path.
- Receiver-side protocol resync: a corrupted frame no longer drops the call.
- Session grace of 90 s with call resume, so a mobile network blip does not end the call.
- Screen wake lock in the browser card (a throttled page was collapsing the microphone uplink).

Open:

- Enclosure CAD (this repository, phase F2) and installation at the gate.
- Field test with the phone over the internet (screen off plus a network gap in the same call).
- Microphone gain tuning for outdoors.
- External antenna through the IPEX1 connector, since the board sits at -73 to -80 dBm at the gate.

## Hardware

| Part | Notes |
|---|---|
| Waveshare ESP32-S3-AUDIO-Board | ESP32-S3R8: 16 MB flash, 8 MB octal PSRAM, 2.4 GHz WiFi only |
| ES7210 | Microphone ADC, dual mic array, hardware AEC reference available on MIC3 |
| ES8311 | DAC (speaker output) |
| NS4150B | Class-D amplifier, enabled through the TCA9555 expander EXIO8, not a GPIO |
| Speaker | Separate part, GH1.25 2-pin header (H3) |
| Battery | Optional 3.7 V Li-ion cell (MX1.25), ETA6098 charger with power path |

Debugging notes, pinout and the full history of what was measured live on this board:
[docs/firmware-history.md](docs/firmware-history.md) and [docs/decisions.md](docs/decisions.md).

## Architecture

    gate:      ESP32-S3 + ES7210/ES8311 + esp_aec   (ESPHome firmware)
               |
               |  TCP audio, port 6054, PCM 16 kHz mono, 512-sample frames
               v
    home:      Home Assistant custom component "intercom_native"
               |
               |  websocket, audio + controls on the same connection
               v
    client:    Lovelace card (browser on a tablet, or the phone off-site over Nabu Casa)

The device side uses the pinned fork `samuelthng/intercom-api` (`i2s_audio_duplex` + `esp_aec` +
`intercom_api`). The Home Assistant side is the same fork's integration, patched here with framing
resync, a 90 s session grace window and a wake lock in the card.

## Repository layout

    cad/            parametric OpenSCAD for the enclosure (ASA, printable)
    docs/           decisions, dimensions, roadmap, gate installation, firmware history
    firmware/       ESPHome configuration for the device
    hardware/       bill of materials and part measurements
    homeassistant/  the Home Assistant side of this project (component, card, automations)
    tools/          project scripts (measure echo, toggle switches, capture logs)
    vendor/         pinned third-party components, with their licenses

## Reproducing

1. Flash the board over USB once, then OTA (`esphome run firmware/esphome/interfone-portao.yaml`).
2. Copy `firmware/esphome/secrets.example.yaml` to `secrets.yaml` and fill in your own values.
3. Install the Home Assistant component from `homeassistant/` and restart Home Assistant.
4. Add the card to a dashboard, using the device id returned by `intercom_native/list_devices`.

## Security

This repository is public. It contains **no credentials**: WiFi, MQTT, the ESPHome API encryption key
and the OTA password are all referenced through `!secret` or replaced with placeholders. Internal
network addresses appear as placeholders such as `<ha-host>` and `<intercom-ip>`. If you fork this,
write your own keys; do not commit `secrets.yaml`.

## License

- Code, firmware configuration and scripts: MIT, see [LICENSE](LICENSE).
- CAD files in `cad/`: CC BY-SA 4.0 unless the file says otherwise.
- Third-party components under `vendor/` keep their own licenses, see the manifest in each directory.

## Credits

- `samuelthng/intercom-api` (MIT): `i2s_audio_duplex`, `esp_aec`, `intercom_api`, Home Assistant
  integration and card. Pinned by commit, see `vendor/`.
- `fallingaway24/esphome-2Way-INTERCOM` (MIT): the earlier UDP-based full-duplex component.
- Waveshare: board documentation, schematic and mechanical drawing. The vendor CAD files are **not**
  redistributed here; dimensions are extracted from them and documented in `docs/dimensions.md`.
