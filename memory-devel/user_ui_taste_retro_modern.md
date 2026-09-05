---
name: user-ui-taste-retro-modern
description: "Kevin's UI design lens for the modeler — \"retro and modern at the same time\"; use to steer future UI decisions"
metadata: 
  node_type: memory
  type: user
  originSessionId: 60399a1c-d529-491a-8e1b-d7c4c3af3640
---

Kevin (2026-09-05, after M4 + polish): "i love the direction we are going with the UI design - retro and modern at the same time."

**The lens:** retro = real Emacs/terminal bones — minibuffer + echo area, status/mode line, keymaps, monospace, doom-one palette, zero chrome (no dialogs, toolbars, buttons, GUI toolkit). Modern = what runs inside those bones — fuzzy pickers, marking menus, translucent HUDs, agent panel, progressive traced renders in-pane.

**How to apply:** when a new UI need appears, first ask "what is the Emacs-shaped answer?" (a command, a minibuffer prompt, a transient overlay, a keymap) and then make that answer feel current (completion, streaming, alpha-blends) — never reach for chrome/dialog/widget solutions. Confirmed decisions in this spirit: file I/O via minibuffer ([[project-modeler]]), spacebar-maximize center-stage-only, Janet-configurable theme/HUD, agent panel styled as Claude Code's terminal UI. Related prioritization lens: [[user_scifi_interest]].
