---
name: reference_janet_docstring_position
description: "Janet gotcha: a defn docstring only registers as :doc when it comes BEFORE the arg list, not after — otherwise it's a silent no-op body expr"
metadata: 
  node_type: memory
  type: reference
  originSessionId: a5b14c6f-813c-426a-875d-64418cd7b2eb
---

In Janet, a `defn` docstring is only stored as the binding's `:doc` when it appears **before the parameter/arg list**:

```janet
(defn add-sphere
  "Add a sphere at CENTER with RADIUS."   # ← registers as :doc
  [center radius]
  ...)
```

Placing the string **after** the arg list (the Clojure-ish `(defn name [args] "doc" body)` habit) does NOT register it — Janet treats it as an inert first body expression (a no-op) and the docstring is silently lost. Verified on Janet 1.41: `after-args` → `:doc` is just the auto signature `"(after-args i)\n\n"` with empty body; `before-args` → full doc.

`(get (get (curenv) (symbol "NAME")) :doc)` returns `"SIGNATURE\n\n<docstring>"` — Janet auto-prepends the arglist signature line + blank line. `describe`/`janet_description` of that string keeps newlines as literal `\n` escapes (2 chars), so they survive the eval server's `.replace('\n', " ")` collapse.

**Bit us in [[ray-janet-poc]]:** every docstring in `live.janet`/`scene.janet` and prelude's `shader-code` was placed after the arg list, so none registered — the new Emacs completion doc popups would have shown nothing. Fixed by moving them all before the arg list (2026-07-26). See [[ray-next-steps]].
