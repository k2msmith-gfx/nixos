---
name: previs-repl-architecture
description: "User's target architecture for a live 3D previs window driven by the Steel REPL — informs future workspace/crate split and IPC-vs-thread design."
metadata: 
  node_type: memory
  type: project
  originSessionId: 72e69d9a-254a-4f9e-b9fd-1d4e42c84c2b
---

Target interaction model for the eventual previs feature (separate from,
optionally linked to, the core renderer + Steel REPL — see
`docs/steel-scripting.md`):

- A 3D preview window (candidate: **macroquad** — lightweight, has plain
  `draw_line_3d`/`draw_cube_wires`/`Camera3D` primitives, avoids pulling in
  a full engine like Bevy) shows the scene as wireframe/low-quality
  hardware render.
- A separate REPL (own window or the terminal) runs Steel (Scheme). The
  user builds the scene interactively there — `sphere`, `plane`,
  `material`, `light`, etc. — or loads a `.scm` script.
- Shapes/lights/materials appear **live** in the 3D window as they're
  created in the REPL — not a snapshot/reload model, real-time reflection
  of REPL-mutated scene state.
- A `(render)` call in Steel produces the real path-traced image: written
  to a file, and shown directly **in the terminal** the REPL is running
  in, via `viu` (a kitty/sixel-protocol terminal image viewer, already in
  the user's nix packages — `~/nixos/home/common.nix`). Confirmed
  2026-07-13: the macroquad window is **not** involved in final render
  output — it's a live *scene-construction* monitor only (wireframe/low-
  quality preview as shapes/lights get added), fully decoupled from the
  REPL's text + rendered-image output. Two independent consumers of the
  same live scene state, not one feeding the other.

**Why it matters now:** "live" updates mean the previs window needs to
watch live Steel/`Scene` state, not just load snapshots — this is a
stronger coupling than a naive "separate app" reading might suggest.

**Open design fork for later** (not decided, deliberately deferred
2026-07-13 — user said "let's hold off" twice on writing an actual plan):
same-process multithreaded (REPL thread + macroquad window thread sharing
`Scene` via a lock/channel — simpler, window starts/stops with the
session) vs. genuinely separate processes over IPC (more flexible —
headless-only runs, attach/detach a previs window later — more moving
parts). "Optionally linked" most likely means "spawn the window thread
only if requested," i.e. leans toward the same-process design, but this
wasn't explicitly confirmed.

**Structural consequence:** `ray` currently has no `lib.rs` (everything is
`mod`-declared in `main.rs`, confirmed via `cargo test --lib` failing
earlier this project). A previs binary/thread needs `Scene`/`Shape`/
`Camera` etc. as library types without dragging macroquad into the core
renderer or Steel CLI — this points toward eventually splitting into a
Cargo workspace (`ray-core` lib + `ray` CLI bin + possibly a previs
component), same "keep the hot/headless path lean" principle
`docs/steel-scripting.md` already follows for `steel-core`/`rustyline`/
`clap`.

See [[steel-procedural-mesh-goal]] — both this and mesh generation depend
on Steel bindings talking to simple, renderer-internal types rather than
format/library-specific ones.
