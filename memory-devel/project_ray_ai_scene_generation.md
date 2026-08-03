---
name: project-ray-ai-scene-generation
description: "goal 3 of ray = AI-generated Janet scenes from NL/reference image; one-shot Python sidecar built (tools/scene_gen.py), pending user API-key setup"
metadata: 
  node_type: memory
  type: project
  originSessionId: bf7d3a31-1cad-4493-b287-ae3636c5d216
---

Kevin's `ray` ray tracer has three stated goals: (1) learn Rust, (2) create content for an **intro computer-graphics class**, (3) experiment with **AI generating Janet scenes from a spoken/written description or a reference image**.

**Goal 3 status (as of 2026-07-31):**
- Design captured in `docs/ai-scene-generation.md` (committed to main). Core idea: the Janet scene DSL is an ideal LLM target (small declarative vocab + full Janet for procedural layout, and safe-by-construction so model output can be eval'd live). Loop: NL/image → Claude emits Janet → load via existing `--scene`/TCP REPL → render → (optional) feed PNG back for critique.
- One-shot sidecar **built**: `tools/scene_gen.py` (+ `tools/requirements.txt`). Python, text **and** image input, `claude-opus-4-8`, streamed, adaptive thinking. System prompt assembled at runtime from `scripts/prelude.janet` (the API source of truth) + `examples/pastel-blocks.janet` + `examples/glass-box.janet`, with prompt caching (~4588-token prefix, over Opus's 4096 cache min). Writes `out/generated.janet`, prints the render command. **Validated offline only** (compiles, `--help`, error paths, prompt assembly, fence-stripping) — NOT yet run against the live API. **`tools/` is uncommitted** as of this note; suggested adding `out/` to `.gitignore`.

**Blocker:** user has **Claude Pro (consumer subscription)**, which does **NOT** include API access. Running the sidecar needs a separate **Anthropic Console** account + pay-as-you-go credits (~10–20¢/run, cheaper with cache). User intends to implement/run the sidecar later ("let me get back to you").

**Interim path that works today:** Claude Code itself acts as the sidecar — given a description/image it writes the `.janet` directly using the same prelude+examples grounding (did this to produce `out/generated.janet`, a pastel-blocks variant). The render→critique loop can also be driven manually through Claude Code (paste the PNG, get an adjusted scene). This is the zero-cost way to trial goal 3 before paying for API.

Deferred tier-2: the **agentic** sidecar (tool-runner: model writes Janet → `load_and_render` returns PNG → self-critique → refine) — build only after the one-shot proves out.

Related: CubeCL was evaluated and **rejected** for goals 1&2 (GPU-kernel DSL, not idiomatic Rust, obscures the CG math that reads like the textbook on the CPU path); **triangle geometry** ranked as the strongest next *renderer* feature for the class goal (BVH already anticipates `Bvh<Triangle>`; do a minimal `Triangle`+OBJ cut before the two-level/instanced BVH). See [[project-ray-next-steps]].
