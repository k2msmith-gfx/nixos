---
name: reference-ray-set-sky
description: "set-sky gradient direction in ray — first arg = nadir (a=0, looking down), second = zenith (a=1, looking up); a = 0.5*(y+1)"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 03b62b83-b6ef-4f04-a3a5-efa591edaaae
---

`(set-sky bottom top)` in `scripts/prelude.janet` maps to `scene.sky_bottom` and `scene.sky_top`.

The blend in `render.rs`:

```rust
let a = 0.5 * (unit_dir.y + 1.0);
(1.0 - a) * scene.sky_bottom + a * scene.sky_top
```

So:
- **first arg = nadir** (ray pointing straight down, y = -1, a = 0) — pure `bottom`
- **y = 0 (horizontal)**: 50/50 mix
- **second arg = zenith** (ray pointing straight up, y = +1, a = 1) — pure `top`

For a **daytime sky**, zenith is darker/deeper blue and horizon is pale:
```janet
(set-sky [0.74 0.86 0.98]   # nadir / horizon: pale blue-white
         [0.18 0.42 0.80])  # zenith: deep clear blue
```

For a **night sky** (as in tree.janet):
```janet
(set-sky [0.06 0.09 0.15] [0.13 0.20 0.30])
```

**Gotcha:** it is easy to accidentally reverse the args, making zenith lighter than the horizon — the opposite of a real sky. The bottom arg is NOT the "lower sky" you see near the horizon; since the camera typically looks roughly horizontally, nadir-direction rays rarely hit the sky at all (they hit the ground plane). The visible sky gradient is mainly the upper hemisphere, so `top` dominates what the camera sees as "sky color."
