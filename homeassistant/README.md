# Home Assistant side

What lands here (phase F3):

| Path | What it is | Origin |
|---|---|---|
| `custom_components/intercom_native/` | The intercom integration, with our patches | Fork `samuelthng/intercom-api` (MIT), pinned by commit |
| `lovelace/portao-view.json` | The gate view of the dashboard: video card, intercom card, gate controls | Ours |
| `automations/` | Gate automations that touch the intercom (bell notification, calling the phone) | Ours |
| `secrets.example.yaml` | Placeholder for anything the automations need | Ours |

Patches carried on the component, both of which were needed in production:

1. `tcp_client.py`: receiver-side resynchronisation with a strict per-message-type plausibility rule.
   A corrupted frame used to raise and end the call.
2. `websocket_api.py`: the session is bound to the connection that created it, with a 90 s grace window
   and a `session_status` command used as the resume ping. A mobile network gap no longer ends a call.

Nothing here contains credentials or internal addresses: values that are site-specific come from
`secrets.yaml` (untracked) or appear as placeholders such as `<ha-host>`.

The card resource is registered by the integration itself, using `?v=<manifest version>` on the URL.
That means **bumping `manifest.json`'s version is what busts the browser cache**: a card change without
a version bump can silently keep running the old module in the browser, and the version bump is applied
at integration setup, so it still requires a Home Assistant restart.
