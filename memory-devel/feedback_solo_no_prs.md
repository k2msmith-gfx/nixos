---
name: feedback-solo-no-prs
description: "ray (and user's repos) are solo projects — don't use or suggest GitHub PRs"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 5d52b543-338c-4da9-9585-c246150c3bc7
---

ray and the user's other repos (e.g. [[reference_repo_paths]]) are solo projects. The user does not use GitHub pull requests.

**Why:** Solo developer, single author — PRs add ceremony with no reviewer.

**How to apply:** Integrate branches by merging/fast-forwarding into `main` locally, then push. Don't offer to open PRs or frame branch work around a PR flow. Pushing a feature branch to origin as a backup is fine.
