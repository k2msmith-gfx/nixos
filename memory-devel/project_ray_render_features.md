---
name: ray-render-features
description: "ray rendering-feature roadmap: anti-aliasing DONE, soft shadows DONE (2026-08-08), glTF model loader DONE (2026-08-09, mesh Stage C3), lit-wireframe shader DONE + MERGED TO MAIN (2026-08-09, origin/main @620aea1). Bang-for-buck ranking + follow-ups. DECISION 2026-08-09: texture mapping (glTF stage 2) chosen as NEXT build, bang-for-buck lens. New plans scoped: live-camera (docs/live-camera-plan.md), distance fog (docs/fog-plan.md). Order: 1 textures, 2 fog, 3 live-camera Pillar 1, 4 cylinder, 5 path tracing."
metadata: 
  node_type: memory
  type: project
  originSessionId: 11dbcc97-ef63-493f-a2cb-8c902b4809fa
---

Roadmap for `ray`'s renderer/integrator features (distinct from the Janet
scripting track in [[ray-next-steps]]). `ray` is a Whitted-style ray tracer:
recursive reflection/refraction + chromatic dispersion, direct lighting via
Lambertian/Phong/BlinnPhong shaders, BVH, per-mesh BVH. Goal 2 of ray =
intro-CG-class content.

## Done
- **Anti-aliasing / supersampling** — pixel-level N-rooks (Latin-hypercube)
  stratified sampling; `Scene::samples` (default 1). Commit `0aacacc`.
- **Soft shadows via spherical area lights — DONE 2026-08-08, on `main`
  (commit `8680238`).** Design + full writeup in `docs/soft-shadows-plan.md`
  (status DONE). New `src/rng.rs` (shared N-rooks sampler, moved out of
  render.rs), `Light::is_delta`/`sample_point`, `SphereLight` (samples a disk
  facing the shaded point), shared `shader::visibility` fraction, a seed
  threaded through `radiance`/`shade`, `Scene::shadow_samples` (default 1 →
  existing renders byte-identical; delta point/spot lights take one ray).
  Janet: `add-sphere-light` + `set-shadow-samples`. Examples:
  `examples/soft-shadows.janet` (single light) + `soft-shadows-still-life.janet`
  (two lights, tinted overlapping shadows); both in `examples/README.md`.
- **glTF/GLB model loader — DONE + MERGED TO MAIN 2026-08-09 (mesh Stage C3),
  `origin/main` @dc6c64a (3 commits: feat(gltf) 9400b4f, fix(shader) e29e916,
  feat(examples) dc6c64a).** **Follow-on 2026-08-09 (also on main, @ecb1051):** added a 2nd example
