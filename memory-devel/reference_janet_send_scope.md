---
name: reference_janet_send_scope
description: "ray-studio/janet-live — scene edits silently not rendering = C-x C-e sent a sub-form, not the whole (set *shapes* ...); use C-M-x"
metadata: 
  node_type: memory
  type: reference
  originSessionId: d730826c-dfbd-4229-9830-5456f9663e55
---

Symptom that wasted a debug session (2026-08-15): editing a sphere's albedo /
mesh segments inside `scripts/scene.janet`'s `*shapes*`, sending it, then
`(render)` shows **no change** — while editing `*lights*` the same way DOES work.

Not a bug. It's **eval scope**, matching SLIME/SLY exactly:
- `C-x C-e` = `janet-send-last-sexp` → the sexp **before point**. On the ~40-line
  `(set *shapes* @[...])` form this grabs the inner `@{...}` shape table your
  point sits in — it evals and echoes a result, but never re-runs the `set`, so
  the global `*shapes*` keeps its old value.
- `C-M-x` = `janet-send-defun` → the **whole top-level form** at point. This is
  the one that rebinds `*shapes*`.
`*lights*` "worked" only because it's a small form so point landed after the
whole `(set *lights* ...)`.

Fix = usage: use **C-M-x** (or `C-c C-b` send-buffer) for a big top-level form;
`C-x C-e` only for one-off expressions. The render/env path is fine — verified by
re-binding the full `(set *shapes* ...)` over the REPL and watching it re-render
(a single sphere, 24 ms → 1.8 ms). Both keys really are bound
(`janet-live-mode.el`) and both are in the right-click context menu.

See [[project_ray_interactive_editor]].
