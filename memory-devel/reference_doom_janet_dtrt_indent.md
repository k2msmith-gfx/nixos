---
name: reference_doom_janet_dtrt_indent
description: "Doom + a Janet file in a NON-project dir → dtrt-indent crashes janet-mode setup (no colorization, no janet-live menu); fix = exclude janet-mode from the guesser"
metadata: 
  node_type: memory
  type: reference
  originSessionId: d730826c-dfbd-4229-9830-5456f9663e55
---

Symptom (cost a long debug session 2026-08-15): opening a `.janet` file OUTSIDE
a project (e.g. ~/Documents/devel/vc/scenes/monorail-lit.janet) in Doom shows
mode line "Janet" but NO font-lock colorization and the ray janet-live context
menu doesn't appear. The same file inside ~/devel/ray works fine. Error in
*Messages*: `File mode specification error: (wrong type argument
number-or-marker-p nil)`.

Root cause = **dtrt-indent**, NOT Janet/envrc/ray. Doom's `:editor whitespace`
runs `+whitespace-guess-indentation-h` on prog-mode-hook → `dtrt-indent-mode`,
which has no working `janet` support and errors in
`dtrt-indent--skip-to-end-of-match(nil nil nil nil)`. That error aborts
`janet-mode`'s hook run before font-lock + janet-live-mode finish.

Path-specificity explained: `+whitespace-guess-indentation-h` SKIPS the guesser
when `(and (not +whitespace-guess-in-projects) (doom-project-root))` — i.e. it
only runs for files NOT in a project. ~/devel/ray has .git → skipped → fine.
The external dir had no .git/.projectile → guesser runs → crash.

FIX (add to ~/nixos/doom/config.el, then darwin-rebuild + restart — see
[[reference_doom_config_nix_rebuild]]):
`(add-to-list '+whitespace-guess-excluded-modes 'janet-mode)`
Live test without restart: eval that in *scratch*, reopen the file.
Alternative: make the dir a project (`git init`) so Doom skips the guesser.

Debug method that finally worked: `M-x toggle-debug-on-error` then
`M-x janet-mode` (calling the mode directly re-raises hook errors that
`normal-mode` otherwise swallows as "File mode specification error"). A
`debug-on-signal t` capture first pointed at envrc — a RED HERRING (it breaks on
benign caught signals). The bug does NOT reproduce headlessly (needs a live
window). See [[reference_janet_send_scope]], [[reference_doom_janet_lsp_routing]].
