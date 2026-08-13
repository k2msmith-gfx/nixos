---
name: reference-ray-view-terminal-rendering
description: "ray-view renders cleaner in iTerm2 than WezTerm on macOS; WezTerm's kitty-graphics path breaks up fine detail"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 711b8d8f-e7ba-42a6-ae19-0e8bf8caa525
---

On macOS, `ray-view` (`src/bin/ray-view.rs`; `viuer` auto-detects the terminal)
produces a noticeably better image in **iTerm2** (its own inline-image protocol)
than in **WezTerm** (kitty graphics protocol): under WezTerm, fine detail — e.g.
text baked into the rendered scene — looks broken up, as if some pixels didn't
transfer or aren't displayed correctly. iTerm2 is the preferred macOS host for
now.

Cause not yet diagnosed. Leading candidate: `draw()` sizes the frame in terminal
*cells* (`width: cols`, `height: rows-2`), so viuer downscales; WezTerm's
kitty-graphics resampling/chunking seems to handle that worse than iTerm2's
protocol. Prospective fix would transmit at native pixel resolution on the kitty
path rather than fit-to-cells. The ray-view docstring's claim that
WezTerm/kitty/Ghostty give "full-res" is optimistic on WezTerm.

Related: [[project_ray_interactive_editor]].
