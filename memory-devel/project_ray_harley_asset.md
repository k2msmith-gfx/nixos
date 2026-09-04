---
name: project-ray-harley-asset
description: RESOLVED 2026-08-27 @9e37009 — harley asset committed as extracted (~14MB, license.txt included, zip gitignored); fresh clones run all three harley examples
metadata: 
  node_type: memory
  type: project
  originSessionId: d690a0b1-925c-4765-96c0-fa169ac6ab69
---

The Harley-Davidson Road King example (`examples/gltf-harley-roadking.janet`,
pushed @f141d46 2026-08-26) loads `examples/assets/harley/scene.gltf`, but that
asset dir (24 MB unpacked + 10 MB zip still beside it) is **untracked** — a
fresh clone can't run the example. Decision pending: (1) leave untracked
(header documents the Sketchfab source + CC-BY-4.0 credit for re-download),
(2) commit trimmed — drop the zip, downscale the 23 baseColor PNGs to JPEG per
the `assets/models/README.md` convention (~3–5 MB), or (3) commit as-is.
Recommended (2). Also relevant to [[project-ray-release-naming]]'s crates.io
size-cap audit. Asset: everhard's FLHRXS Road King Special, CC-BY-4.0, 53
meshes / 23 baseColor maps, metric, noses toward -Z, wheels bottom at file
y=-0.49. Lighting lesson in the scene comments: black vehicles need large soft
flanking sources, not a hard key.


**RESOLVED 2026-08-27 @9e37009 (user: "commit/push everything except copyright materials"):** committed extracted scene.gltf/.bin + 23 textures + license.txt (~14 MB, no texture trim needed); the redundant 10 MB zip stays local via `.gitignore` (`examples/assets/harley/*.zip`). CC-BY-4.0 attribution carried in license.txt + every scene header. Fresh clones now run harley-roadking{,-city,-venice,-wireframe}.
