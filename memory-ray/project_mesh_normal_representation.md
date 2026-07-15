---
name: mesh-normal-representation
description: "Design decision for how the ray renderer represents smooth vs. hard mesh edges — per-corner normal indices, no explicit smoothing-group concept."
metadata: 
  node_type: memory
  type: project
  originSessionId: 72e69d9a-254a-4f9e-b9fd-1d4e42c84c2b
---

Discussed 2026-07-13, ahead of triangle/mesh rendering work (item 2-3 on
[[roadmap-priority]]): how smooth vs. hard edges should be represented
once meshes exist.

**Decision:** the renderer's internal `Mesh` type does not need an
explicit smoothing-group concept at all. The mechanism is **per-corner
normal indices, decoupled from position indices** — each triangle corner
independently references a normal, separate from which vertex position it
references. A hard edge is just two adjacent triangles whose
shared-position corners point at *different* entries in the normal array;
a smooth edge is where they point at the *same* entry. This is exactly
`.obj`'s `f v/vt/vn` face syntax.

**Why not literal smoothing groups:** `.obj` does support them natively
(the `s <group>` / `s off` directive), but most modern exporters
(Blender, Maya, etc.) resolve smoothing groups themselves at export time
and bake the result straight into per-corner `vn` indices — smoothing
groups are an *authoring-time* concept that's already resolved by the
time geometry reaches a renderer. Reconstructing group semantics at
render/load time would be strictly more work for no benefit.

**Practical shortcut:** `tobj` (the recommended `.obj` loader, see
[[steel-procedural-mesh-goal]]) is expected to flatten OBJ's per-corner
`v/vt/vn` indexing into a single shared index per corner during load —
duplicating a vertex's position wherever it needs a different normal, so
you get plain parallel `positions`/`normals` arrays plus one
`indices: Vec<[u32; 3]>` buffer indexing both at once. (Recollection, not
yet verified against the actual crate — check when mesh loading starts.)
If accurate, the internal `Mesh` type can be the plainest possible
indexed-triangle-mesh, with smoothing-group resolution already done
inside `tobj`'s parsing.

**How to apply:** when designing the `Mesh`/`Triangle` geometry type,
don't add a smoothing-group field or any group-to-face bookkeeping. Use
flat `positions: Vec<Vec3>` + `normals: Vec<Vec3>` + one shared
`indices: Vec<[u32; 3]>` (or per-corner position/normal index pairs if a
future loader doesn't pre-flatten like `tobj` does). At a triangle hit,
interpolate the three corner normals by barycentric coordinates (a
byproduct of Möller–Trumbore intersection) for smooth shading, or use the
flat face normal (cross product of two edges) for deliberately faceted
surfaces. This flat representation is also the simplest one for a future
Steel binding to construct procedurally — see [[steel-procedural-mesh-goal]].

Terminology note: "Phong shading" (per-vertex normal interpolation) and
`shader::Phong` (the specular reflection model already in this codebase)
share a name/origin (Bui Tuong Phong) but are unrelated techniques — worth
a clear doc-comment distinguishing them when triangle work starts.
