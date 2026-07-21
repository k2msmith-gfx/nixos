---
name: ray-ecl-poc
description: "ECL-scripted ray tracer POC: scene description + Slynk/SLY live editing. Stage 1+2+3+4 complete. 0.9× Lambert overhead with type decls + compile."
metadata: 
  node_type: memory
  type: project
  originSessionId: 431dfea2-1a06-416f-bfd1-10c0d0145383
---

POC embedding ECL (Common Lisp) into the `ray` crate as a scripting layer.
See [[embedded-lang-benchmarks]] for the benchmark context.

**Why:** Evaluate ECL for live shader/scene scripting; compare against Steel ([[ray-steel-poc]]).
**How to apply:** All four stages done. Be aware of the SIGFPE footgun and Nix dev shell requirement.

## Repos

- Local: `/home/kevin/devel/ray-ecl-poc` (main branch)
- GitHub: `https://github.com/k2msmith-gfx/ray-ecl-poc`
- `ray` dependency: local path `../ray`, `ecl-poc` branch has `lib.rs` + `docs/ecl-poc.md`

## Status

- [x] Stage 1: ECL scene description in `scripts/scene.lisp` — pixel-perfect match vs Rust reference (0 scene-area diffs)
- [x] Stage 2: Slynk server on port 4005 — `M-x sly-connect`, then `(render)` / `(set-albedo i r g b)` / `(quit)`
- [x] Stage 3: ECL Lambert shader — 6.2× overhead (1.803s vs 292ms Rust) via cl_funcall hot-call path
- [x] Stage 4: single-float + compile + type decls → **0.9× overhead** (ECL matches Rust); tex(u,v) microbenchmark added

## Build environment (non-obvious)

ECL requires a Nix dev shell — not just `cargo build`:

```sh
# Activate dev shell (same flake.nix as ecl-test)
source /home/kevin/devel/ecl-test/.direnv/flake-profile-a5d5b61aa8a61b7d9d765e1daf971a9a578f1cfa.rc

# Build
cargo build

# Run (needs LD_LIBRARY_PATH)
LD_LIBRARY_PATH="$ECL_HOME/lib:$LD_LIBRARY_PATH" ./target/debug/ray-ecl-poc
```

Cargo.toml uses `edition = "2021"` — bindgen 0.70 emits `extern "C"` blocks without `unsafe`,
which is rejected by Rust 2024 edition.

## Critical operational finding: SIGFPE footgun

ECL installs a global SIGFPE signal handler at `cl_boot` that intercepts floating-point
exceptions from ALL code — including Rust, glam, and rayon. Without disabling it, glam ops
like `Mat4::inverse()` and `normalize_or_zero()` trigger ECL's debugger, which crashes
catastrophically in embedded mode (`SI:*BREAK-LOCALS*` unbound).

**Fix — must be the first eval call after `cl_boot`:**
```rust
eval("(ext:trap-fpe t nil)");
```

Symptom without fix: intermittent crash at random `cl_eval` calls, not where the glam op is.
Diagnosis: crash always at the NEXT eval after a glam FP op, because the deferred exception
fires on re-entry into ECL.

## Scene description pattern

`scripts/scene.lisp` defines `*scene*` as a property list (plist) with `:film`, `:camera`,
`:ambient`, `:lights`, `:shapes`. Each shape has a `:type` keyword (`:sphere`, `:plane`, `:rect`)
and a `:mat` plist built by `(make-mat &key albedo specular shininess ...)`.

Rust reads it with `eval("(getf *scene* :shapes)")` + `ecl_to_double()` for numbers.
The `eval_truthy`, `eval_sym`, `eval_vec3` helpers cover all access patterns.

## Slynk setup

Slynk loader path (Doom Emacs): `~/.config/emacs/.local/straight/repos/sly/slynk/slynk-loader.lisp`
Pre-compiled `.fas` cache used automatically — no recompilation needed.

Contribs that need Quicklisp/ASDF are skipped via a `*debugger-hook*` that continues past
`COMPILE-FILE returned NIL` errors.

## Live editing helpers (scene.lisp)

```lisp
(render)              ; set *render-requested* → re-render within 100 ms
(quit)                ; set *quit-requested*   → clean shutdown
(set-albedo i r g b)
(set-shininess i s)
(set-reflectivity i r g b)
(set-specular i r g b)
(set-shader i :keyword)
```

Shape indices 0–7: lambertian, phong/glass, phong-backdrop, mirror, blinn-phong,
normal-as-color, ground-plane, backdrop-rect.

## Stage 3: Lambert shader architecture

ECL hot-call path using `cl_funcall` + `ecl_make_double_float`.
Pre-resolve function handle once: `cl_symbol_function(eval("'lambert-shade"))`.
Per pixel: `cl_funcall(10, shade_fn, 9 × ecl_make_double_float(val))`.
Result unboxed via `ecl_to_double(cl_car/cl_cadr/cl_caddr(result))`.

New bindings added: `ecl_make_double_float`, `cl_car`, `cl_cadr`, `cl_caddr`.
Note: `cl_first/second/third` in ECL headers are `#define` aliases for these.
Note: `cl_funcall` narg includes the function: 9 args → `cl_funcall(10, fn, ...)`.

Performance at 1280×720 single-threaded:
- Rust Lambert: 292ms (3.16 Mpix/s)  [Stage 3 baseline]
- ECL Lambert: 1.803s (0.51 Mpix/s) — **6.2× overhead** (was 77.4× with string-eval)  [Stage 3]
- ECL Lambert: **0.9× overhead** (ECL matches Rust) after Stage 4 optimizations
- Pixel diffs: 334,112 (max 1.19e-7, imperceptible — single-float vs f32 rounding)

Stage 4 optimizations (single-float + compile + type decls):
1. `(compile 'lambert-shade)` after load — was benchmarking interpreted bytecode; likely dominant factor
2. `(declare (type single-float ...) (optimize (speed 3) (safety 0) (debug 0)))` — type-specialized native code
3. `ecl_make_single_float` / `ecl_to_float` instead of double — removes f32→f64 upcast, smaller heap objects
   Note: single-float is heap-allocated in ECL 26.5.5 (NOT immediate); only fixnums/chars are immediate

## Stage 4: tex(u,v) microbenchmark
tex(u,v) microbenchmark (2 args, scalar return, single-float, compile+type-decls):
- tex:     0.13 µs/call
- lambert: 0.46 µs/call (9 args + list return)
- ratio:   3.51×  (lambert overhead vs 2-arg floor)

## Known concerns

- SIGFPE handler is a global side effect; easy to forget in a larger embedding.
- Thread safety between Slynk threads and main Rust `cl_eval` calls is informal.
- 9 `ecl_make_single_float` allocs/pixel remain (single-float is heap-allocated in this ECL build).
  Further reduction would require foreign-data bulk arg passing or fixnum-encoded floats.
