---
name: ray-ibl
description: IBL COMPLETE — all stages A–D + follow-ons (chrome-ball, harley-city, load-texture API) DONE + PUSHED 2026-08-27 (origin/main @c79b70b); next per render-features order = emissive glow (HDR post pipeline)
metadata: 
  node_type: memory
  type: project
  originSessionId: fcdce8b5-8e7b-49fb-b7cd-38d03176ef51
---

Image-based lighting for ray, per docs/ibl-plan.md (plan committed earlier; overview in docs/ibl-overview.md). Priority #1 of the sci-fi lens decision in [[ray-render-features]].

**Stage A DONE + committed to main @13abf22 (2026-08-27, 426 tests green, visual check target/test-output/env_map.png):**
- `src/envmap.rs`: `EnvMap` — equirect float-radiance, bilinear (longitude wraps/seam blends, latitude clamps), yaw `:rotate` baked at lookup, `:intensity` scale, total over NaN/inf/zero dirs. NOT a Texture variant (HDR float, direction-addressed, one-per-scene).
- Convention: image center u=0.5 faces **-Z** (default camera forward), row 0 = +Y; longitude increases toward +X; axes land on column *boundaries* for even widths (tests probe diagonals/column centers).
- `image` crate `"hdr"` feature (RGBE decode+encode; encoder used only by tests to write fixtures — no asset files in the suite).
- `Scene.environment: Option<Arc<EnvMap>>`; miss path in render.rs `sky_color` consults env before sky lerp → reflections/refractions free; no-env scenes byte-identical.
- Janet `(set-environment "path.hdr" &named rotate intensity)`, nil clears; builder caches decoded map keyed on (path, rotate, intensity) so per-render scene re-runs don't re-read the file; `%get-environment` + snapshot emits the authored call. Snapshot-reload test needs `boot_with_live` (load-scene lives in live.janet).
- Test subtlety worth keeping: a convex mirror reflects the hemisphere BEHIND the camera — the mirror test tones ahead vs behind differently so it can't pass vacuously off the background.

**Stage B DONE + committed @e1aa5c8 (2026-08-27, 437 tests green, visual check scratchpad ibl-venice-stageb.png / /tmp copies):**
- `rng::cosine_hemisphere_sample` = Malley (disk_sample projected up); cos θ/π cancels Lambert cosine + 1/π BRDF → estimator is a plain average of env lookups over unoccluded dirs.
- `shader::environmental_light` fills the ambient slot of Lambertian/Phong/BlinnPhong (Wireframe inherits); flat `scene.ambient` when no env, SUPERSEDED (not stacked) when env set; Duff-et-al branchless ONB; normal-lift 1e-3 occlusion like soft shadows; env seed = seed ^ 0x3C6E_F372.
- `Scene.env_samples` default 16 (`DEFAULT_ENV_SAMPLES`) + Janet `set-env-samples` + snapshot emission.
- Furnace test is an exact equality (white map × white albedo = 1.0) — deterministic sampling makes pdf slips hard failures.
- Stage A's flat-sky parity test had to narrow to an empty scene once B landed (env now lights surfaces; surface parity needs with_ambient — owned by the B test). Expected-breakage pattern worth remembering.
- Venice render: ground catches dusk-sky color + contact shadows under spheres; visible FIREFLIES from cosine rays hitting HDR sun texels = the Stage C motivation.

**Stage C DONE + committed @23da445 (2026-08-27, 444 tests green, Venice fireflies gone):**
- `Distribution2D` in envmap.rs: marginal-over-rows + conditional-over-columns CDFs, luminance×sinθ weights, continuous placement in texel, f64 cumsums, black-map uniform fallback; `sample_dir(u1,u2)->(dir,pdf/sr)` + `pdf(dir)` (PT's infinite light reuses these verbatim).
- **DEVIATION from plan (documented in ibl-plan.md):** balance-heuristic MIS (`f/(n_cos·p_cos+n_map·p_map)`, summed not averaged) instead of fixed 0.5 weights — fixed weights regress smooth maps below Stage B. PT's full MIS still future.
- `env_samples 1` → map half gets 0 samples → degenerates to exact Stage B cosine path; exactness tests (furnace, byte parity) pinned at n=1, MIS unbiasedness tested as mean-over-50-seeds.
- **Bug worth remembering:** splitting ONE N-rooks stratified set positionally between two strategies biases both (axis-aligned strata → u confined to half the square; measured ~2% dark furnace). Each strategy must draw its own sample_offsets set (different seed salt).
- **Test-design lesson:** a "sun" texel on a coarse map (8×4) is a quarter-hemisphere band — stratified cosine handles it and MIS shows no win; the beats-cosine test needs a sub-stratum sun (64×32 map). Measured 16-sample RMSE: cosine 43.5 → MIS 4.2 (~10×, plan's prediction).

**Stage D DONE + committed @3eb0d7d (2026-08-27, 445 tests green):** assets/hdri/venice_sunset_1k.hdr (Greg Zaal, Poly Haven, CC0, 1k deliberate) + README per assets/models convention; examples/lighting/ibl-helmet.janet + stamped png (SciFiHelmet, photograph-only lighting, :intensity 1.5, native rotation — chosen from a 5-way rotation sweep; example PNGs are stamped startup renders by convention); examples/README.md + docs/janet-scripting.md "Environment lighting (IBL)" section; the_bundled_hdri_decodes test guards the asset.

**Follow-ons (2026-08-27):** @d76e681 examples/models/harley-roadking-city.janet — Road King under assets/hdri/modern_buildings_1k.hdr (2nd bundled CC0 HDRI, Greg Zaal; :rotate 90 glass-facade backdrop; still depends on untracked harley asset [[project_ray_harley_asset]]); @93a9c04 stopped down to :intensity 0.5 (user: 'way too bright' — no tone mapping yet, sky clips at Film::to_rgb8; :intensity doubles as manual exposure until emissive plan's HDR post pipeline); @d6d8986 ground → warm concrete [0.32 0.29 0.25] (neutral gray under blue sky renders LAVENDER — author warm to land neutral); @4c3564b examples/lighting/chrome-ball.janet — Debevec light probe in reverse, sub-second render, doubles as legend for ibl-helmet's light; @c79b70b **(load-texture path) + (material :texture id) BUILT** (texture-mapping plan's deferred Janet API — path-cached per scene, PNG only, snapshot carries :texture id but does NOT replay load-texture; assets/textures/ new dir w/ cobblestone_03 CC0 Charlotte Baglioni, 16→8-bit converted) + Harley ground = tiled cobbles (plane UV = 1 tile/metre, warm albedo tint vs blue-sky lavender; far-field shimmer = known no-mipmap gap).

**IBL COMPLETE.** Next per [[project_ray_render_features]] sci-fi order: 2 emissive glow (docs/post-pipeline-plan.md (renamed from emissive-materials-plan 2026-08-27) — gap is HDR post pipeline exposure/tone-map/bloom at Film::to_rgb8), 3 PBR normal maps; PT's infinite light reuses EnvMap sample_dir/pdf verbatim.
