---
name: project-ray-release-naming
description: "Naming + crates.io release intents — rename ray-janet binary to something language-neutral (candidate ray-studio); crate name `ray` is taken; release blockers audited 2026-08-17"
metadata: 
  node_type: memory
  type: project
  originSessionId: 58d3279b-d336-4043-b459-fc1a403e25f1
---

**Naming intent (user, 2026-08-17):** rename the `ray-janet` binary to
something language-neutral "at some point" — the embedded language is a
feature, not the product, and it may someday switch (e.g. to Steel).
Candidate discussed: **`ray-studio`** (matches emacs/ray-studio.el + the
"studio" concept; SLIME/CIDER-style shared name). Keep language-specific
names for the `janet` feature flag, internals, and the `janet>` prompt —
only user-facing surfaces go neutral. Rename touches: Cargo.toml [[bin]],
src/bin/ray-janet.rs, ~67 elisp refs, docs, user's nixos aliases
(rayj/rayjr/rayjb in darwin.nix). Do it in the same pass as the crate
rename, before any public release freezes names.

**crates.io audit (2026-08-17):** repo stays private until user is ready to
release ([[reference_repo_paths]]). Blockers found: (1) crate name `ray`
taken on crates.io (abandoned 2020 squat) — new name needed; (2)
`scripts_dir()` bakes CARGO_MANIFEST_DIR into the binary → embed
prelude/live.janet via include_str! for `cargo install`; (3) `janet`
feature build.rs panics without JANET_HOME → vendor Janet's amalgamated
janet.c (MIT, designed for embedding) to drop the Nix dependency; (4) no
LICENSE file + no license/description fields in Cargo.toml (also verify
the ab_glyph stamp font's license); (5) crate >10MB cap → package.include
list excluding assets/ (13M) + examples/ (18M). Emacs integration ships
separately (MELPA recipe `:files ("emacs/*.el")` from the same repo, or
load-path instructions initially), never in the crate. Est. ~1 day of work.
