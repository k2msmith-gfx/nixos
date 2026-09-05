---
name: reference-modeler-text-font
description: "Kevin's modeler text-pane font preference = Monaco (macOS system font, runtime-loaded, NOT vendorable); sRGB blending deliberately kept over gamma-correct (looked worse); Zed-quality upgrade paths = swash (pure Rust hinting) or CoreText FFI, both offered and pending"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 2181a6e1-f32a-4207-9fdf-c919efa7c424
---

Modeler text-pane rendering, settled 2026-09-05 with Kevin:

- **Font preference: Monaco** (`/System/Library/Fonts/Monaco.ttf`) — beat bundled JetBrains Mono and Menlo on his display at 14px. Set via `~/.config/modeler/init.janet` (created directly, NOT yet home-manager-managed — he may later move it into ~/nixos like ray's init), guarded with `(when (os/stat ...))` so the same config is Linux-safe (falls back to bundled JetBrains Mono). Monaco/Menlo are Apple-proprietary — never vendor them into the repo.
- `(set-text-font path &opt ttc-index)` loads any local font file at runtime; `~/` expands; bad load keeps current face. `(set-text-size px)` / C-+ / C-- for size (default 14, clamp 8..32).
- **Gamma lesson**: linear-light (gamma 2.2) coverage blending for glyphs was tried and REVERTED — Kevin: "looks worse". Fonts/terminals are tuned around sRGB-space blending; keep the plain sRGB lerp + pixel-grid glyph snapping (that part stayed). Recorded in `blend()`'s doc comment in modeler/src/text.rs.
- **Zed comparison** (Kevin admires Zed's text): Zed is Rust but rasterizes glyphs via CoreText FFI on macOS (glyph atlas + subpixel variants + GPU composite). Offered upgrade paths if ab_glyph ever disappoints again: **swash** (pure Rust, real hinting — on-philosophy) or **CoreText glyph-bitmap FFI** (exact native quality, precedent = libjanet linking). Neither picked yet — Monaco satisfied.

Relates to [[project_modeler]].
