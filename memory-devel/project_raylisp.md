---
name: project_raylisp
description: raylisp — pure-SBCL Common Lisp raytracer subset built to benchmark against the Rust/glam ray renderer
metadata: 
  node_type: memory
  type: project
  originSessionId: 326c3600-3f3a-4e80-8b1f-adc5478fe742
---

**raylisp** — a hand-rolled Common Lisp raytracer *subset*, grown VERY incrementally as a
performance-evaluation counterpart to the Rust `ray` renderer (see [[reference_repo_paths]],
[[project_embedded_lang_benchmarks]]). Started 2026-07-30.

- **Location/remote:** `~/devel/raylisp` → `git@github.com:k2msmith-gfx/raylisp.git` (**private**, SSH, same owner/convention as `ray`). Local `main` tracks `origin/main`.
- **Runtime:** pure **SBCL**, no embedded languages. Nix flake dev shell via `sbcl.withPackages` (alexandria + fiveam) — no `~/quicklisp` bootstrap. `.envrc` = `use flake`; `CL_SOURCE_REGISTRY="$PWD//"` (NO trailing `:` — the withPackages wrapper already appends the one allowed "inherit" marker).
- **Editing:** Doom Emacs + **Sly**. Requires the flake env in Emacs, so Doom's `:tools direnv` module was enabled (was commented out) — deployed via home-manager (`~/nixos/home/common.nix` xdg.configFile → `nswitch` + `doom sync`). Sly *spawns* an inferior SBCL (unlike ray's Janet live-REPL which Emacs merely *connects* to over TCP), which is why Emacs needs the env and ray didn't.
- **Design decision:** hand-rolled math, NOT a library (rejected `sb-cga` as old/awkward; `_3d-math`/origin also available). Numbers are **single-float** to match glam's `Vec3<f32>` for apples-to-apples benchmarking. `mat4` is **column-major** to match glam (and OpenGL); accessor `(mref m i j)` hides layout; literal `(mat4 …)` still takes row-major reading order.
- **Testing strategy = the `cargo test` analog:** FiveAM, `raylisp/test` ASDF system, run via `asdf:test-system "raylisp"` (fails loudly on red) or `(raylisp/test:run-tests)` in Sly. Structure mirrors Rust's per-file `#[cfg(test)] mod tests`: root suite `RAYLISP` + one child suite per source module.
- **Done so far (all Rust `ray.rs` behavior ported, 44 checks green):** vec3, quat (from-axis-angle), mat4 (identity/translate/scale/from-quat/mul/inverse via Gauss-Jordan in double), ray (ray-at = Rust `eval`, ray-transform, print-object = Rust Display). `eval` named `ray-at` since `eval` is reserved in CL.
- **Full renderer now landed** (pulled 2026-08-02, was well behind): shapes (sphere/plane/rect/cuboid + aabb/geometry/shape), shading (light/material/shader/scene), `render.lisp` (serial `render` + `render-parallel` = sb-thread, row-striped, all online CPUs), `scenes.lisp` (`demo-scene`), `examples/bench.lisp`, full FiveAM tests. Perf-pass commits added `(speed 3)` + ~20 `dynamic-extent` sites.
- **BENCHMARK (measured 2026-08-02, 12-core box, 1280×720 demo-scene). The remembered "6–9× slower" is STALE:**
  - serial: Rust (`RAYON_NUM_THREADS=1`) **1.57 Mpix/s** vs raylisp **0.63** = **~2.5×**
  - parallel: Rust (all threads) **~10.4** vs raylisp `render-parallel` **~1.9** = **~5.5×**
  - raylisp parallel scaling is only **~3×** on 12 cores vs Rust's ~6.6× — **GC-bound**: `(time)` shows **966 MB consed/frame**, ~10% GC serially, and SBCL's stop-the-world global GC throttles the 12-thread run.
  - `(speed 3)` already applied by bench (`proclaim` + `:force t`); `(safety 0)` tested = **zero difference** (declarations already elide checks). Policy levers exhausted.
- **Highest-value remaining work = kill the per-frame allocation** (escaping `vec3`s stored in hit records / returned up the recursive `radiance`+shader chain — `dynamic-extent` can't catch escaping values; needs scalarizing hit records + hot shading paths). Double win: modest serial gain, large parallel-scaling gain. SIMD gap (glam vectorizes, SBCL scalar) is fundamental and only helps serial — not worth it. Next diagnostic: `(sb-sprof:with-profiling (:mode :alloc ...) (run-bench))` to name top allocators.
- **Running the bench headless (no direnv):** `cd ~/devel/raylisp && nix develop --command sbcl --non-interactive --load examples/bench.lisp` (ASDF finds deps via the flake's `CL_SOURCE_REGISTRY`; a bare `sbcl` misses alexandria/fiveam).
