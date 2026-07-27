---
name: reference_janet_emacs_signature_help
description: "Emacs/Doom knobs to disable eglot's automatic dim signature-help line for Janet (kept ON as of 2026-07-26 per user; noted for future)"
metadata: 
  node_type: memory
  type: reference
  originSessionId: a5b14c6f-813c-426a-875d-64418cd7b2eb
---

In the [[ray-janet-poc]] Emacs setup, once eglot connects to janet-lsp two doc surfaces show for `(add-sphere ` etc.:
- **dim parameter string, automatic** = eglot **eldoc signature help** (shows as you fill in args).
- **box on `<TAB>`** = the corfu + corfu-popupinfo **completion doc popup** (our feature; see [[ray-next-steps]] janet-lsp coexistence).

User decided 2026-07-26 to **KEEP BOTH** (they're complementary). Drop commands saved in case they want to disable the automatic signature line later:

- Turn off eglot's signature help entirely, keep the TAB completion box:
  ```elisp
  (setq eglot-ignored-server-capabilities '(:signatureHelpProvider))
  ```
- Keep it but only on demand: leave eglot as-is, raise `eldoc-idle-delay`, and summon with `M-x eldoc`.

(The completion doc box itself is toggled separately via `corfu-popupinfo-mode` / `janet-poc-auto-complete`.)
