---
name: ray-next-steps
description: "ray POC next steps: Janet Emacs integration complete (comint + completion); ECL Slynk wired; next candidates: ECL completion, multi-POC comparison, or shader hot-reload."
metadata: 
  node_type: memory
  type: project
  originSessionId: abd31d05-4f5f-4d33-a4de-fcacef7d0773
---

## Completed

- Janet (port 4007): `emacs/janet-mode.el` — comint REPL, send-sexp/defun/region/buffer keybindings, live CAPF completion via `janet--sync-eval` + `(curenv)` query. Works with corfu/company. Docs updated (§3 completion, PDF regenerated).
- ECL (port 4005): Slynk server, SLY connects via `M-x sly-connect localhost 4005`. `(render)` / `(set-albedo i r g b)` / `(quit)` work from the REPL.

## Open / next

- ECL: no completion yet — could do same CAPF pattern using Slynk's `swank:simple-completions`, or a separate TCP eval connection.
- Both POCs: consider a shared Emacs package (`ray-poc.el`) that auto-detects the language by port.
- Stretch: hot-reload a Janet shader function without re-rendering the whole frame.

**Why:** Janet and ECL are the benchmark front-runners (ECL 0.09 µs, Janet 0.27 µs tex). Better Emacs tooling makes iterative shader work faster.

**How to apply:** Janet integration is the reference implementation; use it as the template for ECL or any future POC.
