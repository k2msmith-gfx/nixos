---
name: ray-next-steps
description: "ray POC next steps (updated 2026-07-25): Janet POC migrated to push arch + Corfu auto-popup completion + docs/SETUP, all merged to ray-janet-poc main & pushed. ECL reverted off ray main onto ecl-scripting branch. Next: ECL completion, shared ray-poc.el, shader hot-reload."
metadata: 
  node_type: memory
  type: project
  originSessionId: abd31d05-4f5f-4d33-a4de-fcacef7d0773
---

## Completed

- **Janet POC — push-architecture migration (2026-07-25):** full ECL parity, scripted shaders removed, 0-diff parity. See [[ray-janet-poc]]. Merged to `ray-janet-poc` main and pushed; remote switched to SSH.
- **Janet Emacs (port 4007):** `emacs/janet-mode.el` — comint REPL + send keybindings + CAPF completion. Now with **Corfu auto pop-up** (buffer-local `corfu-auto`) + a **client-side symbol cache** (TTL + invalidate-on-send) so as-you-type completion is round-trip-free. `janet-render`/`janet-quit` fixed to `(render)`/`(quit)`.
- **Docs:** `docs/emacs-janet-workflow.html`/`.pdf` rewritten for push arch (pull model + scripted shaders removed); `make docs` target regenerates the PDF via headless Chrome; `SETUP.md` added (new-machine build guide — siblings layout, Nix shell, DYLD/LD path).
- **ECL — reverted off ray main → `ecl-scripting` branch (remote-only).** See [[ray-ecl-integration]]. Slynk 4005 + push arch preserved on that branch; verified still builds.

## Open / next

- **ECL completion** — still none; when ECL work resumes (from the branch), apply the same CAPF + Corfu + cache pattern as Janet (via Slynk `swank:simple-completions` or a TCP eval connection).
- **Shared `ray-poc.el`** — one Emacs package auto-detecting the language by port (4007 Janet / 4005 ECL); Janet's mode is the reference template.
- **Shader hot-reload** — stretch: re-run a scripted shader without re-rendering the whole frame (note: Janet POC no longer has scripted shaders, so this would be new work).

**Why:** Janet and ECL are the benchmark front-runners (ECL 0.09 µs, Janet 0.27 µs tex). Better Emacs tooling makes iterative shader work faster.

**How to apply:** Janet integration is the reference implementation; use it as the template for ECL or any future POC.
