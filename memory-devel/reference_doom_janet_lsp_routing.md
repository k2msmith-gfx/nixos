---
name: reference_doom_janet_lsp_routing
description: "How the user's Doom Emacs surfaces janet-lsp diagnostics (flycheck-eglot, not flymake) + a stale janet-live-mode load path"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 4f03eec1-51d8-4e3e-9ed3-e0962596582d
---

User's Doom Emacs (config in `~/nixos/doom`): `:checkers syntax` is enabled **without `+flymake`** → Doom uses **flycheck**, and `flycheck-eglot` is installed, so eglot/LSP diagnostics are routed **janet-lsp → eglot → flycheck-eglot → flycheck** display. Consequences that wasted a debugging round on ray-studio:
- `M-x flymake-mode` and `eglot-stay-out-of '(flymake)` do **nothing** to LSP diagnostics here — the display path is flycheck, not flymake.
- The `[!] compile error - unknown symbol *camera*` seen editing `scene.janet` was janet-lsp analysing the file in isolation (can't see prelude.janet's `*film*/*camera*/*ambient*/*lights*/*shapes*` vars). Purely cosmetic — the running binary accepts the edits (verified `(set *camera* …)` + `(render)` over TCP 4007).
- eglot reaches janet **only via `ray-janet-coexist.el`** (it registers the janet-lsp server + a `janet-mode-hook`). Doom's `:lang janet` module does NOT wire up eglot; `:tools (lsp +eglot)` only auto-starts eglot for modes that opt in via `lsp!`/`set-eglot-client!`, which janet doesn't. So: no coexist loaded ⇒ no janet-lsp ⇒ no diagnostics.
- **Fix applied (ray main @08ab18a):** `ray-studio` now defaults janet-lsp OFF (`ray-studio-use-janet-lsp` nil) — gates the coexist load + neutralises `eglot-ensure` across the scene find-file. Set the var to t to opt back in. To kill flycheck diagnostics generally in a buffer here, use `(flycheck-mode -1)`, not flymake.

**Stale path to clean up:** `~/nixos/doom/config.el:45-48` still loads `janet-live-mode.el` from the **old `ray-janet-poc`** repo (`~/Documents/devel/rust/ray-janet-poc/emacs/…` or `~/devel/rust/ray-janet-poc/…`), which is now redundant — the canonical copy lives in the main **ray** repo `emacs/`. So `(require 'janet-live-mode)` in ray-studio picks up the POC version (already `provide`d). Works today (near-identical), but should be repointed at `ray/emacs/janet-live-mode.el`. See [[reference_repo_paths]], [[ray-next-steps]].
