---
name: project_ray_interactive_editor
description: ray interactive editor (docs/interactive-editor-plan.md) — A1/A2/B1/B2 + C1 + C2 done; design decisions reached in conversation that the plan doc does NOT record
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

**C1 DONE + pushed to main (`origin/main` @`fb63cde`, 2026-08-14; pure
`cargo test` + full `--features janet` suite green, 322 tests; user
manually verified end-to-end).** Render thread + `LiveState`
+ broadcast-on-timer. New `src/live.rs` (pure-Rust, NOT janet-gated, so its
tests run under plain `cargo test`): `LiveState { scene: ArcSwapOption<Scene>,
width/height: AtomicU32, camera: Mutex<Option<Camera>>, generation: AtomicU64,
stop, wake_lock+Condvar }` + `run_render_loop(state, broadcast)`. Added
`arc-swap = "1.7"` dep. The render thread snapshots scene/camera/gen, renders,
broadcasts, then **parks on the condvar until the generation bumps** (Whitted =
single pass = converged; no busy spin). Cancellation = gen check between strips.
- **The "also due here" review items are all done:** `render::render_frame(scene,
  film)` is the ONE trace-vs-wireframe dispatch (do_render + live loop both call
  it; was a do_render-only landmine); `wireframe::render_wireframe_into(cam,
  cache, &mut Film, mode)` writes the caller's film (old `render_wireframe`→Film
  kept as a thin wrapper). Skipped the `forward()` hoist (plan flagged it "only
  if profiling says so").
- **New `render::render_progressive(scene, cam, film, cancel, on_strip)`** —
  parallel over `STRIP_ROWS=32` scanline bands, cancel between strips, `on_strip`
  after each. A completed pass is byte-identical to `render()` (tested). Broadcast
  throttled to ~33 ms (`last = Instant::now()`, NOT `now-interval` — so a fast
  scene emits ONE settled frame, not a redundant partial+final; this also made
  the count-based tests deterministic).
- **Binary wiring:** `(live)` (live.janet, sets `*live-requested*`) → main loop
  spawns the render thread with an `Arc<ImageServer>` broadcast closure. While
  live, render requests route to the thread: `scripting::take_pending_camera_only`
  (pure camera move, no `PENDING_WIREFRAME`) → `set_camera` (NO rebuild — the C1
  headline); else `scene_for_render()` rebuild → `set_scene`. `scripting::
  clear_retained()` on entry so a live rebuild always re-runs the scene fn (the
  retained thread-local is stale in live mode; the live scene lives behind the
  ArcSwap). broadcast callback carries `(film, ink, settled)`; ink = white/trace
  or `mode.line`/wireframe; `save-image` works live via a settled-frame snapshot
  (`LastRender` gained `Clone`, `Film` gained `Clone`).
- **TEST GOTCHA (cost me 3 failing runs): live loop tests flake under the full
  parallel suite** because `run_render_loop`'s `par_iter` queues behind dozens of
  other tests' renders on the GLOBAL rayon pool → a 40×40 render starved >10 s.
  Fix: tests spawn the loop inside a **dedicated 2-thread `rayon::ThreadPool`**
  (`pool.install(|| run_render_loop(...))`), immune to global-pool saturation.
  They pass in isolation regardless; only the contended full run needed this.
- **Fixed a PRE-EXISTING bug that blocks the C1 feature:** `scripts/scene.janet`
  set `*camera*` to an immutable **struct** `{…}`, so `orbit!/pan!/dolly!`'s
  `(put *camera* …)` errored "expected array/table/buffer, got struct" (in live
  OR sync mode). Now `@{…}` (matches prelude); `get` reads the same so the render
  is unchanged.

- **BUG FOUND+FIXED during manual test (2026-08-14):** `toggle-wireframe!` in
  live mode turned wireframe ON but never back OFF (and a `pan!` stayed
  wireframe). Cause: `%toggle-wireframe!` decides on/off from
  `current_wireframe()`, which read the (deliberately cleared) `RETAINED` →
  always saw "off" → always toggled *on*. Fix: new thread-local
  `LIVE_WIREFRAME: Cell<Option<Option<WireframeMode>>>` in scripting.rs
  (`None` = not live → fall back to RETAINED; `Some(inner)` = live, current
  producer) consulted by `current_wireframe` between PENDING and RETAINED;
  `scripting::set_live_wireframe(scene.wireframe)` called by the binary on every
  live scene push (start_live + each live rebuild). Non-live path unaffected
  (LIVE_WIREFRAME stays None). Verified on/off by PNG (wireframe frame ~half the
  bytes of the traced one).

**C2 DONE + pushed to main (`origin/main` @`6715a30`, 2026-08-14; 323 tests
green; user-verified live).** (Same commit range also carries a small
`fix(ray-view)`: Ctrl-C now quits the terminal viewer — explicit SIGINT handler
via the `ctrlc` crate under the `view` feature, since viuer's raw-mode kitty
probe left Ctrl-C not terminating.) The automatic coarse-to-fine ladder in
`run_render_loop`: a traced scene draws the **wireframe proxy while moving**
(any generation bump within `SETTLE_TIME` = 150 ms) and **traces once settled**;
an explicit-wireframe scene is drawn at both rungs (unchanged from C1).
- **State machine is time-based**, not a flag: `LiveState.last_change:
  Mutex<Instant>` set in `bump_and_notify`; loop computes `moving =
  last_change.elapsed() < SETTLE_TIME`. New `park_until_change_or(gen, deadline)`
  (condvar `wait_timeout`) lets the loop sleep between drag frames yet wake at
  the settle deadline to trace the now-still scene. Converged trace / explicit
  wireframe still `park_until_change` (indefinite).
- **Edge cache reused across a drag** (`edge_cache_for`): keyed on `Arc::ptr_eq`
  of the scene, holds the `Arc` so the address can't be recycled (ABA); rebuilt
  only on a geometry swap. Camera moves touch no geometry → no EdgeCache rebuild,
  no BVH rebuild (BVH built once at `set_scene`; camera-dirty = 0 rebuilds is
  structural + already covered by the C1 scripting test).
- **Drag wireframe frames are `settled=false`** (transient proxy) so `save-image`
  never captures them — it only snapshots the converged trace / wireframe-scene
  final. Ink still discriminates producer (trace=white, wireframe=mode.line);
  tests use `frame_is_wireframe(ink) = ink != Color::ONE`.
- **Tests reworked for the ladder** (live.rs): the core
  `draws_wireframe_while_moving_and_traces_when_idle` (a 25 ms bumper thread
  holds it on rung 0, then stop → trace); park/wake test switched to a wireframe
  scene (immediate converge, no ladder-timing race); camera-change test compares
  only settled TRACE frames; `set_camera_does_not_block` waits for a trace-in-
  flight (ink==ONE) before pushing. Dedicated-rayon-pool spawn_loop kept.
- Not built: rung 1 (coarse-res trace as an alternative drag producer, "if the
  budget allows") — deferred; rung 0 wireframe is the only drag producer for now.

**Not in C2 (next):** D1 = sample accumulation (per-pixel sum/count, HDR,
monotonic sample counter — the 4 forward-compat constraints in
docs/live-camera-plan.md). E2 = terminal/Emacs mouse → orbit! plumbing (still
write-only ray-view). Rung-1 coarse-res drag producer. All-edges wireframe mode
(now that C2 makes the silhouette crawl observable — revisit per the plan).

Superseded prior "Next: Phase C1" note.

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
