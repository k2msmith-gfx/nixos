---
name: ray-path-tracing
description: "Path-tracing plan A–F ALL COMPLETE (F Sponza PUSHED @06326b9 2026-09-03); Sponza fetch recipe + ~1h interior render reality; next = multi-scatter GGX / firefly clamp / whatever is next; byte-identity recipe"
metadata: 
  node_type: memory
  type: project
  originSessionId: 8e3137bb-9814-487a-ba1e-64d6cd5f3dc6
---

Path tracing (docs/path-tracing-plan.md), the 2nd integrator beside Whitted.

**Stage A DONE 2026-09-01 @28549f6:** `src/integrator.rs` owns the `Integrator` enum
(`Scene::integrator`, default Whitted), dispatching `radiance()` (all four render entry
points), Whitted body moved verbatim + helpers + tests, Janet `(set-integrator
:whitted|:path)` (prelude keyword→code), `%get-integrator`, snapshot round-trip.

**Stage B DONE 2026-09-01 @b437fd5:** `integrator::path` = diffuse reference tracer.
Cosine-weighted walk (reuses shader::orthonormal_basis + rng::cosine_hemisphere_sample),
throughput×albedo (pdf cancels), resolve_emissive at every hit, sky_color = env emitter,
RR from bounce 3 capped 0.95, max_depth = safety cap, fog NOT applied under :path.
Horizon guard: geometric normal threaded TriHit→LocalHit→Hit (Option in LocalHit, None =
"same as shading"; oriented to interpolated normal's side), below-horizon samples
zero-weighted, bounce origins offset along geo normal. Tests: exact white/albedo furnaces
(convex+cosine ⇒ zero-variance equalities), tilted-normal furnace pins the guard, emissive
sphere → closed-form albedo·L_e·(r/d)², 1/√N convergence, determinism, sealed-corridor
termination. Example: examples/lighting/cornell-box.janet (768²@512spp ≈ 14 s, Reinhard
e2.2, emissive panel 18.4/14.6/7.1). The bright halo on the ceiling around the panel is INTENTIONAL and user-approved 2026-09-01 (panel is a physical cuboid glowing from all faces, hung 5mm below the ceiling) — do not "fix" it to match classic flush-mounted Cornell references. Live progressive accumulation works with :path for
free (accumulate_pass goes through the same radiance seam). 504 tests. PUSHED to origin/main 2026-09-01.

**Stage E DONE 2026-09-03 (GGX):** 4th Bsdf lobe — isotropic GGX, height-correlated Smith
G2, Schlick F0=albedo (conductor), α=roughness² floored at MIN_ROUGHNESS 0.05, **VNDF
sampling** (Heitz 2018, weight ≤ F·G2/G1 ≤ 1, no sampler fireflies). Engages when
per-pixel metal>0 (factor×MR texel); `reflectivity` then IGNORED under :path (it's
Whitted's flattening of the same data — double-count guard); diffuse ×(1−metal); Whitted's
mirror_weight heuristic retired path-side. Smooth-lobe generalization: has_diffuse→
has_smooth, eval/pdf include GGX (NEE glints on rough metal, MIS just works), overlapping
smooth lobes use mixture estimator f·cos/pdf; pure-diffuse fast path keeps Stage B exact
arithmetic → **pre-E :path renders bit-identical (pixel-diff verified)**. Janet
:metallic/:roughness keys (prelude mat-emit + %set-material 32-34 + %entry-material +
snapshot round-trip). KEY TEST: rough-1 furnace = closed form env·(1−ln 2) (α=1 VNDF =
cosine distribution; integral derived in-test) — measured 0.1539 vs 0.1534 analytic. Also:
pdf-integrates-to-1 MC, reciprocity, smooth-limit=mirror furnace, MR-map per-pixel gating.
glTF default material (no pbrMetallicRoughness) = metallic 1 rough 1 per spec → renders
dull metal under :path now. Deferred, named: multi-scatter energy compensation (rough
metal darkens by exactly the closed form), dielectric 0.04 GGX, shininess-driven gloss.
Example: examples/lighting/cornell-metals.janet (gold ×3 roughness 0.05/0.25/0.6, 768spp
~48s). 538 tests.

**Env-map NEE DONE 2026-09-03** (right after E): HDR env light-sampled via IBL's existing
EnvMap::sample_dir/pdf (reused whole, both pub, tested) — one env shadow ray to INFINITY
per smooth vertex in direct_light + escape-path MIS weight power_heuristic(prev_pdf,
env.pdf(dir)); gradient sky deliberately NOT sampled (keeps furnace tests exact + env-free
:path renders bit-identical, pixel-diff verified). Tests: uniform-EnvMap furnace =
double-count sentinel; single blazing texel (~1e-3 sr) matches from-scratch closed form
(a/π)·L·Δφ·(cos²θ₀−cos²θ₁)/2 within 5%. ggx-grid re-shot: speckle gone, diffuse row
properly sun-lit; final committed chart = 3072spp (~55s) — residual specks at 768 were
two-bounce sphere-to-sphere sun glints (specular-chain, NEE-immune, fade 1/√N; radiance
clamp/denoiser = named firefly options if ever wanted). ~55 lines integrator + 3 tests.
541 tests. ALL PUSHED 2026-09-03: origin/main @71a7c2f (D @f3081a8, E @c7f7ae0, ggx-grid
@0e2e578, envNEE @d23bfa9, 3072spp bump @71a7c2f).

**Stage F DONE 2026-09-03 @06326b9 (PUSHED; rebased atop the modeler-plan docs from the other machine): PLAN A–F COMPLETE.** Sponza: Intel
2022 remaster, CC BY 4.0, dl link https://cdrdv2.intel.com/v1/dl/getContent/830833 (4GB
zip main_sponza.zip; glTF subset ~2.8GB extracted to gitignored assets/models/sponza/,
fetch recipe in assets/models/README.md + example header). Loader risk = NONE: only
optional KHR_lights_punctual, 405 indexed-tri primitives full attrs, load-gltf unchanged
(~10s load+BVH). examples/models/sponza.janet: cam [-11 3 0]→[12 5 0] fov60, kloofendal
:rotate 90 :intensity 3 (sunset HDRIs too low to enter atrium — probed), Reinhard e9.0
(e6 too dim — killed a 15-min render over it; Reinhard protects sun patch, exposure lifts
bounce-lit arcades). 960×540@1536spp = ~54 min (the plan's samples/time note, stated in
header). Interior = slow case: direct sky only in courtyard, arcades all multi-bounce.
zsh gotcha: `set -- $v` doesn't word-split unquoted vars (SH_WORD_SPLIT off) — bit a probe
loop. **Firefly clamp DONE 2026-09-04 @8d8e02b (local):** (set-clamp-indirect n), Scene.clamp_indirect
0=off default (bit-identical, pixel-diffed). KEY SEMANTICS LESSON: "indirect" = ≥2
SCATTERING EVENTS, not loop bounces — first draft clamped bounce≥1 emission and darkened
the emissive-sphere closed form to 0.375 (MIS routes big emitters' DIRECT energy through
the 1-bounce BSDF path). Exempt: first-vertex NEE, camera-seen and single-scatter
emitters/sky. Clamp at collection points (never throughput), hue-preserving scale.
Deterministic tests via 2-mirror periscope (scatter-count 2 exactly). Janet knob +
snapshot round-trip. User instruction: committed sponza 2K + ggx-grid PNGs stay as-is —
do NOT re-render.

**OIDN denoiser DONE + PUSHED 2026-09-04 (clamp @8d8e02b, OIDN @2b8436d, sponza-denoised example @e3f49f7 — origin/main @e3f49f7):** sponza-denoised.janet = 128spp+denoise 2K frame in 21min vs 8h, halves indistinguishable in /tmp/sponza-split.png comparison. `oidn` cargo feature (off-default; oidn
crate 2.5.1 wrapping nixpkgs openimagedenoise 2.4.1, aarch64-darwin OK). .#janet nix shell
now carries openimagedenoise + OIDN_DIR (build: --features janet,oidn; outside nix shell
export OIDN_DIR=$(nix build nixpkgs#openimagedenoise --print-out-paths)). Two doors:
(set-denoise true) → HDR film at do_render funnel pre-tonemap (preview+save-image+save-hdr
all see it; live progressive stays raw) + `ray-janet --denoise in.png|.hdr --out out` for
existing images (.png = LDR mode, weaker; 2K sponza ≈ 330ms). Feature-off binaries report
+ ignore. oidn crate API: Device::new()→Result, RayTracing::try_new, filter_in_place.
TEST LESSON: synthetic noise must be WHITE (Wang-hash per pixel) — structured hash
patterns read as texture to the CNN and survive. Named upgrade: albedo/normal AOV guide
buffers. **User deferred LIGHT PORTALS** (still the Sponza-shaped unbiased win, ~Stage-D
sized) — next along with multi-scatter GGX + dielectric 0.04.

**Overnight 2K frame LANDED + committed 2026-09-04 @9428151 (local):** 2048×1152@3072spp,
8.0h actual vs 8.2h predicted — the scaling law held. Shipped sponza.png is this frame.

**Byte-identity verification recipe (learned Stage A):** committed example PNGs can NEVER
be reproduced byte-for-byte — the `--out` save is stamped with a caption containing
Mpix/s, varying per run (rows ~24–46, top-left). Verify by rendering the same scenes with
HEAD-worktree vs new binaries and pixel-diffing, excluding rows < ~64 (scratchpad
pngdiff.py — pure-python PNG decode; no PIL/magick on this Mac). Also: ray-janet drops
into its REPL after `--out` unless stdin is redirected (`</dev/null`) — background
scripts hang without it.

**Pre-existing drift noticed:** examples/geometry/mesh-cone.png is stale relative to main
(both Stage A and pre-Stage-A binaries agree with each other, differ from the committed
PNG well below the caption). Worth a re-render sweep of committed example PNGs someday.

Related: [[project_ray_pbr]] (GGX = Stage E), [[project_ray_post_pipeline]] (tone map
prebuilt — plan decision 4 was already satisfied).

**Stage D DONE 2026-09-03 (NEE+MIS):** src/emitter.rs `EmitterTable` built in Scene::new
(scene materials frozen post-construction; live edits rebuild) — uniform world-area
sampling of emissive shapes: uniform-scale spheres, cuboid 6 faces, rects, mesh tris (area
CDF); excluded (BSDF-only fallback, unbiased): planes/cylinders/ellipsoids,
emissive-TEXTURED materials, env map (env NEE = named deferral, the HDRI-sun win).
Samplable emitters stamped `Shape.light: Option<u32>` → `Hit.light` for the emission-side
MIS lookup. path(): per diffuse vertex (Bsdf::has_diffuse) NEE = ALL LightKind lights
(no MIS — not geometry, BSDF can't hit them) + 1 uniformly-picked emissive shape with
power-heuristic MIS vs Bsdf::pdf; emission at hits weighted by prev_pdf vs emitter
solid-angle pdf (full weight after camera/specular — Stage C's `specular` flag pays off).
**Delta lights restored with physical inverse-square (I/d²)** — new physics :path-only,
Whitted keeps no-falloff. Empty-scene NEE draws zero rng → furnace tests still exact
equalities. Key tests: point-light inverse-square EXACT closed form, rect panel vs
from-scratch analytic view factor, tiny (r/d)²=1e-4 emitter NEE nails/brute-force can't,
sphere-light→point-light mean, emissive-sphere closed form doubles as double-count
sentinel. Cornell PNGs re-shot same spp: box 1.43MB→948KB (noise entropy), ~2× render
time (28s) for far less noise. 528 tests (janet).

**Stage C DONE 2026-09-01 @a1ff740 (PUSHED):** src/bsdf.rs = the explicit
BSDF interface (user requested "a more obvious interface in Rust"): Bsdf::from_hit →
diffuse/mirror/transmit lobes (Whitted energy layering, MR-map aware), sample/eval/pdf +
specular flag (Stage D MIS-ready), eval/pdf-reproduces-weight self-consistency test.
Single-live-lobe fast path skips the selection draw → all-diffuse :path renders
bit-identical (committed cornell-box.png reproduces exactly). TIR → reflect inside; per-lobe
horizon guards; :abbe dispersion NOT interpreted under :path (spectral, deferred). Tests:
mirror furnace exact, glass furnace mean, mirror/glass-see-emitter exact, half-mirror
k+(1−k)a. Example: examples/lighting/cornell-spheres.janet (mirror+glass, real caustic,
1024spp/depth32, ~36 s). 515 tests.