`examples/gltf-material-spheres.janet` — Khronos MetalRoughSpheresNoTextures
(CC0, 98 materials/123 primitives, metallic/roughness factors, no textures) to
test **material groups** (per-primitive PBR→Material at scale). It surfaced two
fixes: (1) **fix(geometry) scale-invariant `Triangle::intersect` parallel test**
— was `|det| < 1e-8` absolute; det = −dir·n scales with geometry+ray length, so
mm-scale meshes (or a big Shape scale shrinking the local ray) had det ~1e-10
and every triangle was falsely rejected → mesh invisible. Now `det*det <=
EPS_PARALLEL_SQ(1e-16) * dir.len_sq * n.len_sq` (keys on cos θ, sqrt-free, `<=`
also rejects degenerate tris). (2) **test(scripting) serialize Janet-VM tests
via a static Mutex** — libjanet has process-global VM state (janet_init/deinit),
NOT parallel-safe; scene_from holds JANET_TEST_LOCK. Chose **glTF over OBJ**
  (user's call): `gltf` crate 1.4 (does NOT read .obj — separate formats),
  carries normals+texcoords+materials+node-graph in one file. Design in
  `docs/gltf-plan.md`. New `src/gltf_loader.rs`: `load_gltf(path, root, mat_override)
  -> Vec<Shape>` + `load_gltf_primitives -> Vec<LoadedPrimitive{mesh,transform,material}}`
  (latter exposed so loaded geometry is testable — Shape hides its Box<dyn Geometry>).
  One glTF primitive → one TriangleMesh → one Shape (node's composed world Mat4 into
  Shape::new — reuses existing transform/normal-matrix machinery, zero Scene/render/BVH
  changes). PBR→Material: base_color→albedo, metallic→tinted reflectivity,
  roughness→BlinnPhong shininess (2/α⁴−2, clamped), shader BlinnPhong. [UPDATE 2026-08-12: this flattening DROPS normal/MR/occlusion maps + the metallic/roughness *quantities* — the PBR plan below preserves them.] Geometry:
  Triangle gained uv0/uv1/uv2 (with_uvs builder), TriHit.uv (interp), from_indexed
  gained `uvs: Option<&[Vec2]>` param — **UVs stop at TriHit, NOT threaded to
  LocalHit/Hit/shaders** (texture *sampling* is the deferred next stage; UV plumbing
  is step 1). Janet: `%load-gltf` reads string path via `jz_string_bytes` glue +
  new `arg_string` helper; `(load-gltf path :at :scale :rotate :material-fn)` — does
  NOT consume cur_mat (glTF has own materials); `:material-fn` thunk overrides all
  (grow-branches idiom — bare (material…) returns nil, undetectable). Fixture
  `tests/assets/tri.gltf` (embedded-buffer 1-tri, generated via nix python3).
  Example `examples/gltf-suzanne.janet` (Suzanne CC0 UX3D, textures stripped to
  geometry-only ~590KB, `:material-fn` clay override; rendered gltf-suzanne.png).
  175 tests pass (janet), gltf_loader clippy-clean (only pre-existing findings remain).

- **Lit wireframe shader — DONE + MERGED TO MAIN 2026-08-09, `origin/main`
  @620aea1** (feat `1d4cf76`, suzanne camera-fix `0ab7335`, glass-marbles
  half-res tweak `ae1b85b`, README `620aea1`). New
  `ShaderKind::Wireframe { wire_color, width }` in `src/shader.rs`: a normal
  Lambertian-lit *fill* with triangle edges painted over it in a solid wire
  color (smoothstep-AA'd on the inner side). Needs a per-hit **distance to
  nearest triangle edge** — this is the first thing threaded all the way
  TriHit→LocalHit→Hit into a shader (the UV plumbing the texture stage wants is
  the same shape, still not done). `Hit.edge_dist: Option<f32>` — `Some` only
  for meshes; analytic prims (sphere/plane/rect/cuboid) set `None` and render as
  unbroken fill, so no spurious lines. Edge dist is **precomputed sqrt-free**:
  each `Triangle` caches its 3 altitudes at build (`Triangle::altitudes`, +12
  B/tri), so `intersect` only does `min(w·hₐ, u·h_b, v·h_c)` — no per-ray sqrt
  (user explicitly didn't want heavy per-hit math; fully gating on shader would
  need a flag through the Geometry trait, not worth it for ~5 flops). Local dist
  → world via `Shape.edge_scale` = cbrt(|det| of 3×3 block), so `width` is in
  **world units** (constant thickness regardless of tessellation density).
  Janet: `:shader :wireframe` + `:wire-color [r g b]` (default black) +
  `:wire-width n` (default 0.01) → shader code 4, `%mat-wire` cfunction,
  `MatBuilder.wire_color/wire_width`. Example
  `examples/gltf-suzanne-wireframe.janet` (8 spp / 1 shadow-sample, 0.003 wire,
  camera pulled back to fit the ears). 171 tests pass. **Render-perf gotcha
  (learned here):** the 11k-tri Suzanne at the studio scenes' 64 spp / 16 shadow
  samples does NOT finish in a debug build within ~10 min; render heavy examples
  with `cargo run --release …` (~80 s). Light previews (8 spp / 1 shadow) are
  ~10 s in debug and fine either way. `gltf-suzanne.janet` reframed here
  (camera z 4.3→5.1, target y 0.55→0.85) to stop the ears clipping;
  `gltf-suzanne-studio.janet` left alone (intentional 3/4 hero angle, `:at 1.77`,
  frames fine).

## Bang-for-buck ranking (reprioritized 2026-08-09; lens = bang-for-buck)
**DECISION 2026-08-09 (user): texture mapping is the NEXT build; roadmap ordered
for bang-for-buck.** Soft shadows / glTF loader / wireframe done. Two NEW plans
scoped this session and slotted into the ranking: **live interactive camera**
(`docs/live-camera-plan.md`, uncommitted→ committed @215e968/@e5b8aea — move the
camera by mouse from Emacs while progressively rendering; 3 pillars: retain
Scene + decouple camera [Pillar 1, workflow multiplier + PT-viewport prereq],
interruptible tiled render thread w/ generation epoch, coarse-to-fine +
sample-accumulate; forward-compat w/ path tracing documented — 4 accumulator
constraints) and **distance fog** (`docs/fog-plan.md`, few-line quick win, slots
into sky/ambient scene-param pattern). Bang-for-buck order now:
1. **glTF texture sampling (loader stage 2) — CHOSEN NEXT (2026-08-09).** SCOPED, plan in
   `docs/texture-mapping-plan.md` (@def201f), not built. 6 stages: thread `uv`
   through LocalHit/Hit, `src/texture.rs` (bilinear+wrap), Scene-owned texture
   table + `Material` handle slot, `resolve_albedo` in shaders, glTF image load,
   textured-Suzanne example. 4 locked decisions: (1) texture **handle** (u32
   index into Scene.textures), NOT Arc — keeps Material `Copy`; (2) real UVs for
   sphere/plane/rect now, cuboid→zero; (3) **keep ray's linear no-gamma pipeline**
   — texel/255 used directly, NO sRGB decode (full sRGB = separate scene-wide
   project; ray's film::to_u8 writes linear straight to 8-bit); (4) **base color
   only** in phase 1 (metallic-rough needs per-hit resolve in BOTH shader+
   integrator since reflectivity is integrator-read; normal maps need the TANGENT
   attr we drop). UV storage (Triangle/TriHit) already in place from stage 1.
2. **Distance fog** — SCOPED, plan in `docs/fog-plan.md`, not built. Cheap
   quick win (a few lines), blend surface color toward a fog color by ray
   distance; slots into the `sky`/`ambient`/`max_depth` scene-param pattern.
   Can slot in parallel to #1 anytime.
3. **Live camera — Pillar 1 (retain Scene + decouple camera)** — SCOPED,
   `docs/live-camera-plan.md`. The infrastructure pick: kills the per-render
   BVH-rebuild (build_scene resets + re-runs the scene fn every render), so it
   speeds the everyday edit→render loop, and is the prerequisite for a
   progressive / PT viewport. Independent of the interactive part.
4. **Cylinder primitive** — low ROI (already 6+ primitives); a quick low-stakes
   win only.
5. **Path tracing / global illumination** — SCOPED, plan in
   `docs/path-tracing-plan.md` (@e0bd64b), not built. Highest ceiling +
   difficulty. Key design: a **second integrator alongside Whitted**, selectable
   via `scene.integrator` enum (default Whitted → existing renders byte-identical)
   — separation removes regression risk, NOT the intrinsic Monte-Carlo risk.
   Seam: `render()` already owns the reusable pixel loop/AA+DoF sampling/Rayon/
   seeds; `render.rs::radiance` IS the Whitted integrator that PT replaces.
   Reference-first stages: A seam, B diffuse reference (cosine sampling, Russian
   roulette, sky=env light, emissive surfaces, NO NEE) + furnace-test validation,
   C specular reflect/transmit, D NEE+MIS, E GGX glossy, F Cornell box. Materials
   interpreted into BSDFs (shaders stay **Whitted-only**; albedo→diffuse,
   reflectivity/transparency/ior→specular). Gotchas: **delta point/spot lights
   invisible to pure BSDF sampling** (need emissive spheres or NEE); PT **forces a
   tone-map** (HDR>1, film::to_u8 just clamps) that Whitted didn't need; retires
   `scene.ambient`.

## Follow-ups from the soft-shadows work
- **Perf:** `shader::visibility` reuses `rng::sample_offsets`, which allocates
  a `Vec` per call — now in the hot path (per hit per area light). Switch to an
  allocation-free stratified iterator.
- **Perf:** `Scene::occluded` still runs a full closest-hit BVH search; a
  dedicated any-hit traversal would pay off much more now that soft shadows
  multiply shadow-ray count (already flagged in scene.rs + the plan's Caveats).

## Update 2026-08-12 — textures + fog DONE; RE-SEQUENCED; PBR + interactive editor scoped

- **DONE since the 2026-08-09 ranking:** glTF **texture mapping** (base color,
  loader stage 2) shipped; **distance fog** shipped (`34b0ef7`, Beer-Lambert
  `Scene::apply_fog`, true no-op at density 0). Ranking items #1 and #2 complete.
- **Two NEW plan docs (committed, origin/main @`aa6baac`):**
  `docs/pbr-materials-plan.md` + `docs/interactive-editor-plan.md` (the latter has
  a References section). They join the pre-existing `path-tracing-plan.md` +
  `live-camera-plan.md`.
- **RE-SEQUENCING DECISION (2026-08-12)** — supersedes the old "3. live-camera
  Pillar 1 … 5. path tracing" tail:
  1. **Interactive-editor Phase A** (retain Scene + decouple camera + `set-camera!`)
     — the accelerator; kills the per-render BVH rebuild, compounds on all later
     work incl. PBR tuning; low-risk, synchronous, byte-identical. Unconditional
     next step.
  2. **Editor Phase B** — wireframe rasterizer.
  3. **PBR** — data model + normal mapping.
  4. THEN decide the realism track: heavy editor Phases C–F **vs** the
     path-tracing reference integrator.
  Flip B↔PBR by near-term goal (image-quality-now → PBR first; tooling → B first).
  A+B is a severable low-risk synchronous slice worth landing alone.
- **Interactive editor = live camera + wireframe editor unified as ONE
  coarse-to-fine producer ladder:** rung 0 = instant **BVH-free** wireframe
  (moving/editing) → rung 1 = coarse trace → rung 2 (finest) = full-res
  sample-progressive trace, converging to the deterministic one-shot `render()`.
  One render thread picks a producer by generation-epoch + idle state; **only
  trace producers touch the accumulator**. Editor **generates Janet code**
  (round-trips via `scripting::eval_string`). Design calls: wireframe renders to a
  **framebuffer → Emacs image buffer** (NO winit/egui/wgpu — GUI stack collapsed;
  software line rasterizer, **zero new deps**: `imageproc`+`ab_glyph` already in
  `film.rs`); `Camera::project` = exact inverse of `Camera::ray` (pixel-exact
  registration; **near-plane clip is the one gotcha**); gizmos = projected line
  segments + 2D hit-test (no gizmo crate); batch vs live = the render thread is a
  **coordinator NOT the parallelism** (both use all cores via Rayon; two entry
  points over one kernel; batch byte-identical).
- **PBR = data-vs-shading split:** do the *data model* (metallic/roughness scalars
  + normal/MR/occlusion map handles, additive & inert) + **normal mapping** NOW;
  **defer the GGX/Fresnel BRDF to path-tracing Stage E** (reads those fields; the
  two plans cross-reference).
  - **Validation-asset gotcha:** every bundled `assets/models/*.gltf` is
    texture-trimmed (base-color + emissive only) — none exercise normal-map/GGX
    paths; re-fetch maps from Khronos glTF-Sample-Assets. **SciFiHelmet = the
    target** (upstream normal+MR+AO, **CC0**). DamagedHelmet has full upstream maps
    but is **CC BY-NC 4.0** — the one non-CC0 asset in the repo. ToyCar declares
    clearcoat/transmission/sheen (deferred). VirtualCity (`~/Documents/devel/vc`)
    is flat-textured (metallic 0, occlusion-only) — not a PBR showcase.
- **Photon mapping considered & DEFERRED (2026-08-12):** path tracing is better
  de-risked (clean `radiance` seam, unbiased → crisp furnace test) vs photon
  mapping (consistent-but-biased, needs a point-kNN structure + two-pass
  restructure). A **caustic-only** photon map is the targeted alt IF caustics
  through the existing glass/dispersion become the goal. No photon-mapping doc.
- Also: user committed Barcelona-chair procedural-mesh examples (`5825b4e`).
