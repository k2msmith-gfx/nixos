---
name: project_ray_interactive_editor
description: ray interactive editor (docs/interactive-editor-plan.md) — A1/A2/B1/B2 done+pushed; design decisions reached in conversation that the plan doc does NOT record
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

**A2 / B1 / B2 DONE + pushed to main (`origin/main` @`fd86e8d`, 2026-08-13).**
A2 = `shade_pixel` extracted + `Tile`/`render_tiled(…, cancel)`; batch `render()`
stays on the flat `par_iter_mut` path. B1 = `Camera::project`/`clip_segment`/
`NEAR`. B2 = `src/wireframe.rs` (rung 0), three commits: `8e97a2d` rasterizer,
`9ad1d83` mesh twins, `2a80c3c` toggle+Emacs.

**B2 facts worth not rediscovering:**
- `TriangleMesh` now **retains `positions`/`indices`** (chosen over rederiving
  shared edges by position-matching). `EdgeTable` + `edges_welded_auto()`;
  welding is REQUIRED — a `uv_sphere`'s duplicated seam column leaves 116
  boundary edges and inks a spurious meridian.
- **Only meshes have edges** → analytic prims are absent from the drawing. Hence
  the mesh twins `add-cuboid-mesh`/`add-rect-mesh`/`add-cone` (+ existing
  `add-sphere-mesh`), each taking its twin's args in the same local space.
  `add-plane` gets NO twin (infinite ⇒ no meaningful extent).
- `(toggle-wireframe!)` (C-c w) flips the **retained** scene like `set-camera!`;
  `set-wireframe` is the scene-building form and needs a full rebuild.
- `%toggle-wireframe!` returns a **number, not a boolean** — bindgen only sees
  Janet's out-of-line wrappers and `janet_wrap_boolean` is a macro.
- Speeds: helmet 3.3 ms drawn vs ~25 s traced; primitives 1.3 ms vs 333 ms.

**Wireframe draws EVERYTHING as of `d57d332` (2026-08-13).** The meshes-only
first cut was wrong in practice — `scripts/scene.janet` drew 2 of its 11 shapes,
so C-c w looked broken on the default scene. Analytic prims now supply
`Geometry::wireframe_proxy` (a coarse tessellated stand-in used ONLY by the
rasterizer; `intersect_local` stays exact, asserted by a proxied sphere still
hitting at radius 1). Infinite planes get `Plane::ground_grid` instead —
**cell size from the scene diagonal, not camera height** (height alone puts
10-unit cells under a 6-unit subject once you pull back), faded ink since it is
context and there is no HLR. Consequence: the mesh twins are no longer needed
for visibility, only for a deliberately faceted look.

**Two clipper bugs fixed there, invisible until a line spans the camera:**
`clip_segment` aimed at exactly `NEAR`, but `view_depth` at that point is a dot
product of near-total cancellation carrying ~1e-7 noise → landed *below* NEAR
half the time and `project` refused the clipper's own output. Now `CLIP_DEPTH =
NEAR * 2`. And `to_pixel` rejected huge coordinates (i32-wrap guard), throwing
away the on-screen part too — now 2D Liang–Barsky clipping. Together they
dropped every converging grid line: a grid with no perspective.

**PREDICTION for C1/C2 (untested, recorded in the plan under C2):** silhouette
edges are recomputed against the eye per frame, so on smooth meshes the drawn
set changes continuously and edges pop in/out — static frames fine, drags may
shimmer. Creases/boundaries are view-independent and stay put. The deferred
all-edges mode is view-independent and cannot crawl, so it may be the *steadier*
drag preview on modest meshes — counter-intuitive, worth comparing once C2 makes
it observable.

**FULL PIPELINE CODE REVIEW 2026-08-14, all fixes merged (@cf4a4a3, 3 commits).**
Walked Janet surface → FFI/state → dispatch → geometry hooks → edge topology →
camera → rasterizer. Everything found was fixed in place or recorded in the
plan's C1 "also due here" block (render_frame library dispatcher; render_wireframe
writes into caller's Film; forward() hoist). Key invariants NOW TRUE:
- **Wireframe frames are byte-deterministic** (EdgeTable sorted; was HashMap
  order → ~0.8% of junction pixels wobbled ≤4/255 between builds). So
  render-twice-and-cmp / golden hashes are now valid on drawn frames too.
- Proxies are OnceLock statics (`Option<&'static TriangleMesh>`); trait has NO
  default — a new primitive (cylinder is queued) must answer drawability
  explicitly or it won't compile.
