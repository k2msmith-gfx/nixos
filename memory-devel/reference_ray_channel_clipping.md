---
name: reference-ray-channel-clipping
description: point light intensity × albedo > 1.0 clips channels to 255 — orange can render as yellow/green if G clips; keep intensity below 1/max_albedo_channel
metadata: 
  node_type: memory
  type: reference
  originSessionId: 03b62b83-b6ef-4f04-a3a5-efa591edaaae
---

When a point light intensity × albedo exceeds 1.0 per channel, the channel clips to 255. If this happens to both R and G equally, orange becomes yellow. If G clips while B stays low, the result looks yellow-green, which users perceive as "green."

**Example (fall-tree):** pumpkin orange albedo G = 0.52. Sun at [2.5 2.5 2.4]:
- G channel: 0.52 × 2.5 = 1.30 → clipped to 255
- R channel: 0.92 × 2.5 = 2.30 → clipped to 255
- Result: (255, 255, 25) = bright yellow — looked green to the user

**Fix:** keep `light_intensity < 1.0 / max_albedo_channel`. For albedo G=0.52, max safe sun = ~1.9. For albedo R=0.92, max safe sun = ~1.1 (to keep any headroom). Compensate with higher ambient.

**Safe pattern for warm fall leaves:**
```janet
(set-ambient [0.38 0.36 0.34])
(add-point-light [...] [1.1 1.05 1.0])   # dim sun, no G blowout
```

**Also:** specular highlights add to all channels — even if diffuse stays below 1.0, a specular term can push G over. Use lambertian for highly-saturated leaves to avoid this.
