---
name: ray-next-steps
description: "Next focus: Emacs integration for Janet and/or ECL ray POC — live shader editing from Emacs."
metadata: 
  node_type: memory
  type: project
  originSessionId: abd31d05-4f5f-4d33-a4de-fcacef7d0773
---

Next session focus: pick 1–2 candidates (Janet and ECL are the front-runners) and explore Emacs integration for live shader/scene editing.

**Why:** Janet and ECL both already have Emacs-friendly server setups (Janet TCP eval on port 4007, ECL Slynk/SLY on port 4005). The goal is smooth live editing of shaders from Emacs — edit a function, re-render, see the result.

**How to apply:** Prioritise this over new POC stages. ECL has SLY already wired up (M-x sly-connect). Janet has a raw TCP REPL — may want a proper Emacs minor mode or inf-janet style integration.

## Current state

- ECL (port 4005): Slynk server running, SLY connects via `M-x sly-connect localhost 4005`. `(render)` / `(set-albedo i r g b)` / `(quit)` work from the REPL.
- Janet (port 4007): TCP eval server, stdin REPL fallback. No Emacs package wired up yet.

## Open questions for next session

1. Is inf-janet or a custom comint mode the right approach for Janet?
2. Should both POCs get the same Emacs UX, or lean into ECL/SLY being the primary workflow?
3. Any interest in displaying the render output image inside Emacs (e.g. via `M-x image-mode` or iimage)?
