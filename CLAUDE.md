# NixOS / nix-darwin Configuration

Flake-based system config for 3 machines: 1 NixOS, 2 macOS (aarch64-darwin).

## Machines

| Host | Platform | Username | Home |
|------|----------|----------|------|
| `kevinix` | NixOS x86_64 (Lenovo laptop) | `kevin` | `/home/kevin` |
| `kevmac` | macOS aarch64 (nix-darwin, MacBook) | `kevinsmith` | `/Users/kevinsmith` |
| `kevmini` | macOS aarch64 (nix-darwin, Mac mini) | `kevinsmith` | `/Users/kevinsmith` |

## File Layout

```
flake.nix                   # inputs + outputs (nixosConfigurations, darwinConfigurations)
configuration.nix           # NixOS system config (kevinix)
hardware-configuration.nix  # auto-generated, don't edit by hand
home/
  common.nix                # shared home-manager config (both platforms)
  linux.nix                 # NixOS-only home-manager additions
  darwin.nix                # macOS-only home-manager additions
modules/
  darwin/system.nix         # nix-darwin system-level settings (kevmac)
  desktop/niri.nix          # Niri Wayland compositor config (NixOS only)
niri/config.kdl             # Niri keybindings/layout (symlinked via linux.nix)
```

## Rebuild Commands

**NixOS (kevinix):**
```bash
nswitch   # sudo nixos-rebuild switch --flake ~/nixos#kevinix
nboot     # rebuild to boot, don't activate yet
ntest     # activate without making it the boot default
nbuild    # build only, don't activate
ncheck    # dry-build (syntax/eval check)
```

**macOS (kevmac / kevmini):**
```bash
nswitch   # sudo -H darwin-rebuild switch --flake ~/nixos#<hostname>
nbuild    # darwin-rebuild build --flake ~/nixos#<hostname>
```

**Flake inputs:**
```bash
nup       # nix flake update ~/nixos  (update all inputs)
ngc       # sudo nix-collect-garbage -d
```

## Claude Memory Sync

Auto-memory files live in `memory/` (git-tracked). Each machine's Claude project memory path is symlinked there via `home.file` in `common.nix`:

- macOS: `~/.claude/projects/-Users-kevinsmith-nixos/memory` → `~/nixos/memory`
- Linux: `~/.claude/projects/-home-kevin-nixos/memory` → `~/nixos/memory`

Memories sync via `git pull` / `git push` — no extra tooling needed. After adding a memory on one machine, commit and push `memory/`; pull on others.

## Key Conventions

- `home/common.nix` is imported by both platforms — keep it platform-agnostic.
- Platform-specific packages/services go in `linux.nix` or `darwin.nix`.
- `emacs-pgtk` is Linux/Wayland only; macOS uses plain `emacs`.
- nixpkgs channel: `nixos-26.05` / `home-manager release-26.05` / `nix-darwin-26.05`.
- `noctalia` overlay is applied on NixOS only (provides custom packages).
- Flake inputs are pinned via `flake.lock`; run `nup` deliberately, not as routine.

## Notable System Details (kevinix)

- Display server: Niri (Wayland compositor), launched via `tuigreet`.
- Audio: PipeWire (PulseAudio disabled).
- Kernel module `lenovo-acpi` loaded; mic LED disabled on boot.
- `sudo` timeout extended to 60 minutes (`timestamp_timeout=60`).
- Nix store auto-optimised; GC runs weekly, keeps 30 days.
