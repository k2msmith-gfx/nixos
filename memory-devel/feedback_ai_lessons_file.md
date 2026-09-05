---
name: feedback-ai-lessons-file
description: "docs/ai-lessons.md in the ray repo = the canonical, versioned AI lessons corpus — read it when authoring scenes, append new earned lessons there (not only to local memory)"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 60399a1c-d529-491a-8e1b-d7c4c3af3640
---

Kevin's decision (2026-09-05, @d6649af): scene-authoring lessons must persist across sessions AND machines, so the canonical home is **`docs/ai-lessons.md` in the ray repo** (git-versioned), not only this local memory directory.

**Why:** local Claude memory is machine-locked; Kevin works on multiple machines; the file is also loaded into the in-app AI tiers' system prompts (modeler-ai.md hard part #5), so a lesson written there teaches every AI seat, not just me.

**How to apply:** when acting as the scene-authoring sidecar (or building modeler AI features): read `docs/ai-lessons.md` at session start; when a session earns a new gotcha (the [[reference_ray_rotate_order]] / [[reference_ray_set_sky]] class), distill it into that file — terse entry, the failure it prevents — and commit it, in addition to any local memory note. Keep it prompt-sized; prune stale entries. Related: [[project-modeler]].
