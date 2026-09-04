---
name: project-ray-generative-ideas
description: Backlog of generative-scene example ideas for ray (brainstormed 2026-08-17); terrain picked first
metadata: 
  node_type: memory
  type: project
  originSessionId: 58d3279b-d336-4043-b459-fc1a403e25f1
---

Generative example ideas brainstormed 2026-08-17, ranked by wow-per-effort.
Existing machinery lowers cost: `sweep-tube`/`transport-frame` (any path),
`grow-branches`, leaf-style grid-mesh building. Already done: trees (+leaves,
fall), coral, spring, leaf profiles, Poisson marble packing, pastel-blocks,
bounce animation.

1. **fBm terrain** — value noise + fBm from scratch (core CG curriculum);
   heightfield grid mesh; altitude-banded materials via per-band mesh split
   (one material per Shape); water plane; distance fog showcase. ~2 evenings.
   **DONE 2026-08-17 (@c47ab79 + wireframe variant @21e4318).**
2. **Lorenz attractor** — **DONE + PUSHED 2026-08-18 (@1cc36ea)**: RK2 (not Euler — claim render-verified: fine at dt
   0.006, fuzz at 0.02), 40 emissive sweep-tube chunks with time-gradient
   color, zero lights, matched user's reference snapshots. Rössler/
   Halvorsen variants = easy follow-ons from the same harness.
3. **Menger sponge** — 20-cube recursion, level 3 = 8k cuboids (BVH stress);
   free second render via :wireframe shader. ~15-line generator.
4. **Phyllotaxis** — **DONE + PUSHED 2026-08-18 (@867cf41)**: full sunflower (Vogel seed head + 21/13 petal whorls from the
   same golden-angle rule + stem/leaf); ANGLE env + *angle-deg* live var;
   ships phyllotaxis-spokes.png companion (ANGLE=137.9 collapse). The
   on-sphere variant (cactus spines) remains an easy follow-on.
5. **3D pipes** — **DONE 2026-08-26, final @34979d1**: self-avoiding random
   walk, occupancy table, sphere elbows only at real turns; iterated to a
   19x12x10 lattice / 55 thin pipes (R 0.09), whole tangle in frame. Used
   analytic `add-cylinder :rotate` (landed same day, @be381a7) instead of
   the sweep-tube plan — one exact cylinder per straight run, no meshes.
   A DoF inside-the-corridor companion was built then CUT (user kept only
   pipes.*; @4aa79ac in reflog; corridor-finding = scan occupancy for
   longest free sightline).
6. **Verlet chains** — relax hanging chains to catenaries, render settled
   state; opens simulation-as-geometry (later: draped cloth).
7. **Voronoi basalt columns** — 2D Voronoi (O(n²) half-plane clip), extrude
   prisms, Giant's Causeway under low sun + soft shadows.

Added 2026-08-18 (re-rank after terrain: phyllotaxis > Lorenz > Menger,
because phyllotaxis is the live-studio killer demo — tweak the golden
angle live and the spiral collapses into spokes):

8. **Seashell** — helico-spiral sweep with growing tube radius;
   sweep-tube/transport-frame machinery is exactly this; banded/spotted
   texture → "Algorithmic Beauty of Sea Shells" in one file.
9. **Terrain erosion pass** — droplet hydraulic erosion over the existing
   fBm height grid (new stage on terrain.janet, not a new scene);
   before/after teaching pair; Janet-side cost → coarse-grid path.

Menger + wireframe-shader caveat: cuboids are analytic (no edge_dist →
no wires); the wireframe render of the sponge needs mesh cubes.

**AVOID: Apollonian glass packing** — tangent transparent spheres hit the
known entering/exiting refraction heuristic footgun (examples/README.md);
fine in matte/metal, wrong in glass.
