---
name: ray-post-pipeline
description: POST PIPELINE ARC FULLY COMPLETE 2026-08-28 (@0533855) — all stages + the example re-authoring pass done and pushed; next feature per sci-fi order = PBR normal maps, then path tracing
metadata:
  type: project
---

Post pipeline for ray per docs/post-pipeline-plan.md (renamed from emissive-materials-plan 2026-08-27; emissive glow = motivating client). Priority #2 of the sci-fi ordering in [[ray-render-features]], after [[ray-ibl]].

**Stage A DONE + pushed @c2ac2c5 (2026-08-28, 367+462 tests):**
- `src/post.rs`: `Post { exposure, tone_map }`, `ToneMap::{Clamp, Reinhard, Aces}`; default = byte-identical clamp (pinned). Reinhard luminance-scaled = hue-preserving (orange→yellow fix, pinned); ACES Narkowicz per-channel = filmic desaturating roll-off.
- `Scene.post` + `with_post`; film funnel `to_rgb8` + all 4 wrappers take `&Post` (every output path must name its develop — no silent skips); film never modified (pinned).
- Janet `set-exposure` / `set-tone-map :clamp|:reinhard|:aces` + snapshot emission; `scripting::current_post()` → save-image re-develops last render under CURRENT builder post, no re-trace (verified live: 156 s Venice trace, 3 instant re-develops).
- Live loop develops under scene-snapshot post; post change still re-traces (noted acceptable; future = post-only dirty path).
- **Venice comparison result (copies in /tmp/tonemap-*.png): exposure 1.8 + Clamp blows sunset white; + ACES holds sky but pales it; + Reinhard lifts bike AND keeps saturated orange — Reinhard is the scene's keeper.** Venice/city examples NOT yet re-authored to use post (user decision pending).

**Stage A.5 DONE + pushed @0bde9b1 (2026-08-28, 373+469 tests):** `ToneMap::Lut(Arc<Lut3d>)` — .cube parser (red-fastest order PINNED by test — classic transposition bug), trilinear sample, domain clamp; ToneMap/Post lost Copy (Arc) → clones at live/ray-janet sites; `(set-tone-map :lut "path.cube")` w/ builder lut_cache + lut_path for snapshot readback; failed load leaves operator unchanged (no silent downgrade). Bundled demo assets/luts/ektachrome-ish.cube is PROCEDURAL (own ~15-line formula: S-curve, cyan shadows, blue×1.035, sat×1.10) — unencumbered, "inspired-by not calibrated"; third-party film LUTs land near-not-exact under gamma-naive convention. Verified on ibl-helmet (/tmp/lut-off.png vs /tmp/lut-ektachrome-ish.png).

**No-practicals A/B result (Venice, /tmp/tonemap-5..7):** exposure+Reinhard recovers brightness but NOT directional modeling — key light earns its keep, spill is ~redundant under develop. **USER DECISION: re-author shipped examples (venice/city adopting post etc.) deferred to the LAST stage of the project.**

**Stage B bloom DONE + pushed @7dab69d (2026-08-28, 379+476 tests):** `Bloom{threshold 1.0, knee 0.5, strength 0.5}` on Post; `Post::develop(w,h,pixels)` = new image-level funnel entry (bloom is spatial; `apply` stays per-pixel bloomless path). THREE as-built corrections, each test-caught: (1) 2×2 box downsample drifts halo half-texel/level → 3×3 tent anchored at even texels (symmetry test); (2) summing mips → far-field plateau + energy blowup → progressive AVERAGE combine (up+mip)/2, self-normalizing, monotonic; (3) bare bilinear reach too short → per-level tent blur (dual-filter) + stop chain at coarsest ≥8px (2×2 mip = flat veil). Janet `(set-bloom :threshold/:knee/:strength)` / `(set-bloom nil)`, snapshot emit. Neon scratch validation /tmp/bloom-1-clamp.png vs bloom-2-aces-bloom.png: clamp renders authored-ORANGE tube YELLOW + flat; ACES+bloom = white core + colored halo + glowing reflections. add-cuboid arg order gotcha: (SCALE-half-extents ROTATION TRANSLATION material).

**Stage C DONE + pushed @427464b (2026-08-28, 381+478 tests):** gltf crate feature `KHR_materials_emissive_strength`; `convert_material` folds strength into emissive Color (factor [1,.5,.25] × 4 → [4,2,1], pinned via tests/assets/tri_emissive.gltf); no bundled asset uses the extension yet.

**Stage D DONE + pushed @e6f5389 (2026-08-28, 382+479 tests):** examples/lighting/neon.janet + png (3 tubes via add-cylinder-on :rotate, wet floor, fog, chrome sphere, console screen; ACES + bloom :strength 0.9); docs/tone-map-comparison.png (Venice: clamp/reinhard/aces) + docs/bloom-comparison.png (neon off/on), both re-develop-generated + DejaVu-labeled via nix imagemagick (-font path needed, no fontconfig in sandbox); janet-scripting.md "The post pipeline (develop)" section; glow pinned end-to-end in render tests. **Composition lesson: neon must be ACTUALLY bright — emissive ~5 halos invisibly (luminance bright-pass extracts ~40% of a thin line), ~13 gives white core + halo. Blue emitters halo weakest (0.0722 luminance weight).**

**Stage E DONE + pushed @65fab13 (2026-08-28, 383+480 tests):** `Film::save_hdr` (raw scene-referred plate, bypasses post, atomic rename); Janet `(save-hdr &opt path)` via *save-hdr-requested* flag plumbing, served in batch + live loops, defaults --out with .hdr ext; round-trip pinned via EnvMap::from_hdr; validated full-circle (neon render → plate → set-environment → chrome probe lit by its own tubes). Also @3fc925b neon legibility fix (practical + sphere placement — user caught the 'artifacts').

**POST PIPELINE COMPLETE.** Remaining in the arc: the deferred example re-authoring pass (user: last stage of project — venice/city adopt set-exposure/tone-map, spill light removal candidate). Next features per [[ray-render-features]] sci-fi order: PBR normal maps, then path tracing (EnvMap sample_dir/pdf + Post + emissive all pre-built for it).


**Re-authoring pass DONE + pushed @8f38f41/@0533855 (2026-08-28, 383+480 green):** city → native intensity + ACES (facade reads, plaza sunlit); venice → exposure 1.8 + Reinhard, SPILL RETIRED (lift replaced it), key kept (develop lifts brightness, only a light creates direction); ibl-helmet → exposure 1.5 + Reinhard (sunset band appears where clamp blew white); lantern → bundled Lantern.gltf given KHR_materials_emissive_strength 4 (documented in assets/models/README — panes genuinely glow under ACES + default-threshold bloom; per-material Janet emissive targeting on glTF groups still impossible, update-material hits all members); chrome-ball left raw on purpose. :intensity back to light-balancing only.
