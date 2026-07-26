---
name: project-ray-janet-scene-architecture
description: ray-janet-poc design rationale — scene-as-Janet-data (immediate mode) vs retained live scene in Rust; why current model kept; revisit-later note
metadata: 
  node_type: memory
  type: project
  originSessionId: 478f80b7-f486-465b-a09b-289918195403
---

Design rationale for ray-janet-poc's scene model (recorded 2026-07-26; **user wants to study later**, not acted on now). Question raised: why push a fresh scene copy into Rust on every `(render)` instead of keeping a persistent "live scene" in Rust that Janet mutates via add/remove/clear calls?

Framing: it's **retained mode** (proposed: Rust owns a persistent scene, Janet mutates it) vs **immediate mode with retained state in Janet** (current: `*shapes*`/`*camera*`/… are the source of truth as Janet data; Rust rebuilds a throwaway `Scene` each render by re-running `(scene)` which pushes via `%`-callbacks). Real question = where the single source of truth lives.

**Why current model kept (decision: keep it for the POC):**
- Single source of truth → no two-copy sync/drift bugs; Rust scene is a pure function of Janet data.
- Snapshot/undo/serialize/procedural scenes for free (scene is data); makes the 0-diff parity check easy.
- Hot-swap ([[project-ray-janet-render-params]] era `register-scene`) + live-reload trivial.
- Smaller, uniform Rust API (builder callbacks only, no object identity/remove-by-handle) — matters for the ECL/Janet/Steel push-API benchmark parity ([[project_embedded_lang_benchmarks]]); a stateful handle API would need per-language GC/lifetime mgmt and diverge.
- Statelessness: every render `reset()`s, no accumulated corruption.

**Where retained mode actually wins (revisit triggers):** large scenes + incremental edits where push cost approaches render cost; **retained + incrementally-refit BVH** (the real prize as the tracer matures — currently linear, no BVH); stable object identity for animation. Not yet: push is ~0.02–0.4 ms vs hundreds of ms render, so full rebuild-per-render is free now.

**Trap:** retained only pays off if Rust becomes the *sole* source of truth (Janet holds no scene data, just commands); keeping both = worst of both (two copies to sync) and loses "scene as inspectable Janet data" (`(get *shapes* 0)`).

**How to apply / recommendation:** keep data-in-Janet source of truth. When perf motivates change, do a **hybrid** (keep Janet authoritative): dirty-flag + incremental push of only changed shapes, or retained BVH in Rust invalidated/refit on change — captures retained efficiency without the sync problem. Relates to [[project_ray_janet_poc]], [[project_ray_next_steps]].
