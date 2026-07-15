---
name: user-pbrt-background
description: "User's mental model for ray tracer architecture is pbrt (Physically Based Rendering book/renderer) — use pbrt terminology and comparisons when explaining design choices in the ray project."
metadata: 
  node_type: memory
  type: user
  originSessionId: 72e69d9a-254a-4f9e-b9fd-1d4e42c84c2b
---

The user is familiar with **pbrt** (the Physically Based Rendering book/renderer) and reads this codebase's architecture through that lens. Confirmed when they asked whether `ray`'s `Shape`/`Geometry` naming was "appropriate" — the instinct came from pbrt, where the naming is inverted relative to this codebase: pbrt's `Shape` = `ray`'s `Geometry` (local-space primitive math), pbrt's `Primitive` = `ray`'s `Shape` (geometry + material + transform placed in the scene).

**How to apply:** when explaining or proposing renderer design choices in this project, pbrt comparisons land well and are a fast way to communicate tradeoffs (e.g. `ShaderKind`'s tagged-union dispatch was modeled explicitly on pbrt-v4's `TaggedPointer`, discussed and accepted readily). Feel free to reference pbrt concepts (BSDF, Primitive vs Shape, SAH, NEE, etc.) directly without over-explaining them first.

See [[ray-project-architecture]] for the actual naming mapping, documented in `docs/architecture.md`.
