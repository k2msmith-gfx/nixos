---
name: ray-ecl-integration
description: "ECL scripting for ray via push architecture (Lisp calls Rust API). REVERTED off ray main 2026-07-25 → now lives ONLY on the ecl-scripting branch (origin/ecl-scripting @2045750); ray main is back at 9888b98. Branch verified still builds. Architecture notes below still accurate."
metadata: 
  node_type: memory
  type: project
  originSessionId: 909e0d2a-a13e-4498-b883-790f8e87ca7c
---

> ⚠️ **STATUS 2026-07-25 — reverted off `ray` main.** This ECL integration was last night's work on `ray` main (commits `ead65c2`, `47655e1`, `2045750` on `9888b98`). At the user's request it was **reverted**: `ray` main reset to `9888b98` (pre-ECL) and the three commits preserved on the **`ecl-scripting`** branch. That branch is now **remote-only** — pushed to `origin/ecl-scripting` (@`2045750`), local branch deleted; `ray`'s GitHub main force-pushed to `9888b98`. Verified the branch **still builds** (fresh `cargo clean -p ray` + `nix develop .#ecl` → `cargo build --features ecl --bin ray-ecl`, rc=0, ECL 26.5.5). Recover with `git checkout -b ecl-scripting origin/ecl-scripting`. Everything below still accurately describes the code **on that branch** — it's just not on `ray` main anymore. The parallel Janet POC took this same push architecture ([[ray-janet-poc]]).

ECL (Common Lisp) scripting — code lives on the `ecl-scripting` branch of the `ray` project (`/Users/kevinsmith/Documents/devel/rust/ray`), no longer on main. See [[ray-ecl-poc]] for the prior pull-model POC this evolved from.

**Why:** Chose ECL for `ray` scripting. Moved from the POC's *pull* model (Rust walks a Lisp `*scene*` plist) to a *push* model (Lisp calls Rust API functions like `add-sphere`). User's 4 steps: (1) integrate into real project, (2) push method, (3) demo scene loaded from Lisp not hard-coded in main, (4) skip Lisp shaders — native Rust shaders only for now.
**How to apply:** Build/run via the ECL feature + dedicated Nix shell (below). Pure-Rust builds stay Nix-free.

## Architecture: push (Lisp → Rust)

- Rust registers `%`-prefixed callbacks via `ecl_def_c_function(sym, fn, narg)` + `ecl_make_symbol(name, "CL-USER")`. Names must be UPPERCASE (reader up-cases).
- Callbacks are `unsafe extern "C" fn(cl_object, ...) -> cl_object`, transmuted to ECL's untyped `cl_objectfn_fixed = cl_object(*)()`. Args read with `ecl_to_double(o) as f32`. Arity limit is 63.
- A thread-local `SceneBuilder` (RefCell) accumulates film/camera/ambient/lights/shapes + a "current material". `%mat-*` build the current material; the next `%add-sphere/plane/rect` consumes it.
- `build_scene()` = reset builder → `eval("(scene)")` → `finish()` → (Scene, Film). Re-running `(scene)` each render is what makes live edits take effect.

## Files (all ECL code feature-gated)

- `src/scenes.rs` — **single source of truth** for the demo scene: `pub fn demo_scene(aspect) -> Scene`. Uses `crate::` paths so it compiles into both the `ray` bin's module tree (`mod scenes;` in main.rs) and the lib (`pub mod scenes;`). No more hand-synced duplicate.
- `src/scripting/mod.rs` — FFI, SceneBuilder, all `%` callbacks, `register_api()`, `build_scene()`, `eval_truthy()`. `#[cfg(feature="ecl")] pub mod scripting;` in lib.rs.
- `src/bin/ray-ecl.rs` — boot, register, load prelude+scene, render, parity check, Slynk loop. Parity check calls `ray::scenes::demo_scene()` (no local copy).
- `scripts/prelude.lisp` — ergonomic wrappers (`material` w/ &key, `add-sphere`, `set-camera`, ...) over the flat `%` callbacks.
- `scripts/scene.lisp` — scene as **editable Lisp data** (`*film* *camera* *ambient* *lights* *shapes*`, each shape a plist w/ a `make-mat` :mat plist) + `emit-*` helpers + `(scene)` that pushes the data. NOT Rust-read — Lisp iterates and calls the push API (still "push").
- `scripts/live.lisp` — granular live-edit setters: material (`set-albedo/specular/shininess/reflectivity/shader I ...`) + geometry (`set-center I x y z`, `set-radius I r`, sphere-only). Shape index aliases (`*sphere-blue*`=0 ... `*backdrop*`=7), `shape`/`shape-mat` accessors, `(render)`/`(quit)`. Setters mutate `*shapes*` plists in place (pure Lisp, no FFI); next `(render)` re-runs `(scene)` and picks them up.
- `src/main.rs` — now thin: `let scene = scenes::demo_scene(film.aspect());` then render/time/save. Still the pure-Rust reference binary (`ray`). Note: main.rs has its OWN `mod` tree (does not consume the lib crate) — that's why scenes.rs uses `crate::` paths and is declared in both main.rs and lib.rs.

