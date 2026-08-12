---
name: reference_repo_paths
description: Local paths for the main repos used in this project
metadata: 
  node_type: memory
  type: reference
  originSessionId: 64c575b2-dc31-45ab-ba9e-12e9efd32849
---

- `~/devel/ray-zig` — Zig 0.16 port of ray tracer (benchmark comparison); GitHub: k2msmith-gfx/ray-zig (private)
- `~/nixos` — NixOS config (GitHub: k2msmith-gfx/nixos, HTTPS remote, pulls without SSH)
- `~/devel/ray` — main ray renderer (GitHub: k2msmith-gfx/ray, SSH remote). **MOVED here 2026-07-28** from `~/Documents/devel/rust/ray` to escape iCloud-sync churn (iCloud kept dropping `" 2"` duplicate files under ~/Documents and occasionally scrambled git's index mid-operation). Now the **same path on macOS and Linux**. This also changed the Claude project slug → the memory symlink in `~/nixos/home/common.nix` (`rayProjectSlug`) was updated to `~/devel/ray`, and the macOS aliases in `darwin.nix` (dv/rayj/rayjr/rayjb/rays) were repointed; **requires `nswitch` to apply**. The other POC repos below were NOT moved (still under ~/Documents on macOS).
- `~/Documents/devel/rust/ray-janet-poc` — Janet scripting POC
- `~/Documents/devel/rust/ray-steel-poc` — Steel scripting POC
- `~/Documents/devel/rust/ray-ecl-poc` — ECL scripting POC
- `~/Documents/devel/rust/embedded-lang-benchmarks` — benchmark suite

SSH key required for all rust repos: `~/.ssh/id_ed25519` (has passphrase). The nixos repo itself is HTTPS (pulls/pushes without SSH).

**Passphrase handling (set up 2026-07-27):**
- **macOS (kevmac/kevmini):** `~/.ssh/config` has `Host *` with `AddKeysToAgent yes` + `UseKeychain yes` + `IdentityFile ~/.ssh/id_ed25519`. Passphrase stored in login Keychain (`ssh-add --apple-use-keychain` run once) → key auto-loads on login, no prompt across reboots. This `~/.ssh/config` is hand-managed, NOT via home-manager (deliberately, to avoid home-manager taking over the file).
- **Linux (kevinix):** managed declaratively in `~/nixos/home/linux.nix` — `services.ssh-agent.enable` + `programs.ssh.matchBlocks."*"` (`addKeysToAgent`/`identityFile`). Passphrase prompted once per boot (terminal prompt, no GUI askpass), held by the user ssh-agent until reboot/logout. No keyring (niri/greetd desktop, no GNOME/KDE). Committed `~/nixos` @9161ce9, pushed; NOT yet applied — run `ntest`/`nswitch` on the box.
- If a session ever can't push (agent empty), run `ssh-add ~/.ssh/id_ed25519` in the terminal (via `! ssh-add ...`); the model can't enter the passphrase.
