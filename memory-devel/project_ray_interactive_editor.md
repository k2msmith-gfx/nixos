---
name: project_ray_interactive_editor
description: ray interactive editor (docs/interactive-editor-plan.md) — A1 done; design decisions reached in conversation that the plan doc does NOT record
metadata: 
  node_type: memory
  type: project
  originSessionId: 59c846bd-1754-4400-8572-b0698c9f43ab
  modified: 2026-08-12T22:41:12.588Z
---

Build status + decisions for the interactive editor. The *phases* live in
`docs/interactive-editor-plan.md`; this records what that doc does **not** say.

**A1 DONE + pushed 2026-08-12 (`ff01e8b`), scoped to camera motion only.**
`do_render` retains its built `Scene` (`scripting::retain_scene`) and takes the
next from `scene_for_render()`; `(set-camera! ...)` in `scripts/live.janet`
parks a `CamParams` that swaps only the camera on the retained scene — no scene-fn
re-run, no BVH rebuild. `#[cfg(test)] bvh::BUILD_COUNT` proves zero rebuilds.

**CONSTRAINT — do not "optimise" `(render)` into using the cache.** `(render)`
must keep re-running the Janet scene function, because that re-run *is* the
mechanism by which `live.janet`'s in-place `*shapes*` edits (`set-center`,
`set-albedo`, …) take effect (`scene.janet:6`). A1 deliberately inverts the
usual default: only an explicit `set-camera!` opts into reuse, so no geometry
edit can silently render against a stale scene. A dirty-flag scheme driven from
the Rust `%add-*` callbacks CANNOT work — those only fire during a build, so
they can't observe a Janet-side mutation.

**Precedence:** scene file stays authoritative for the pose — the next
`(render)` returns to its `(set-camera ...)`. Consequence: the live camera is
NOT saved. Accepted for now.

**Two shared prerequisites for lights/shapes/save (the real next work):**
1. **Addressing** — `%add-*` returns nil and `Scene::new` partitions
   (finite/infinite) then BVH-permutes, so Janet's index names nothing stable in
   Rust. Need `add-*` → id + an id→location map on the retained `Scene`.
   Unblocks light editing AND shape editing at once.
2. **Authored-form retention** — keep the form the user *wrote*, not the lowered
   result. Rust's `Scene` is lossy/compiled: `Shape` is a `Mat4` +
   `Box<dyn Geometry>`, and `uv_sphere(0.5,48,24)` is ~2300 triangles with no way
   back. `Camera` too (stores origin/lower_left/horizontal/vertical — `up` is not
   uniquely recoverable). `CamParams` already does this by accident.

**Cost tiers:** camera = no rebuild (done); **lights = no rebuild either**
(`Scene.lights` is a plain `Vec`, not in the BVH) → cheapest next step;
shapes = rebuild required → needs plan's C2 (wireframe during drag, exactly one
rebuild on settle).

**Codegen/save — capability in ray, policy in the client.** Do NOT put form-writing
in `ray-studio.el`: Emacs is one client (TCP 4007 + PPM image stream are both
client-agnostic; a GUI viewport could connect the same way). Ray should expose a
*pure* `(camera-form)`/scene-emitter returning Janet source text; clients decide
whether to insert-unsaved, diff-dialog, or write. Corollary: "refuse to clobber a
dirty buffer" can only be enforced client-side — ray can't know a file is open
elsewhere. Also: writing back to Janet `*camera*`/`*shapes*` is style-dependent
and fails **silently** for imperative scenes that never use those vars (ray's own
test scenes don't) — that's why the authored form belongs in ray.

See [[project_ray_render_features]], [[project_ray_next_steps]].