Demo scene now exists in exactly two places: Rust (`scenes::demo_scene`, one source consumed by both `ray` and the ECL parity check) and Lisp (`scripts/scene.lisp`). The parity check diffs them — 0 pixels.

## Ergonomic pattern (prelude)

`(add-sphere '(-2.45 -0.15 -2.6) 0.35 (material :albedo '(0.3 0.5 0.9) :specular '(1 1 1) :shininess 16))`
— `material` emits the `%mat-*` sequence (side effects → current material) and returns nil; CL's left-to-right arg eval guarantees it runs before `%add-sphere` reads the material. The shape's `material` param is `(declare (ignore))`d. Relies on eval order — documented, works (parity exact).

## Build & run (non-obvious)

Two Nix dev shells in `ray/flake.nix`:
- `devShells.default` — pure-Rust, `mkShellNoCC` on Darwin (protects system clang). `cargo build`/`test` need no ECL.
- `devShells.ecl` — `pkgs.mkShell` (nix cc + clang + libclang + ecl). **Required** for ECL builds.

```sh
cargo build                                    # pure Rust, Nix-free
nix develop .#ecl --command cargo build --features ecl --bin ray-ecl
nix develop .#ecl --command bash -c \
  'DYLD_LIBRARY_PATH="$ECL_HOME/lib" ./target/debug/ray-ecl'
```

## Two gotchas solved

1. **Darwin linker `-liconv`**: the default `mkShellNoCC`/system-clang path can't resolve `-liconv` when linking bindgen's build script inside the shell. Fix: a **separate `devShells.ecl`** using nix's cc/stdenv (the POC's proven recipe). Do NOT add ECL to the default shell.
2. **Edition 2024 + bindgen 0.70**: bindgen emits `extern "C" {` blocks without `unsafe`, rejected by edition 2024. `build.rs` post-processes: `.replace("extern \"C\" {", "unsafe extern \"C\" {")`. Only touches block decls, not `extern "C" fn` pointer types.

Also: `bindgen` is an always-on build-dependency (compiles without libclang via clang-sys runtime loader); `build.rs` only *invokes* it when `CARGO_FEATURE_ECL` is set (build scripts get features as env vars, NOT `#[cfg]`).

## Status

- [x] Stage 1: scaffolding (feature gate, build.rs, flake, `%ping` callback proving Lisp→Rust)
- [x] Stage 2: full push API + prelude + demo scene. **Parity: 0 pixel diffs vs pure-Rust reference (exact).** Slynk preserved on 4005; `(render)` re-runs `(scene)`.
- Perf: ECL render 541ms; pure-Rust `ray` 455ms (full recursive integrator, not the POC's lambert-only path).

## Live-edit setters (done)

Granular setters restored via the **data-driven scene**: `(scene)` builds from mutable `*shapes*`, so pure-Lisp setters that mutate `*shapes*` persist across re-renders. Chose this over mutating a built Rust `Scene` because `Scene::new` partitions shapes (finite→BVH, infinite→flat list) and the **BVH stores its own copies** — in-place mutation would fight the copies + reindexing. Verified end-to-end: a setter changing sphere 0's albedo produced 10166 parity diffs (vs 0 baseline), confirming it propagates through `(scene)`→push→render.

## Not done yet (deferred)

- Lisp-scripted shaders (step 4 said revisit later) — shaders are native Rust `ShaderKind`, selected by `:shader` keyword → int code (0 lambertian, 1 phong, 2 blinn-phong, 3 normal-as-color).
- Setters cover material (albedo/specular/shininess/reflectivity/shader) + sphere geometry (center/radius). Plane `:y` and rect `:scale`/`:rotation-x`/`:translation` setters not added yet; `*shapes*` schema supports adding them the same way. Lights are not yet live-editable.
