---
name: reference-janet-cond-material
description: Janet cond with (material ...) branches fails silently for per-instance color randomness — use nested if chains instead
metadata: 
  node_type: memory
  type: reference
  originSessionId: 03b62b83-b6ef-4f04-a3a5-efa591edaaae
---

When writing a `leaf-mat-fn` (or any material-selection function) that picks between several `(material ...)` calls using `cond` + `math/random`, the `cond` form does NOT correctly apply the material — leaves remain their previous/default color.

**Broken pattern:**
```janet
(fn []
  (def r (math/random))
  (cond
    (< r 0.20) (material :albedo [0.80 0.12 0.06] ...)
    (< r 0.50) (material :albedo [0.88 0.36 0.05] ...)
    (< r 0.80) (material :albedo [0.90 0.56 0.07] ...)
    (material :albedo [0.91 0.78 0.12] ...)))
```

**Working pattern:**
```janet
(fn []
  (def r (math/random))
  (if (< r 0.20)
    (material :albedo [0.80 0.12 0.06] ...)
    (if (< r 0.50)
      (material :albedo [0.88 0.36 0.05] ...)
      (if (< r 0.80)
        (material :albedo [0.90 0.56 0.07] ...)
        (material :albedo [0.91 0.78 0.12] ...)))))
```

Root cause not fully diagnosed — `material` sets Rust-side global state (via `%mat-begin`) and returns nil; the `cond` macro may interact poorly with the nil return + the random test in this position. Nested `if` chains are the safe alternative. Confirmed in examples/fall-tree.janet (2026-08-06).
