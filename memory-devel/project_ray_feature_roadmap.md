---
name: ray-feature-roadmap
description: "post-Janet-migration render-feature roadmap for ray — 4 scoped plan docs (path-tracing, live-camera, pbr-materials, interactive-editor) + sequencing DECISION 2026-08-12 (Editor Phase A → B → PBR → then path-tracing vs heavy editor); photon mapping deferred; glTF assets are texture-trimmed so SciFiHelmet is the PBR validation target"
metadata: 
  node_type: memory
  type: project
  originSessionId: 82786a97-2634-4343-bad7-595aefc25976
---

The "new render features" track that continues [[ray-next-steps]] item (b). Four
scoped plan docs live in `docs/` (all committed, origin/main @ `aa6baac`):
`path-tracing-plan.md` (pre-existing; opt-in `Integrator{Whitted,Path}` enum,
reference-first, furnace test, Stage E = GGX), `live-camera-plan.md`
(pre-existing; retained Scene + interruptible tiled render thread + progressive
accumulation + Emacs mouse), and NEW this session `pbr-materials-plan.md` +
`interactive-editor-plan.md`.

**SEQUENCING DECISION (2026-08-12):** Editor **Phase A** (retain Scene + decouple
camera + `set-camera!`) FIRST — the accelerator that kills the per-render BVH
rebuild and compounds on everything after (incl. tuning PBR); low-risk,
synchronous, byte-identical. Then Editor **Phase B** (wireframe rasterizer). Then
**PBR** (data model + normal mapping). THEN decide the realism track: heavy editor
Phases C–F **vs** the path-tracing reference integrator. A+B is a severable
low-risk synchronous slice worth landing alone. Flip B↔PBR by near-term goal:
image-quality-now → PBR before B; tooling → B before PBR.
**Why:** Phase A's payoff is immediate and compounds; PBR's is partly deferred
(normal maps need re-fetched assets; metallic/roughness only pays off at path
Stage E). **How to apply:** treat Phase A as the unconditional next step.

**Interactive editor = live camera + wireframe editor, unified as ONE
coarse-to-fine producer ladder** (`interactive-editor-plan.md`, staged A–F, tests
per stage, References section): rung 0 = instant BVH-free wireframe (while
moving/editing) → rung 1 = coarse trace → rung 2 (finest) = full-res
sample-progressive trace, converging to the deterministic one-shot `render()`. One
render thread picks a producer by generation-epoch + idle state; **only trace
producers touch the accumulator**. The editor **generates Janet code** (round-trips
via `scripting::eval_string`). Non-obvious design calls:
- Wireframe viewport renders to a **framebuffer → Emacs image buffer** (like ray) —
  NO winit/egui/wgpu; the requirements collapsed the whole GUI stack. Software line
  rasterizer, **zero new deps** (`imageproc` + `ab_glyph` already in `film.rs`).
- `Camera::project` = exact inverse of `Camera::ray` from the same basis → wireframe
  registers pixel-exact with traced frames. **Near-plane clip is the one real gotcha.**
- Gizmos = projected line segments + 2D hit-test (no gizmo crate). Wireframe is
  **BVH-free** → stays instant during object drags; the BVH rebuilds once on settle.
- Batch vs live: the render thread is a **coordinator, not the parallelism** — both
  use all cores via Rayon; two entry points over one kernel, batch byte-identical.

**PBR (`pbr-materials-plan.md`):** do the *data model* (metallic/roughness scalars +
normal/MR/occlusion map handles, stored losslessly, additive & inert) + **normal
mapping** NOW; **defer the GGX/Fresnel BRDF to path-tracing Stage E**, which reads
those fields (the two plans cross-reference). The glTF loader currently FLATTENS
metallic→reflectivity / roughness→shininess and DROPS normal/MR/occlusion maps.
- **Validation-asset gotcha:** every bundled `assets/models/*.gltf` is
  texture-trimmed (base-color + emissive only) — none exercise normal-map/GGX paths;
  re-fetch maps from Khronos glTF-Sample-Assets. **SciFiHelmet = the target**
  (upstream normal+MR+AO, **CC0**). DamagedHelmet has full upstream maps but is
  **CC BY-NC 4.0** — the one non-CC0 asset in the repo. ToyCar declares
  clearcoat/transmission/sheen (deferred). VirtualCity (`~/Documents/devel/vc`) is
  flat-textured (metallic 0, no roughness, occlusion-only) — not a PBR showcase.

**Photon mapping considered & DEFERRED (2026-08-12):** path tracing is better
de-risked (clean `radiance` seam, unbiased → crisp furnace test) vs photon mapping
(consistent-but-biased, harder to validate, needs a point-kNN structure + two-pass
restructure). A **caustic-only** photon map is the targeted alt IF caustics through
the existing glass/dispersion ever become the goal. No photon-mapping doc written.

Also this session (all on origin/main): user committed distance-fog (`34b0ef7`,
Beer-Lambert `apply_fog`, no-op at density 0) + Barcelona-chair examples
(`5825b4e`). Doc plans + References committed (`c4fd658`, `ba59fbd`, `aa6baac`).
Related: [[project_ray_janet_render_params]], [[project_ray_janet_scene_architecture]].
