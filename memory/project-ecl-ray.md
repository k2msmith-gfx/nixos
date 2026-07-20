---
name: project-ecl-ray
description: Plan to integrate ECL scene loading into the Ray renderer on a new branch
metadata: 
  node_type: memory
  type: project
  originSessionId: eb0edd0a-e809-4672-9d9b-8c69abd92bc6
---

Add ECL-based scene loading to the Ray CPU renderer (`~/devel/ray`) on a new branch.

**Why:** Proved in `~/devel/ecl-test` that embedded ECL is viable — `cl_funcall` on natively-compiled functions hits ~0.35 µs/call, fast enough for per-sample texture evaluation. Goal is a Lisp DSL for scene descriptions and procedural textures with live SLY/Emacs reloading.

**How to apply:** When resuming, create a new branch in `~/devel/ray` (e.g. `ecl-scene`) and implement a `load_scene()` function that:
1. Boots ECL and loads a `scene.lisp` file
2. Reads back `*scene*` as a property list
3. Constructs Rust `Scene`, `Camera`, `Shape`, `Material`, `Light` structs from it

Key Ray types to map (from `~/devel/ray/src/`):
- `Camera::new(eye, target, up, vfov_deg, aspect)` — `camera.rs`
- `Material { albedo, specular, shininess, reflectivity, transparency, ior, abbe_number, shader }` — `material.rs`
- `Shape::sphere(center, radius, material)`, `Shape::plane(y, material)` — `shape.rs`
- `PointLight::new(position, intensity)`, `SpotLight::new(position, target, intensity, cone_angle_deg, penumbra_deg)` — `light.rs`
- `Scene::new(camera, shapes, lights).with_ambient(color)` — `scene.rs`

See `~/devel/ecl-test` for the FFI setup (bindgen, build.rs, flake.nix) that can be ported into Ray.
See also the sample scene DSL written in this session (in conversation history).

**Steel vs ECL tradeoffs:**

| | ECL | Steel |
|---|---|---|
| FFI | bindgen + C headers required | Pure Rust, zero FFI |
| Performance | ~0.35 µs/call (native compiled) | ~0.73 µs/call (bytecode only) |
| Live REPL | Yes — Slynk/SLY inside running process | No — edit file + restart |
| Contributor setup | Needs ECL, optional Emacs/SLY | Just `cargo add steel` |
| Language | Full Common Lisp (CLOS, macros, ANSI stdlib) | Scheme (less expressive) |
| Native compilation | Yes — `(compile 'fn)` → C | No |

Middle ground option: ship scene DSL in Steel (easy for contributors), keep ECL opt-in for texture/shader authoring where performance and live REPL matter most.

**Slynk bundling plan** (for contributor portability):
- Current setup hardcodes Doom Emacs path to slynk-loader.lisp — breaks for anyone without Doom/SLY
- Current contrib errors (sly-quicklisp etc.) are Doom-specific; vanilla SLIME users won't hit them but the fix shouldn't be editor-dependent
- Solution: bundle slynk sources inside the Ray repo (or as a git submodule), load from a relative path
- Only include core slynk contribs that work with embedded ECL — no quicklisp, no asdf
- Make slynk optional (e.g. `--slynk-port 4005` flag) so contributors without Emacs aren't forced to use it
- Works with both SLY and SLIME (same slynk backend), so contributor editor choice doesn't matter
