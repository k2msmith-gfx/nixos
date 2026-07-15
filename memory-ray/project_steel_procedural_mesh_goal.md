---
name: steel-procedural-mesh-goal
description: "User wants Steel (embedded Scheme) scripts to procedurally generate meshes, not just load static files — this constrains the internal mesh storage format design."
metadata: 
  node_type: memory
  type: project
  originSessionId: 72e69d9a-254a-4f9e-b9fd-1d4e42c84c2b
---

The user wants to be able to generate meshes **procedurally from Steel
(Scheme) scripts**, not just load them from `.obj`/`.gltf` files, once the
embedded scripting layer (`docs/steel-scripting.md`) lands.

**Why:** this means the internal `Mesh`/`Triangle` representation the
renderer uses matters more than which file format/loader is picked. Stated
2026-07-13, while discussing mesh format options (recommended `.obj` +
`tobj` for the *file-loading* path — see conversation, no doc written yet
since mesh work hasn't started, "not yet").

**How to apply:** when mesh/triangle geometry design actually starts,
the internal `Mesh` type needs to be **loader-agnostic** — a plain,
simple representation (indexed vertex positions + triangle index list,
optional per-vertex normals/UVs) that both a file loader (`tobj` for
`.obj`) *and* a Steel binding populate equally easily. Don't build the
renderer's `Mesh` type directly around `tobj`'s own structs — that would
make Steel-side procedural generation a bolted-on second-class path
instead of a first-class one. The Steel binding will likely want something
like a `mesh-add-vertex!`/`mesh-add-triangle!` pair or a
`mesh-from-lists` constructor talking to that same simple internal type.

See [[user-pbrt-background]] for related design-conversation context on
this project.
