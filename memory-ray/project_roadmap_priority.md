---
name: roadmap-priority
description: "User's stated priority order for upcoming ray renderer work — BVH, then triangles, then mesh loading, then Steel scripting."
metadata: 
  node_type: memory
  type: project
  originSessionId: 72e69d9a-254a-4f9e-b9fd-1d4e42c84c2b
---

Stated 2026-07-13, current priority order for the `ray` project:

1. **Complete the BVH** — tree build/traversal is in progress (`src/bvh.rs`,
   `docs/bvh-plan.md`); user is implementing the tree itself, assistant
   scaffolded `Aabb`/`local_bounds`/slab-test. Known open issues from a
   code-inspection pass (not yet fixed as of this note): infinite-plane
   bounds produce NaN through `Shape::new`'s `transformed()` call,
   `partial_cmp(...).unwrap()` can panic on NaN centroids (fix:
   `f32::total_cmp`), `t_min` not enforced on leaf hits, `max_leaf_size = 0`
   causes infinite recursion.
2. **Learn to render triangles** — a `Triangle` `Geometry` impl, explicitly
   framed as a learning step before mesh loading.
3. **Load/render meshes** — `.obj` via `tobj` recommended for the file
   loader (see [[steel-procedural-mesh-goal]] for why the *internal* mesh
   representation needs to stay loader-agnostic, independent of this file
   format choice).
4. **Steel (Scheme) scripting integration** — deliberately last; see
   `docs/steel-scripting.md` (design agreed, deferred) and
   [[previs-repl-architecture]] for the live-previs vision that builds on
   top of it.

**How to apply:** don't push mesh-loading or Steel-integration work ahead
of BVH/triangle work unless the user explicitly redirects — this is a
deliberate sequencing choice, not just an arbitrary backlog order.
