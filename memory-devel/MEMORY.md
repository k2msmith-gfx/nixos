# Memory Index

- [Embedded lang benchmarks](project_embedded_lang_benchmarks.md) — 6-language Rust embedding benchmark suite; v4 report complete; ECL leads shader-math (0.09 µs), Janet 2nd, Steel best pure-Rust; LuaJIT disqualified (no ARM64 JIT); all ray POCs at Stage 4
- [ray-ecl-poc](project_ray_ecl_poc.md) — ECL scene description + Slynk (port 4005); Stage 1+2+3+4 done; 0.9× Lambert overhead (compile + type decls + single-float); tex=0.13 µs; SIGFPE footgun, Nix dev shell required
- [ray-steel-poc](project_ray_steel_poc.md) — Steel (Scheme) scene description + TCP eval server (port 4006); Stage 1+2+3+4 done; 4.1× Lambert overhead; extract_value hot-call (0.17 µs add, 0.67 µs tex); pure cargo build
- [ray-janet-poc](project_ray_janet_poc.md) — Janet 1.41 scene description + TCP eval server (port 4007); Stage 1+2+3+4 done; 0.9× Lambert overhead (fiber_reset); tex=0.27 µs; pixel-perfect; Nix dev shell required
- [ray POC collaboration feedback](feedback_ray_poc_collaboration.md) — stage-by-stage confirmation, honest assessments wanted, one-word approval means implement directly
