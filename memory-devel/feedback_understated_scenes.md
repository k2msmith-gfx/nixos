---
name: understated-scenes
description: "User consistently strips flashy scene elements (plasma tubes, display floor) — default to restrained, photographic compositions; comment out rather than delete"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 8ef79e4d-13ae-4bc7-aad2-b58c6d8e682e
---

In the Apollo scenes (2026-08-18) the user removed my showier elements
both times: the reflective display floor in gltf-apollo.janet and the
emissive plasma ring/streaks in gltf-apollo-reentry.janet ("it didn't
look right"). Both times he *commented the code out* rather than
deleting it.

**Why:** solid emissive tubes read as ribbons, not fire — effects the
renderer can't do convincingly look worse than leaving them out. His
taste runs to restrained, photographic compositions (subject + light +
dark).

**How to apply:** when staging example scenes, start minimal — subject,
lighting, one supporting idea — and offer flourishes as options rather
than baking them in. When he cuts something, preserve it as commented
code with a header note (his own pattern), and re-render the shipped PNG
so it matches the file. See also [[confirm-before-push]].
