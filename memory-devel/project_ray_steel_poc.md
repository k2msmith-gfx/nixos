---
name: ray-steel-poc
description: "Steel (Scheme) scripted ray tracer POC: scene description + TCP eval server + Emacs steel-mode. Stage 1+2+3+4 complete."
metadata: 
  node_type: memory
  type: project
  originSessionId: 431dfea2-1a06-416f-bfd1-10c0d0145383
---

POC embedding Steel (pure-Rust Scheme, `steel-core = "0.8"`) into the `ray` crate as a scripting layer.
See [[embedded-lang-benchmarks]] for the benchmark context; compare with [[ray-ecl-poc]].

**Why:** Evaluate Steel as a simpler alternative to ECL — no FFI, no system deps, just `cargo build`.
**How to apply:** All four stages done. Stage 4 pre-resolves function handle for 4.1× Lambert overhead.

## Repos

- Local: `/home/kevin/devel/ray-steel-poc` (main branch)
- GitHub: `https://github.com/k2msmith-gfx/ray-steel-poc`
- `ray` dependency: local path `../ray` (same as ECL POC)

## Status

- [x] Stage 1: Steel scene description in `scripts/scene.scm` — pixel-perfect match vs ECL and Rust reference (0 scene-area diffs)
- [x] Stage 2: TCP eval server on port 4006 + `emacs/steel-mode.el` for Emacs live editing
- [x] Stage 3: Steel Lambert shader — 4.3× overhead (1.214s vs 284ms Rust), 336k diffs max 1e-7 (f64 vs f32, imperceptible)
- [x] Stage 4: Pre-resolve function handle — `extract_value("lambert-shade")` before pixel loop, call via `call_function_with_args_from_mut_slice(shade_fn.clone(), ...)`. 4.1× overhead. Microbenchmarks: tex=0.65 µs/call, lambert=1.40 µs/call

## Build (pure Rust — no special environment)

```sh
cargo build   # that's it
./target/debug/ray-steel-poc
```

No Nix dev shell, no bindgen, no C compiler, no system libraries.

## Critical API constraint: `vm.run()` requires owned String

`Engine::run<E: AsRef<str> + Into<Cow<'static, str>>>(E)` — cannot pass a borrowed `&str` 
from a function parameter. Must pass an owned `String`:

```rust
// WRONG — compile error (lifetime escapes)
vm.run(expr)          // where expr: &str

// RIGHT
vm.run(expr.to_owned())     // inside helpers
vm.run(some_string)         // consuming a String
```

All helpers in `src/main.rs` take `expr: &str` and call `.to_owned()` internally.

## Scene description pattern

