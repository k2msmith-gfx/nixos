---
name: project-ray-studio-stream-fix
description: "DONE 2026-08-17: heavy-scene studio stall-until-drag fixed, user-verified live, committed+pushed @b0eb7f4; residual ~20s terrain scene-build lock is inherent (eval thread); follow-up ideas listed"
metadata: 
  node_type: memory
  type: project
  originSessionId: 58d3279b-d336-4043-b459-fc1a403e25f1
---

**RESOLVED + COMMITTED + PUSHED 2026-08-17 (origin/main @b0eb7f4; terrain
example c47ab79 pushed in the same range).** User confirmed live: "I do see
the terrain scene in live mode and it is working properly."

**The bug:** heavy-scene C-c C-l left frames streaming but invisible until
any input event. Three causes/fixes (all in b0eb7f4): server firehose
(~180 MB/s → broadcast_interval caps mid-pass partials at ~40 MB/s,
finished work unthrottled), quadratic per-chunk `concat` in the Emacs
image filter (→ chunk list + peek header + assemble once per frame), and
redisplay only on geometry change (→ forced on geometry change + ~4 Hz
throttle while steady-size frames stream).

**Verification method worth remembering:** couldn't reproduce post-fix, so
launched the studio Emacs with `(server-start)` + new `ray-studio-trace`
(timestamped filter/assembly/paint/redisplay log in *ray-studio-trace*,
default nil, kept in tree) and drove the exact C-c C-l form sequence over
TCP 4007; then screen-recorded (screencapture every 2 s — user granted
Screen Recording to the terminal app, [[reference-repo-paths]]) the user's
own ritual. IMPORTANT: don't poll emacsclient during such a test — each
request is input that forces redisplay and masks exactly this class of bug.
`tools/studio-stream-repro.py` (committed) reproduces the protocol
headlessly against a spawned ray-janet.

**Follow-up DONE 2026-08-17 (user-approved "full cleanup" option):** the
confusing C-c C-l REPL transcript is fixed @dcac2ed — %repl-eval returns
"" for nil (no more bare-nil echoes anywhere), render-when-live marks
requests *render-implicit* so an implicit render on an empty scene stays
quiet (kills the misleading "Nothing to render" mid-load; explicit
(render) still explains itself), "Already live." → "live — rendering",
and janet-clear-and-send-buffer batches bookkeeping into (do ...) on each
side of the buffer (3 sends, quiet replies; trailing reply = done
signal). Also @3cbcee2 fix(test): BVH BUILD_COUNT thread-local (was a
process-global atomic racing parallel tests — ~50% flake on
the_store_survives_..., 5/5 green after). **Both PUSHED 2026-08-17 with
user's explicit OK ([[confirm-before-push]] honored), together with the
terrain-wireframe example @21e4318 (user bumped CELLS default back to
512 — wants the real tessellation; CELLS=120 stays documented as the
legible/fast preview). User tested the new REPL transcript live
2026-08-18: "tested and working". Nothing outstanding.**

**Residual, expected behavior (not a bug):** ~19.5 s scene build for
terrain after C-c C-l. Janet evals serialize on one VM, so camera drags
during the build queue behind it and the studio feels "locked" until it
returns; only sign of life is the `; loading …` REPL line. Follow-up ideas
(none built): REPL line when a live rebuild completes (live_render returns
None silently); suppress the confusing "Nothing to render" during
clear+send; drop (rather than queue) camera gestures while a rebuild is in
flight; speed up terrain generation itself (Janet-side fBm grid dominates).