- clip_to_frame is f64 inside (f32 lerp lost ~25px at grid-case magnitudes —
  lines stopped 15px short of the frame border).
- WIRE_STYLE is scene-scoped (was leaking palettes across load-scene).
- Caption ink follows the frame (wireframe captions were white-on-white).
- camera::NEAR doc carries a domain-of-validity table: view_depth noise =
  |coords|·1e-7, margin 1e-4 → guarantee inverts past ~1500-unit scenes.
Traced output byte-identical across the whole review (coral A/B 0 diffs).
Remaining known-not-fixed: GRID_FADE constant duplicated (prelude 0.62 +
wireframe.rs), Janet silently ignores misspelled &named keywords, ~10
pre-existing unresolved rustdoc links repo-wide.

**Deferred, recorded in the plan's `## Deferred` section:** hidden-line
removal (back-face edge culling is the cheap 80% before a z-buffer pre-pass,
which would change rung 0 from O(visible edges) to O(pixels×triangles)) and an
all-edges mode — where the trap is that **`:crease-angle 0` is NOT all-edges and
no threshold can be**: coplanar faces meet at exactly 0, so a flat quad's
diagonal is unreachable (cuboid stays 12/18 edges, rect 4/5, at any threshold).
User decision 2026-08-13: all-edges **on hold until the remaining phases land**,
then revisited — it is a first-class diagnostic output, not just a stand-in.

**Maya-style camera controls DONE + pushed to main (`origin/main` @`e1a91af`,
2026-08-13) — the client-facing half of Phase C.** `scripts/live.janet` now has
`(orbit! dx dy)` / `(pan! dx dy)` / `(dolly! d)` taking **raw mouse deltas in
pixels**, so any client (ray-view, Emacs, a future GUI) only reports the drag and
does zero 3D math — ray owns the feel. Pure Janet, built on the prelude's
`vsub`/`vcross`/`vlen`/… (no Rust). orbit = spherical tumble about `:target`
(dx→yaw about world-up, dy→pitch about view-horizontal), radius preserved, pitch
clamped shy of the poles (no flip/roll); pan = eye+target slide scaled by
distance; dolly = exponential distance scale, clamped at `*min-dist*`, never
crosses target. Policy vars `*orbit-speed*`/`*pan-speed*`/`*dolly-speed*`/
`*min-dist*`/`*el-limit*`, live-tweakable (negative speed inverts). **Math is
Y-up only** (matches `set-camera`'s default + every bundled scene).

**KEY divergence from A1's "live camera NOT saved":** each helper **mutates
`*camera*` in place** *then* fires `set-camera!` for the fast no-rebuild redraw.
Mutating `*camera*` is what makes successive drag events **accumulate** (each
reads the prior pose, not the scene's declared one) AND makes the move **persist**
— a later full `(render)` re-reads `*camera*` (`scene.janet:129`), so unlike a
bare `set-camera!` these controls stick. Tested via `boot_with_live` (prelude +
live.janet): accumulation ("two 45° yaws == one 90°"), radius preservation,
pitch/dolly clamps, pan coupling — each reduced to a tolerance `=> true`.
Terminal mouse-capture plumbing (xterm `1002`+`1006` → `dx,dy` → these calls over
TCP 4007) is still a Phase-C task; ray-view is currently write-only (no back-channel).

**NOT YET TESTED UNDER REAL INPUT (user decision 2026-08-13).** The pose *math*
is unit-tested, but nobody has driven these with live `dx,dy` mouse events —
validation deliberately deferred to the Phase-C mouse plumbing. Expect to tune at
that point: the `*-speed*` magnitudes + signs are pure feel (likely flip a sign
once you see which way a drag should tumble), and whether `*el-limit*` "stop shy
of vertical" feels right vs. Maya's over-the-top flip is only judgeable while
dragging. Treat the values as provisional, not validated.

**Next: Phase C1** — render thread + `LiveState`, where the toggle stops being a
manual key and becomes the state machine's automatic choice during a drag.

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