`scripts/scene.scm` defines `*scene*` as a nested hash map (Steel's `hash` function).
Keys are symbols (`'shapes`, `'mat`, `'albedo` etc.), values are hashes, lists, numbers, strings, or `#f`.

Material helper with defaults:
```scheme
(define (mat . pairs)
  (let loop ((m (hash 'albedo '(0.8 0.8 0.8) ... 'shader "lambertian")) (ps pairs))
    (if (null? ps) m (loop (hash-insert m (car ps) (cadr ps)) (cddr ps)))))
```

Rust reads the scene via composed Steel expressions:
```rust
fn mat_expr(i: usize, field: &str) -> String {
    format!("(hash-ref (hash-ref (list-ref (hash-ref *scene* 'shapes) {i}) 'mat) '{field})")
}
// e.g. get_f32(vm, &mat_expr(0, "shininess"))
```

## Steel quirks observed

- `set!` returns the new value, not void. Setters in scene.scm return `#t` explicitly
  to avoid printing the entire `*scene*` hash in the REPL on every material change.
- `list-set` is not in stdlib — implemented in scene.scm for functional list update.
- Hashes are immutable; `hash-insert` returns a new hash (functional update). `set-shape-mat!`
  rebuilds `*scene*` on every material edit.

## TCP eval server (port 4006)

Server starts before the initial render so Emacs can connect immediately.
Protocol: form terminated by `\n\n` (blank line); response is a single line (internal newlines
collapsed to spaces to avoid breaking the line-based protocol).

Per-connection handler threads send `(form, SyncSender<String>)` to the main thread.
Main thread evaluates in the Steel VM (which is `!Send`) and sends result back.

## Emacs integration (`emacs/steel-mode.el`)

```elisp
(load-file "emacs/steel-mode.el")
M-x steel-connect      ; opens *steel* comint buffer on port 4006
M-x steel-mode         ; enable in scene.scm buffer

; Keybindings (with steel-mode active):
; C-x C-e    send sexp before point
; C-M-x      send top-level form
; C-c C-r    send region
; C-c C-b    send buffer (reload scene.scm)
; C-c r      (render!)
; C-c q      (quit!)
```

comint input sender configured to append `\n\n` so direct typing in `*steel*` also uses the protocol.

## Live editing helpers (scene.scm)

```scheme
(render!)                    ; set *render-requested* → re-render within 100 ms
(quit!)                      ; clean shutdown
(set-albedo! i r g b)
(set-shininess! i s)
(set-reflectivity! i r g b)
(set-specular! i r g b)
(set-shader! i "string")     ; "lambertian" "phong" "blinn-phong" "normal-as-color"
```

Shape indices 0–7: lambertian, phong/glass, phong-backdrop, mirror, blinn-phong,
normal-as-color, ground-plane, backdrop-rect.

## Stage 3+4: Lambert shader architecture

Steel hot-call path (Stage 4) uses pre-resolved function handle:
```rust
let shade_fn = vm.extract_value("lambert-shade").expect("...");
// per pixel:
let val = vm.call_function_with_args_from_mut_slice(shade_fn.clone(), &mut args)
    .expect("lambert-shade call failed");
```
Args as `SteelVal::NumV(f64)`, result from `SteelVal::ListV` iterator.

Performance at 1280×720 single-threaded:
- Rust Lambert: 290ms (3.17 Mpix/s)
- Steel Lambert: 1.177s (0.78 Mpix/s) — **4.1× overhead** (vs 4.3× with by-name lookup)
- Pixel diffs: 336,372 (max ~1e-7 due to f64 arithmetic vs Rust f32, imperceptible)
- tex(u,v): 0.65 µs/call (ray-steel-poc microbenchmark)
- lambert(9-arg): 1.40 µs/call

Compare: Janet 1.9× (janet_pcall + fiber reset), ECL 0.9× (compiled + type declarations).

## Steel hot-call API — two paths, important distinction

```rust
// v3 (old): string name lookup + Vec alloc per call
vm.call_function_by_name_with_args("tex", vec![u.clone(), v.clone()])

// v4 (new): cached SteelVal handle + stack slice, no alloc
let fn_tex = vm.extract_value("tex").expect("tex not defined");
vm.call_function_with_args_from_mut_slice(fn_tex.clone(), &mut [u.clone(), v.clone()])
```

v4 hot-call numbers (from steel-test, 100k iters):
- (+ 1 2):       **0.17 µs** (was 0.80 via run_raw_program — 4.7× faster)
- factorial(20): 2.44 µs
- sum-to(1000):  228 µs  ← 0.23 µs per inner loop iteration; the 25 µs in v3 bench report
                            was from `run_raw_program("(sum-to 1000)")`, a different call path
- tex(u,v):      0.67 µs (name lookup was not the bottleneck here)
- dot_cos:       0.69 µs

`SteelVal` derives `Clone`; cloning a function handle is cheap (Rc bump).
Pre-boxing args as `SteelVal::NumV(f64)` or `SteelVal::IntV(i64)` outside the loop
avoids repeated boxing in the hot path.

## Known concerns vs ECL

- No Slynk equivalent: no completion, inspect, or condition restarts in the REPL.
- `Cow<'static, str>` constraint is surprising and allocates on every eval call.
- Immutable hashes require full `*scene*` rebuild on every material edit (GC churn).
- `list-set` absent from stdlib signals Steel stdlib immaturity at 0.8.
- Steel API changed significantly from 0.5 → 0.8 (Helix fork uses 0.5) — maintenance risk.
