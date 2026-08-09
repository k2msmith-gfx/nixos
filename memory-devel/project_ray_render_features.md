---
name: ray-render-features
description: "ray rendering-feature roadmap: anti-aliasing DONE, soft shadows DONE (2026-08-08), glTF model loader DONE (2026-08-09, mesh Stage C3). Bang-for-buck ranking + follow-ups. Next candidates: texture sampling (glTF stage 2), cylinder, path tracing/GI."
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
  roughness→BlinnPhong shininess (2/α⁴−2, clamped), shader BlinnPhong. Geometry:
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

## Bang-for-buck ranking (2026-08-08, when picking the step after AA)
Soft shadows was #1 (done). OBJ/model loader was #1 remaining — done as glTF
(2026-08-09). Remaining candidates, in order:
1. **glTF texture sampling (loader stage 2)** — SCOPED, plan in
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
2. **Cylinder primitive** — low ROI (already 6+ primitives); a quick low-stakes
   win only.
3. **Path tracing / global illumination** — SCOPED, plan in
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
