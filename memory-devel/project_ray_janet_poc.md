---
name: ray-janet-poc
description: "Janet 1.41 scripted ray tracer POC: scene description + TCP eval server (port 4007) + emacs/janet-mode.el + live CAPF completion. Stage 1+2+3+4 complete. 0.9× Lambert overhead with fiber reset."
metadata:
  node_type: memory
  type: project
  originSessionId: 431dfea2-1a06-416f-bfd1-10c0d0145383
---

POC embedding Janet 1.41 into the `ray` crate as a scripting layer.
See [[embedded-lang-benchmarks]] for benchmark context; compare with [[ray-ecl-poc]] and [[ray-steel-poc]].

**Why:** Janet placed 2nd in hot-call benchmarks (0.27 µs tex, 0.23 µs dot-cos via fiber reset), between ECL and Steel. Pixel-perfect vs Rust (f32↔f64 round-trips cancel).
**How to apply:** All four stages done. Nix dev shell required (clang for bindgen, JANET_HOME for dylib).

## Repos

- Local: `/home/kevin/devel/ray-janet-poc` (main branch)
- GitHub: `https://github.com/k2msmith-gfx/ray-janet-poc`
- `ray` dependency: local path `../ray`

## Status

- [x] Stage 1: Janet scene description in `scripts/scene.janet` — pixel-perfect match vs Rust reference (0 scene-area diffs)
- [x] Stage 2: TCP eval server on port 4007 + `emacs/janet-mode.el` for Emacs live editing
- [x] Stage 3: Janet Lambert shader — pixel-perfect vs Rust, 1.9× overhead (539ms vs 290ms at 1280×720 single-threaded)
- [x] Stage 4: fiber reset (janet_fiber_reset + janet_continue) → **0.9× overhead**, pixel-perfect

## Build (requires Nix dev shell)

```sh
source /home/kevin/devel/ecl-test/.direnv/flake-profile-*.rc   # provides clang/libclang
export JANET_HOME=/nix/store/kk051knsm6g0dwsrm1cja8qac8221zxd-janet-1.41.2
cargo build
LD_LIBRARY_PATH="$JANET_HOME/lib:$LD_LIBRARY_PATH" ./target/debug/ray-janet-poc
```

Or once the flake.nix is resolved via `direnv allow`.

## Janet scene pattern

`scripts/scene.janet` defines `*scene*` as a nested mutable table (`@{...}`) with keyword keys.
Live editing uses `put` / `put-in` directly — no functional rebuild needed (unlike Steel's immutable hashes).

```janet
(put-in *scene* [:shapes 0 :mat :albedo] [1.0 0.0 0.0])  # change sphere 0 to red
(render!)                                                   # triggers re-render in ~100ms
```

Rust reads via composed `get-in` expressions:
```rust
fn mat_expr(i: usize, field: &str) -> String {
    format!("(get-in *scene* [:shapes {i} :mat :{field}])")
}
// get_f32(env, &mat_expr(0, "shininess"))
// get_vec3(env, &mat_expr(0, "albedo"))
```

## Stage 3: Lambert shader architecture

Rust computes BVH traversal, shadow rays, N·L weighting → `direct: Vec3`.
Janet function `(lambert-shade ar ag ab lr lg lb dr dg db)` returns `[r g b]` tuple.
Result unpacked with `janet_getindex(out, i)` (added to build.rs bindings).

Performance at 1280×720 single-threaded:
- Rust Lambert: 290ms (3.18 Mpix/s)
- Janet Lambert: 539ms (1.71 Mpix/s) — 1.9× overhead
- Pixel diffs: **0** (pixel-perfect, f32→f64→f32 round-trips cancel out)

The 1.9× overhead = janet_pcall fiber allocation per pixel + boxing 9 f64 args.
After Stage 4 fiber reset: 0.9× overhead — matches Rust.

## Janet FFI constraint: janet_pcall / fiber_reset

`janet_call` panics when called outside a Janet fiber frame (after `janet_dobytes` returns).
Hot-call path: `janet_pcall` on first hit (null fiber → allocates), then
`janet_fiber_reset(fiber, fn, argc, argv)` + `janet_continue(fiber, nil, &out)` for all
subsequent hits — reuses the same fiber allocation, no per-pixel GC pressure.

## TCP eval server (port 4007)

Same protocol as ray-steel-poc (port 4006): form terminated by `\n\n`, response is single line.
Server starts before initial render so Emacs can connect immediately on launch.

## Emacs integration (`emacs/janet-mode.el`)

```elisp
(load-file "emacs/janet-mode.el")
M-x janet-connect      ; opens *janet* comint buffer on port 4007
M-x janet-mode         ; enable in scene.janet buffer

; Keybindings (with janet-mode active):
; C-x C-e    send sexp before point
; C-M-x      send top-level form
; C-c C-r    send region
; C-c C-b    send buffer (reload scene.janet)
; C-c r      (render!)
; C-c q      (quit!)
; M-TAB      complete symbol at point (live, via eval server)
```

## Symbol completion

`janet-completion-at-point` is a CAPF registered buffer-locally by `janet-mode`. It opens a
dedicated sync TCP connection per query, sends:
```janet
(string/join (sort (filter (fn [k] (string/has-prefix? PREFIX (string k)))
                           (map string (keys (curenv))))) "|")
```
and parses the `=> "foo|bar|baz"` response. Covers all Janet core symbols plus every
user-defined name in the live environment. Works with corfu/company automatically.
`janet--sync-eval` is the reusable helper (separate from the comint process) — timeout 1 s.

## Janet scene advantages vs Steel

- Mutable tables (`@{...}`) allow `put-in` to edit nested fields without rebuilding the whole scene
- `get-in` path syntax is cleaner: `(get-in *scene* [:shapes 0 :mat :albedo])` vs `(hash-ref (hash-ref ...))`
- `list-set` not needed (arrays are mutable with `(put array idx val)`)
- Result: simpler scene.janet, simpler Rust accessors
