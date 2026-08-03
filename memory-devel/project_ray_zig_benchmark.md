---
name: project_ray_zig_benchmark
description: "Zig 0.16 port of ray tracer — benchmark findings, Janet REPL, LOC comparison, and why Rust was kept"
metadata: 
  node_type: memory
  type: project
  originSessionId: 1a70aa56-f689-417e-bb31-71053b37c6a6
---

Zig 0.16 port of ray at `~/devel/ray-zig` (GitHub: k2msmith-gfx/ray-zig, private), built 2026-08-02 as a benchmark comparison. Full feature parity with the Rust demo scene: BVH, Phong/Blinn-Phong/Lambertian shaders, mirror reflection, refraction + chromatic dispersion, multi-threaded rendering, Janet scripting (push architecture, full REPL).

**Why:** Zig was not chosen for the main repo — Janet FFI already working in Rust and switching would discard that work. Port exists as a benchmark reference and teaching comparison.

## CLI (matches ray-janet)

- `rayz` / `rayzr` — debug / release build + run via `zig build run --`; Janet lib rpath baked in at build time (no DYLD_LIBRARY_PATH needed)
- `rayzb` — release build only
- `ray-zig [--scene <path>] [--out <path>] [--demo]`
  - No flags → bare `janet>` REPL (matches `rayj` with no args)
  - `--scene` → load scene, initial render, then `janet>` REPL
  - `--demo` → render hardcoded Zig scene and exit

## Janet REPL (matches ray-janet behavior)

Boot sequence: prelude.janet → scene.janet (if --scene) → live.janet → initial render → `janet>` loop.
Flag protocol same as Rust: `*render-requested*`, `*save-requested*`, `*quit-requested*` polled after each eval.
`(render)` re-renders; `(save-image "path.ppm")` honours `*save-path*`; `(quit)` or Ctrl-D exits.

**Gotcha:** `scripts/live.janet` must exist in ray-zig (it defines the Janet-side protocol). Was missing on initial commit — caused `FileNotFound` at startup via `zig build run`.

## Performance (Apple Silicon, ReleaseFast/release, 12 threads, 1280×720)

| | Time | Mpix/s |
|---|---|---|
| Zig (hot) | ~16 ms | ~57 |
| Rust (hot) | ~14–21 ms | ~44–65 |
| Zig 4K (3840×2160) | 148 ms | 56 |
| Rust 4K (3840×2160) | 167 ms | 50 |

Zig edges Rust by ~10–15% at 4K; essentially equivalent at 1280×720 within measurement noise.

## Lines of code (non-blank, Rust tests excluded)

| | Lines |
|---|---|
| Rust core (no janet/mesh/triangle/scripting) | 2303 |
| Zig | 1495 |
| **Zig advantage** | **−54%** |

## Zig 0.16 API gotchas encountered

- `std.Thread.Pool`/`WaitGroup` removed → `std.atomic.Value(usize).fetchAdd` work-stealing
- `std.time.Instant` removed → `std.c.clock_gettime(std.c.CLOCK.MONOTONIC, ...)`
- `std.io` removed → `std.Io.File.Writer` + `std.Io.Dir.cwd().createFile(io, ...)`
- `pub fn main()` → `pub fn main(init: std.process.Init) !void`
- `std.heap.GeneralPurposeAllocator` renamed to `std.heap.DebugAllocator`
- `build.zig`: `root_source_file` moved inside `b.createModule(...)` as `root_module`
- `exe.addRPath` doesn't exist — rpath is on the module: `exe.root_module.addRPath(.{ .cwd_relative = path })`
- Janet rpath: extract lib dir from `pkg-config --libs-only-L janet` in build.zig and add as rpath so binary finds `libjanet.dylib` without `DYLD_LIBRARY_PATH`
- Janet macros unavailable via `@cImport` → `janet_glue.c` C wrapper for `janet_wrap_nil`, `janet_type`, `janet_truthy`, `janet_pretty`, `janet_description`, etc.
- `zig build run` CWD is the project root — all `scripts/` paths load relative to `~/devel/ray-zig`
