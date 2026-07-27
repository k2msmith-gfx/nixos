---
name: feedback_autonomous_implementation
description: "For multi-step implementation tasks the user has approved, run to completion autonomously (no stage-by-stage approval); report at the end"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: a5b14c6f-813c-426a-875d-64418cd7b2eb
---

Once the user has approved a plan / said "go", execute the whole multi-step task **autonomously to completion** — do NOT stop for per-stage confirmation. Report once at the end with a consolidated summary + verification results. Only interrupt for a genuine blocker or a decision that can't be reasonably defaulted.

**Why:** User explicitly asked (2026-07-26, during the Janet→ray migration) for "less interaction/approvals." This refines [[feedback_ray_poc_collaboration]]: the stage-by-stage confirmation applied to *POC exploration*; for *approved implementation work* they want fewer interruptions.

**How to apply:** After a "go", batch the work, keep a self-tracked checklist, surface only the final result. Suggest Shift+Tab (auto-accept edits) / bypass-permissions mode to reduce prompt friction on build-heavy tasks.
