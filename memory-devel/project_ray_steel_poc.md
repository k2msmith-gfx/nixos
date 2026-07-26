---
name: ray-steel-poc
description: "Steel (Scheme) scripted ray tracer POC. Migrated 2026-07-25 to PUSH architecture (full ECL/Janet parity): Rust register_fn %-callbacks, Steel scene calls them. Scripted shaders removed. TCP eval server (port 4006) + emacs/steel-mode.el + CAPF/Corfu completion. Parity: 0 diffs."
metadata: 
  node_type: memory
  type: project
  originSessionId: 431dfea2-1a06-416f-bfd1-10c0d0145383
---

POC embedding Steel (pure-Rust Scheme, `steel-core = "0.8.2"`) into the `ray` crate as a scripting layer.
See [[embedded-lang-benchmarks]] for benchmark context; compare with [[ray-ecl-poc]], [[ray-janet-poc]] (mirrors its layout).

**Why:** Evaluate Steel as a simpler alternative to ECL — no FFI, no system deps, just `cargo build`.
**How to apply:** Local checkout `/Users/kevinsmith/Documents/devel/rust/ray-steel-poc`; `cargo build` (pure Rust, no Nix). See [[reference_repo_paths]].

## 2026-07-25 — PUSH architecture migration (full ECL/Janet parity)

Migrated from the pull model (Rust walked `*scene*` via `hash-ref`) to the **push** model mirroring [[ray-janet-poc]]: Rust registers `%`-prefixed callbacks and a Steel scene *calls* them to build the scene. Rust owns the schema; Steel owns ergonomics.

- **`src/scripting.rs` (new):** `thread_local` `RefCell<SceneBuilder>` (Steel VM is `!Send`, main-thread only). 14 `%`-callbacks registered via `Engine::register_fn` — closures capture nothing, reach the builder through `with_builder`, so they satisfy register_fn's `Send+Sync+'static` bound. `SceneBuilder`/`MatBuilder` identical to the Janet/ECL version. `register_api(&mut vm)` + `build_scene(&mut vm)` (resets builder, `vm.run("(scene)")`, finish).
- **Steel register_fn facts (verified in steel checkout v0.8.2):** callbacks take positional `f64` args (max arity **16**; widest callback = 11-arg spot light). `f64::from_steelval` accepts **only `NumV`, not `IntV`** (`try_from_impl!(NumV => f64, f32)`) → prelude coerces every arg with `exact->inexact` (`->f`), incl. shader int codes. `()` impls IntoSteelVal. **`void` is a VALUE not a procedure** — use bare `void`, never `(void)` (that applies void → "Application not a procedure" error).
- **Three-file script layout** (mirrors Janet's prelude/scene/live trio):
  - `scripts/prelude.scm` — `->f`, `shader-code` (string→int code), `set-film/-camera/-ambient`, `add-point-light/-spot-light`, `material` (flat `'key value` plist via `plist-get`, emits `%mat-*`), `add-sphere/-plane/-rect`.
  - `scripts/scene.scm` — `make-mat` (builds a hash) + `*film*/*camera*/*ambient*/*lights*/*shapes*` data (lists of immutable hashes) + `emit-*` + `(scene)`. Order now matches Janet/ECL: 0 blue-lambert, 1 glass-phong, 2 orange, **3 green-blinn-phong, 4 mirror**, 5 normal, 6 ground, 7 backdrop (swapped from old Steel order which had mirror at 3, blinn at 4).
  - `scripts/live.scm` — setters rebuild `*shapes*` via `set!` + `list-set` (Steel hashes/lists immutable, so functional rebuild — the one real diff vs Janet's in-place `put`). Index aliases, `*render-requested*`/`*quit-requested*`, `render!`/`quit!`.
- **`src/main.rs`:** rewritten as pure push builder; local `reference_scene()` mirrors scene.scm → **0 pixel diffs**. Kept TCP server 4006 + stdin REPL. Now emits a `steel> ` prompt on connect + after each response (was promptless) so the Emacs completion helper can detect readiness.
- **Removed:** scripted Lambert shader (`lambert-shade`, `render_steel_lambert`, `tex`), Stage 3 pixel-diff block, all µs/call microbenchmarks, the entire pull `hash-ref` accessor layer (`shape_expr`/`mat_expr`/`light_expr`/`build_material`/`build_shape`/`build_light`/`get_f32` etc.).
- **Completion (Stage 2):** Steel has no value-level env introspection, but `Engine::globals()` → `Vec<InternedString>` (`.resolve()` → name) does it on the Rust side. Added a `(%symbols)` **sentinel** intercepted in `eval_form` before `vm.run`: returns all globals pipe-joined in a quoted string (`=> "a|b|c"`), filtering `#`-containing and `%-builtin-module-*` noise (790 clean symbols). `emacs/steel-mode.el` ported from janet-mode.el: `steel--sync-eval` (waits for `steel>`), client-side cache (TTL 3s + invalidate on send), `steel-completion-at-point` CAPF, Corfu auto-popup. Verified in batch emacs: CAPF `set-a` → `(set-albedo set-ambient)`. Symbol chars `*!?/<>=+%a-zA-Z0-9_-`.

⚠️ **Everything below is historical (pre-2026-07-25 migration)** — the pull-model scene pattern (`hash-ref`/`hash-insert` accessors from Rust), the Lambert scripted shader, and their 4.1× benchmarks describe code that no longer exists. Kept for the benchmark record and [[embedded-lang-benchmarks]] context.

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

Linux (x86_64):
- Rust Lambert: 290ms (3.17 Mpix/s)
- Steel Lambert: 1.177s (0.78 Mpix/s) — **4.1× overhead** (vs 4.3× with by-name lookup)
- Pixel diffs: 336,372 (max ~1e-7, imperceptible)
- tex(u,v): 0.65 µs/call; lambert(9-arg): 1.40 µs/call

macOS (ARM64, Apple Silicon, 2026-07-24):
- Rust Lambert: 1.675s (0.55 Mpix/s)
- Steel Lambert: 3.550s (0.26 Mpix/s) — **2.1× overhead**
- Pixel diffs: 336,372 (max 1.19e-7, same as Linux)
- tex(u,v): 1.47 µs/call; lambert(9-arg): 3.09 µs/call
- Note: per-call µs are higher than Linux despite lower render ratio — Rust debug baseline is also slower on this machine

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
