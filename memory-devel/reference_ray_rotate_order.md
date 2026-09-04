---
name: ray-rotate-order
description: "ray's :rotate [rx ry rz] composes Z-INNERMOST (v' = Rx·Ry·Rz·v) — cost two wrong attitude renders in the reentry scene; screen-space attitude solve recipe inside"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 8ef79e4d-13ae-4bc7-aad2-b58c6d8e682e
---

ray's `:rotate [rx ry rz]` (add-mesh/add-tube/load-gltf) applies **Z
innermost**: `v' = Rx(rx)·Ry(ry)·Rz(rz)·v`. Assuming X-innermost gives
mirrored/toward-camera attitudes — it cost two wrong renders in
gltf-apollo-reentry.janet (2026-08-18). A single-axis Y rotation (the
Earth-globe hemisphere solve) can't distinguish the conventions, which is
why the wrong assumption survived the museum scene.

To aim a model's local +Y (apex) at a target world direction while
staying perpendicular to the camera axis ("lean in screen space"):
target = up·cos(lean) + screen_right·sin(lean), where screen_right =
(−d̂z, 0, d̂x) for view dir d̂; then solve
apex = (−sinγ·cosβ, cosγ·cosα − sinγ·sinβ·sinα, cosγ·sinα + sinγ·sinβ·cosα)
for [α=rx, β=ry, γ=rz] — pick γ (lean amount) first, β from the x
equation, α from z then verify y. Worked example: 47° lean toward
screen-right from camera [3.7 0.7 5.2] → [-59, -31.8, -45]
(gltf-apollo-reentry.janet).
