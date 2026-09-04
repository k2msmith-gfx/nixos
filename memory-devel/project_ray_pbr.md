---
name: ray-pbr
description: PBR materials — Stages A+B + per-pixel metal DONE 2026-08-28 (@718161f normal maps, @24d27fc assets, @6b092f8 mirror_weight tinted-glass visor); GGX deferred to PT; next = path tracing
metadata:
  type: project
---

PBR per docs/pbr-materials-plan.md. Stages A+B DONE + pushed @718161f (2026-08-28, 392+489 tests).

- **Stage A (inert):** Material carries metallic/roughness factors + normal/MR/occlusion texture handles losslessly; loader rebases all FIVE handles (rebase comment warns: every new *_texture field must be added there); Texture.color_space tag (Srgb default / Linear for numeric maps) — tag-only, no decode yet.
- **Stage B (normal mapping):** tangents (glTF TANGENT Vec4 layout, w=±1 handedness, w=0 sentinel = none) thread Triangle→TriHit→LocalHit→Hit; world transform via plain linear map (tangents = directions, NOT the normal matrix); loader reads TANGENT or derives from UV gradient (`geometry::derive_tangents`, Gram-Schmidt + per-vertex accumulation) only when the material has a normal map. Perturbation ONCE at top of `radiance` (`apply_normal_map`) so shading/mirrors/refraction/env/shadows all agree. Guards: hemisphere inversion, degenerate frame, dangling id → geometric normal.
- **Flat-map canary:** [128,128,255] decodes to +0.0039/axis (bytes can't say 0.5) → near-noop test tolerance 0.01, not exact.
- **Asset:** SciFiHelmet normal/MR/AO restored from Khronos at 1024 (normal+MR PNG — JPEG would bend vectors; AO jpg); .gltf images/textures rebuilt; file ships real TANGENT. Helmets transformed: machined metal, not painted detail. Analytic primitives report tangent None → normal maps no-op there (procedural tangents deferred — plane :normal-texture via Janet would need this + Janet material option, both deferred).
- **Deferred:** GGX/Fresnel BRDF + MR/AO application (path tracer Stage E consumes the now-stored data), Janet :normal-texture material option, sRGB decode (tag exists).

Next per [[ray-render-features]]: path tracing — every prerequisite now built (EnvMap sample_dir/pdf, Post pipeline, over-unity emissives, PBR data model).


**Assets follow-on @24d27fc:** FlightHelmet bundled (CC0 Microsoft, 6 materials all normal-mapped, real TANGENT, ~14MB at 1024; base colors → jpg w/ URI rewrite, normal/ORM stay PNG) + examples/models/flight-helmet.janet (IBL+develop only, Venice sun raking leather). Lantern/ToyCar normal maps restored (Lantern has TANGENT; ToyCar exercises UV-derive). **Loader policy fix worth remembering: materials with an MR *texture* leave metallicFactor at default 1.0 (real values painted in the map Whitted can't sample) → factor-derived reflectivity turned everything chrome; loader now skips the mirror term when an MR texture is present (pinned by test).**


**Per-pixel metal @6b092f8 (user-driven: DamagedHelmet visor = tinted glass on Khronos viewer):** DamagedHelmet MR+normal maps restored (trim-era factor overrides removed); `shader::mirror_weight` = metal × quadratic-ramp-below-rough-0.3 from the MR map per pixel; `resolve_reflectivity` = albedo × weight (conductor F0 tint); shaders scale diffuse by 1−weight (METAL HAS NO DIFFUSE — the key insight; suppressing it is what turns pale paint into dark tinted glass). Energy moves, never doubles; no-MR materials byte-identical. **Iteration lesson: damped mirrors for rough metal silver-plate everything (Whitted sharp mirror ≫ GGX blur perceptually) — cutoff, don't damp. And a mirror needs an env with CONTENT: the example moved to modern_buildings IBL + ACES, facade reflections read through the teal tint, matched to user's reference screenshots.**

**DECISION 2026-08-28 (user): sRGB migration deferred to the path-tracer era.** Rationale: it's look-changing for every hand-authored scene, GGX will change the renders far more than gamma, and co-locating both means re-tuning the example gallery once, not twice. Infrastructure is ready when it comes: ColorSpace tags on every texture (normal/MR exempt from decode per spec), output encode belongs in the post pipeline's develop. Remaining reference-vs-ray color differences until then = BRDF gap (biggest, GGX closes it) + environment/exposure choice + sRGB (systematic, smallest).
