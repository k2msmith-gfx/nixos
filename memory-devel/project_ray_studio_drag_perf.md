---
name: project-ray-studio-drag-perf
description: "OPEN investigation (2026-08-27) — ray-studio camera-drag wireframe mode slow/jumpy on Kevin's Linux box; tracing verified fully stopped during drag, so suspects are grab-hitch strip latency / Emacs display cost / event rate; Kevin testing on another system next"
metadata: 
  node_type: memory
  type: project
  originSessionId: b5a45112-1446-4d39-8bdd-786a383e8330
---

**Symptom (2026-08-27, Linux):** in ray-studio, the camera-drag wireframe
(raster) mode is "very slow and jumpy" on Kevin's Linux system. Status: OPEN —
Kevin is testing on another system (likely macOS/iTerm2) to compare before we
instrument or fix anything.

**Verified from code (src/live.rs `run_render_loop`), answering "does tracing
stop during a drag?" — YES, completely, by design:**

- Every drag event bumps the generation and stamps `last_change`
  (`bump_and_notify`). An in-flight trace observes the bump only **between
  strips** (strip = cancellation unit, src/render.rs) and abandons the frame.
- While `last_change` is under `SETTLE_TIME` (150 ms), the loop draws ONLY the
  rung-0 wireframe proxy (edge projection, no rays, no BVH), one frame per
  bump, parking between bumps (`park_until_change_or`).
- After 150 ms of quiet it restarts tracing from scratch: `acc.reset()`,
  coarse ladder [16,8,4], then full-res accumulation. Pre-drag samples are
  discarded on purpose (camera moved).

**So the jank is NOT tracer/rasterizer CPU contention. Ranked suspects:**

1. **Grab hitch** — cancellation latency up to ~1 strip of the in-flight
   full-res trace; on a heavy scene (Road King) one strip is a noticeable
   fraction of a second, delaying the FIRST proxy frame. This is the known
   residual logged when D1/D2 landed.
2. **Display cost per proxy frame** — full-res PPM encode → TCP push → Emacs
   image redisplay (kitty graphics in terminal). Usually the FPS ceiling, not
   the raster. Related prior art: WezTerm's kitty path degrades ray-view vs
   iTerm2 ([[reference_ray_view_terminal_rendering]]) — terminal choice may
   explain a per-system difference.
3. **Event rate** — the loop draws exactly one proxy frame per bump, so drag
   smoothness = ray-studio.el's throttled/coalesced event rate minus
   encode/display time.

**Agreed next step if it reproduces:** instrument per-proxy-frame timing during
a Road King drag — wireframe raster ms vs broadcast (encode+push) ms.
Broadcast dominates → downscale proxy frames during drag (draw wireframe at
half res) or throttle harder; raster dominates → edge count; grab hitch →
shrink strip height or check cancellation inside strips.

See [[project_ray_interactive_editor]] for the C2 ladder / D1+D2 design this
sits on.
