# Memory Index

- [User's pbrt background](user_pbrt_background.md) — reads renderer architecture through pbrt terminology; pbrt comparisons land well.
- [Steel procedural mesh goal](project_steel_procedural_mesh_goal.md) — mesh format must be loader-agnostic so Steel scripts can generate meshes, not just load files.
- [Previs + REPL architecture](project_previs_repl_architecture.md) — live 3D window (macroquad) driven by Steel REPL; implies future workspace split.
- [Roadmap priority](project_roadmap_priority.md) — order: BVH → triangles → mesh loading → Steel scripting. Don't push later items ahead of it.
- [Mesh normal representation](project_mesh_normal_representation.md) — smoothing = per-corner normal indices, no smoothing-group concept in the renderer.
