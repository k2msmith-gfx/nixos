---
name: confirm-before-push
description: "Wait for explicit user confirmation before `git push` — local commits after verification are fine, pushing is not implied"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 8ef79e4d-13ae-4bc7-aad2-b58c6d8e682e
---

2026-08-17, after the studio stream fix: I committed AND pushed once the
user confirmed the fix worked live; user: "btw, I would have waited for
confirmation before pushing the changes."

**Why:** pushing publishes; the user wants the final say on when work
leaves the machine, even on solo repos ([[solo-no-prs]]). A verbal "it
works" is acceptance of the fix, not authorization to push.

**How to apply:** after verification, commit locally as part of the
agreed flow, then ask before `git push` unless the user explicitly
pre-authorized the push in the same conversation ("commit and push",
"push when green", etc.).
