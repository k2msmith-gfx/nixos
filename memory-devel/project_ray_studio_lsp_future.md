---
name: project_ray_studio_lsp_future
description: "Deferred ray-studio editor-tooling options (live-connection eldoc/goto-def, janet-lsp stub-file); user is trialing the workbench before deciding"
metadata: 
  node_type: memory
  type: project
  originSessionId: 4f03eec1-51d8-4e3e-9ed3-e0962596582d
---

**Deferred 2026-07-27, pending real-world use.** ray-studio ships with janet-lsp OFF by default (`ray-studio-use-janet-lsp` nil — see [[reference_doom_janet_lsp_routing]]), relying on the live-REPL CAPF (completion + docstrings + arglist from the running `(curenv)`, real errors on send). User will **use the workbench for a while first to see what's actually missing** before investing in any of these.

**What's lost without janet-lsp** (accounted honestly): goto-definition / find-references (biggest real loss, matters most if editing prelude.janet or writing new Janet), persistent eldoc signature help while typing args, hover docs on an existing symbol, completion of special forms (`if`/`def`/`fn`/`let` — not in `(curenv)`) and not-yet-loaded source symbols, imenu/outline/rename, as-you-type diagnostics (but those were mostly the false positives we disabled). **Kept:** running-env completion w/ docs+arglist, ground-truth errors on send, the live-edit loop. **When it starts to hurt:** when work shifts from *editing scene data* → *writing substantial Janet* (new helpers, refactoring prelude, cross-file nav).

**Future options to revisit (in rough order of appeal):**
1. **Live-connection eldoc** — wire eldoc to the TCP 4007 connection so the arglist/docstring of the symbol at point shows in the echo area (query the running env, like the existing doc-popup does). Gives signature help WITHOUT janet-lsp's false positives. Smallest, most self-contained win.
2. **Scripts-scoped goto-definition** — a `xref`/command that finds a symbol's `defn`/`def`/`var` across the three script files (prelude.janet, scene.janet, live.janet) via grep or a `(curenv)` `:source-map` query over TCP. Covers the main navigation gap without a static server.
3. **Stub-file approach** (enables full janet-lsp cleanly) — a `stubs.janet` declaring the `%`-cfunctions + shared vars; `prelude.janet` imports it, `scene.janet` imports prelude → a complete on-disk dependency graph janet-lsp can walk, with Rust's real cfunctions overriding the stubs at runtime (like `.d.ts`/C headers). Cost: keep stubs in sync with Rust `register_api` registrations, AND rework the loader so the flat single-core-env live-edit semantics survive the module boundaries `import` introduces (currently everything is `janet_dobytes`'d into `janet_core_env`; import creates separate namespace envs that would fragment the shared mutable `*shapes*`/`*camera*` state live.janet mutates). Could prototype on a branch to gauge intrusiveness. See [[project_ray_janet_scene_architecture]].
4. **Cheap fallback** — just set `ray-studio-use-janet-lsp` t and tolerate the false positives, if navigation/diagnostics turn out to be needed before 1–3 are built.

Related: [[reference_doom_janet_lsp_routing]] (why janet-lsp is off + Doom flycheck-eglot routing), [[ray-next-steps]].
