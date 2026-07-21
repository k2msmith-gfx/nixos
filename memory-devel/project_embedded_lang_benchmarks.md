---
name: embedded-lang-benchmarks
description: "Benchmark suite comparing 6 scripting engines embedded in Rust for a ray tracer POC. v4 report (bench-report-v4.html) with ECL/Janet/Steel optimizations complete."
metadata: 
  node_type: memory
  type: project
  originSessionId: 431dfea2-1a06-416f-bfd1-10c0d0145383
---

Built a benchmark suite comparing six scripting/Lisp/Scheme engines embedded in Rust.
Motivation: evaluating which language to use for user-defined shaders in a ray tracing POC.

**Why:** The ray POC needs a scripting layer for hot shader functions called per-ray. The compile-once / call-many (hot-call) path matters most — parse+eval per ray is never viable.

**How to apply:** ECL leads shader-math hot-call (tex=0.09 µs, dot_cos=0.12 µs). Janet is second (0.23–0.27 µs). Steel is the pure-Rust sweet spot (0.17–0.69 µs). LuaJIT is **disqualified** — no JIT on ARM64/Apple Silicon. All three POCs (ECL, Steel, Janet) have completed Stage 4 optimizations.

## Repos (all under k2msmith-gfx GitHub org)

- [ecl-test](https://github.com/k2msmith-gfx/ecl-test) — ECL 26.5.5, FFI via bindgen, nix dev shell required (`source .direnv/flake-profile-*.rc`)
- [steel-test](https://github.com/k2msmith-gfx/steel-test) — Steel 0.8, pure Rust
- [scheme-rs-test](https://github.com/k2msmith-gfx/scheme-rs-test) — scheme-rs 0.2, pure Rust
- [rhai-test](https://github.com/k2msmith-gfx/rhai-test) — Rhai 1.25, pure Rust
- [lua-test](https://github.com/k2msmith-gfx/lua-test) — LuaJIT 2.1 via mlua 0.12, needs system LuaJIT
- [janet-test](https://github.com/k2msmith-gfx/janet-test) — Janet 1.41.2, FFI via bindgen, nix dev shell required (JANET_HOME + clang/libclang)
- [embedded-lang-benchmarks](https://github.com/k2msmith-gfx/embedded-lang-benchmarks) — PDF + HTML report, README with links

## Local paths

- `/home/kevin/devel/ecl-test`
- `/home/kevin/devel/steel-test`
- `/home/kevin/devel/scheme-rs-test`
- `/home/kevin/devel/rhai-test`
- `/home/kevin/devel/lua-test`
- `/home/kevin/devel/janet-test`
- `/home/kevin/devel/embedded-lang-benchmarks`
- `/home/kevin/devel/bench-report-v2.pdf` — latest PDF report

## Benchmarks

Five functions measured across two call paths each:
- `(+ 1 2)` — trivial arithmetic
- `factorial(20)` — recursive calls
- `sum-to(1000)` — tight loop
- `tex(u,v)` — sine-based UV shader
- `dot_cos(ax,ay,az,bx,by,bz)` — dot product + cosine

## Hot-call results v4 (µs/call, lower is better)

| Benchmark     | ECL      | Steel | Rhai  | LuaJIT   | scheme-rs | Janet |
|---------------|----------|-------|-------|----------|-----------|-------|
| (+ 1 2)       | 2.08     | 0.17  | 0.14  | 1.26     | —         | 0.14  |
| factorial(20) | 3.35     | 2.44  | 22.1  | **0.24** | 43.0      | 1.85  |
| sum-to(1000)  | 6.53     | 228   | 179   | **1.40** | 884       | 22.7  |
| tex(u,v)      | **0.09** | 0.67  | 1.48  | 0.14     | 2.44      | 0.27  |
| dot_cos       | **0.12** | 0.69  | 2.05  | 0.22     | 2.83      | 0.23  |

v3 optimizations: ECL `(declare (type single-float …) (optimize speed 3))` + explicit `(compile 'fn)`;
Janet `janet_fiber_reset + janet_continue` (zero-alloc hot calls).
v4 optimization: Steel `extract_value` + `call_function_with_args_from_mut_slice` (skip name lookup + Vec alloc).

## Key findings (v4)

- **ECL** now leads shader-math hot-call with type declarations — **0.09 µs dot_cos, 0.12 µs tex** (beats LuaJIT). Requires `(compile 'fn)` explicitly after `(load ...)` and `(declare (type single-float …) (optimize speed 3 safety 0))`. Nix dev shell required.
- **LuaJIT** wins compute-heavy loops on x86-64 — tracing JIT compiles factorial (0.24 µs) and sum-to (1.40 µs) to native code. **Disqualified as a candidate: the JIT does not support ARM64 (Apple Silicon), falling back to interpreter and losing its entire advantage. Cannot be used cross-platform.**
- **Janet** is fast and pixel-perfect — 0.14 µs trivial, 0.27 µs tex, 0.23 µs dot_cos via `janet_fiber_reset + janet_continue`. `janet_call` panics outside a fiber frame; always use `janet_pcall` + fiber reset. Nix dev shell required.
- **Steel** is best pure-Rust option — no FFI, no system deps. `extract_value` + `call_function_with_args_from_mut_slice` drops trivial-call to 0.17 µs. Shader-math (tex, dot_cos) ~0.67–0.69 µs — name lookup wasn't the bottleneck. `call_function_by_name_with_args` (Vec alloc per call) is the v3 path; avoid on hot paths.
- **Rhai** fast for trivial exprs (0.14 µs add, AST tiny), stalls on loops (tree-walk, 179 µs sum-to).
- **scheme-rs** Cranelift JIT generates excellent code but ~2–3 µs ContBarrier overhead per call dominates.

## Ray POC repos (Stage 4 complete for all three)

See [[ray-ecl-poc]], [[ray-steel-poc]], [[ray-janet-poc]] for details.

- `ray` crate at `/home/kevin/devel/ray` is a lib+bin so POCs can depend on it
- ECL POC:   2.6× Lambert overhead (compile + type decls + single-float; 9+3 heap allocs/call); Slynk port 4005
- Steel POC: 4.1× Lambert overhead (bytecode VM floor); TCP eval port 4006
- Janet POC: 0.9× Lambert overhead (fiber reset); TCP eval port 4007
- Report: `bench-report-v4.html` in embedded-lang-benchmarks repo
