---
name: project-ray-janet-render-params
description: "ray-janet-poc future design — keep (render) nullary; put render params (filename, etc.) in a Janet table"
metadata: 
  node_type: memory
  type: project
  originSessionId: 478f80b7-f486-465b-a09b-289918195403
---

Agreed future design for ray-janet-poc (deferred 2026-07-26, revisit later): keep `(render)` a **simple nullary command** (it just flips the `*render-requested*` boolean flag). All rendering parameters move into a **mutable Janet table**, with the output **filename as one element** — not a bare scalar var.

Start with the table from day one to avoid a scalar→table migration:
```janet
(def *render* @{:path "target/janet-render.png"})   # add :samples :max-depth :background :annotate? etc. later
```
Live use: `(put *render* :path "frame-01.png")` then `(render)`. Rust `do_render` (src/main.rs) reads `:path` at render time instead of the hard-coded `out`. Open question: whether `*film*` `[w h]` (currently scene-side via set-film) should fold in as `:width`/`:height` render params.

**Why:** keeps `(render)` an imperative trigger vs. declarative render state (mirrors how `*shapes*`/`*camera*` are data read by `(scene)`); also sidesteps the render-coalescing path-ambiguity (bursts of render collapse into one, so a per-call filename arg could be lost).

**How to apply:** the one new bit of plumbing is reading a Janet **string** into Rust — current callbacks only read numbers via `argf`; needs `janet_unwrap_string` + string length allowlisted in build.rs (same pattern as the `janet_gcroot` addition for [[project-ray-janet-register-scene]]). Relates to [[project_ray_janet_poc]] and [[project_ray_next_steps]].
