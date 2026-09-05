---
name: reference-memory-sync-nixos
description: "The Claude memory dir IS ~/nixos/memory-devel (home-manager symlink, cross-machine sync via the nixos repo) — memory writes dirty ~/nixos; commit there ('memory: ...' convention) + pull --rebase to sync; ask before push"
metadata:
  type: reference
---

`~/.claude/projects/-Users-kevinsmith-devel-ray/memory` is a **symlink to
`~/nixos/memory-devel`** (home/common.nix; both macOS and Linux point at the
same dir — that IS the cross-machine memory sync). Consequences:

- Every memory write immediately shows as a dirty file in the ~/nixos repo.
- "Git conflicts in ~/nixos" usually = dirty memory-devel blocking `git pull
  --rebase`, not a real conflict. Fix: commit memory-devel (`memory: <what>
  (macOS)` — the existing convention), then pull --rebase, then push (ask
  first per [[feedback-confirm-before-push]]).
- Kevin approved doing a session-end `memory:` commit in ~/nixos to keep the
  sync tidy (offered 2026-09-05, he said "push it").
- The other machine's aliases: `raym` = release modeler + SciFiHelmet,
  `raymb` = build (home/ shell aliases, @ab795d7).

Relates to [[reference-repo-paths]].
