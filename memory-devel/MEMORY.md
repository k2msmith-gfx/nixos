# Memory Index

- [Embedded lang benchmarks](project_embedded_lang_benchmarks.md) — 6-language Rust embedding benchmark suite; v4 report complete; ECL leads shader-math (0.09 µs), Janet 2nd, Steel best pure-Rust; LuaJIT disqualified (no ARM64 JIT); all ray POCs at Stage 4
- [ray-ecl-integration](project_ray_ecl_integration.md) — ECL now in the REAL ray project (./ray); push architecture (Lisp calls Rust %-callbacks); feature-gated (`--features ecl`, `nix develop .#ecl`); parity-exact vs pure-Rust ref; Slynk 4005 preserved; Darwin -liconv + edition-2024 bindgen gotchas solved
- [ray-ecl-poc](project_ray_ecl_poc.md) — standalone ECL POC (pull model, precursor to ray-ecl-integration); Slynk (port 4005); Stage 1+2+3+4 done; 2.6× Lambert (Linux), 1.1× (macOS ARM64); tex=0.18 µs Linux / 0.05 µs macOS; SIGFPE footgun, Nix dev shell required
- [ray-steel-poc](project_ray_steel_poc.md) — Steel (Scheme) scene + TCP eval server (port 4006); Stage 1+2+3+4 done; 4.1× Lambert (Linux), 2.1× (macOS); tex=0.65 µs Linux / 1.47 µs macOS; pure cargo build
- [ray-janet-poc](project_ray_janet_poc.md) — Janet 1.41 POC; MIGRATED 2026-07-25 to PUSH architecture (full ECL parity): Rust registers %-cfunctions, Janet calls them; scripted shaders removed; 3-file prelude/scene/live layout; parity 0 diffs; TCP 4007 + comint + CAPF kept; Nix dev shell required
- [ray POC collaboration feedback](feedback_ray_poc_collaboration.md) — stage-by-stage confirmation, honest assessments wanted, one-word approval means implement directly
- [ray next steps](project_ray_next_steps.md) — Janet Emacs integration complete (comint + completion); ECL Slynk wired; next: ECL completion or shared ray-poc.el
