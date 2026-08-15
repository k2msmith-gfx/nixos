---
name: reference_ray_user_config
description: ray has a ~/.config/ray/init.janet boot-time user-config hook (deployed via nixos home-manager) + set-wireframe-theme :light|:dark
metadata: 
  node_type: memory
  type: reference
  originSessionId: d730826c-dfbd-4229-9830-5456f9663e55
---

ray-janet evaluates **`~/.config/ray/init.janet`** on boot (respects
`$XDG_CONFIG_HOME`), AFTER the bundled prelude + live.janet, so it has the full
API. It's the place for personal preferences that persist across sessions.
Optional & non-fatal: absent = silent, an error is reported but boot continues.
Impl: `load_user_init()` / `config_dir()` in `src/bin/ray-janet.rs`
(ray commit 301b326).

Deployed to every machine via **nixos home-manager**: `home/common.nix` has
`xdg.configFile."ray/init.janet".source = ../ray/init.janet;`, source lives at
`~/nixos/ray/init.janet` (nixos commit 627aa33). Edit that file + darwin-rebuild
to change prefs everywhere. See [[reference_doom_config_nix_rebuild]].

Wireframe themes (ray commit 42aa5c8): `(set-wireframe-theme :light|:dark)` —
:light = built-in near-black-on-white, :dark = Doom doom-one (#bbc2cf ink on
#282c34 paper). Presets = `wireframe-themes` (prelude); setter in live.janet.
Held in a PERSISTENT `WIRE_THEME` (survives rebuilds, unlike scene-scoped
WIRE_STYLE); fallback palette for toggle-wireframe! AND the live move-proxy
(threaded via `LiveState.wire_theme`). A scene's own `(set-wireframe ...)` still
wins for that scene. Current default init.janet = `(set-wireframe-theme :dark)`.

To pick up either: relaunch the studio (new binary re-reads scripts) + for the
config file, darwin-rebuild first. See [[project_ray_interactive_editor]],
[[project_ray_render_features]].
