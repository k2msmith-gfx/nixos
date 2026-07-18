---
name: project-neovim
description: "Neovim config in home/neovim.nix — languages, plugins, keybindings, SBCL workflow"
metadata: 
  node_type: memory
  type: project
  originSessionId: 7a0ec372-0bd9-4ec1-8ddd-b5da7c4db82c
---

Neovim is configured in `home/neovim.nix`, imported via `home/common.nix`, so both machines get it.

## Working languages
- **Rust** — LSP via `rust-analyzer` (in `extraPackages`), treesitter
- **Common Lisp (SBCL)** — Conjure via Swank on port 4005, treesitter (`commonlisp` parser)
- **Janet** — Conjure (not yet tested end-to-end), treesitter (`janet_simple` parser)
- **Nix** — LSP via `nixd`, treesitter
- **Steel Scheme** — LSP via `steel-language-server`, Conjure stdio REPL (`steel` binary, prompt `λ > `), `.steel` files mapped to `scheme` filetype, treesitter via `scheme` parser
- **Treesitter only** — scheme, lua, toml, bash, markdown, markdown_inline

## SBCL + Conjure workflow
Quicklisp is installed. Add to `~/.sbclrc`:
```lisp
(ql:quickload :swank :silent t)
(swank:create-server :port 4005 :dont-close t)
```
Then just run `sbcl` — Conjure auto-connects when a `.lisp` file is opened.

## Plugins (managed via home.file, NOT programs.neovim.plugins — see [[feedback-nix-darwin]])
- catppuccin-nvim (Mocha theme)
- nvim-treesitter.withAllGrammars (query files only — parsers are separate)
- conjure
- plenary-nvim + telescope-nvim
- nvim-cmp + cmp-nvim-lsp + cmp-buffer + cmp-path
- Individual parser packages in `nvim-treesitter-parsers.*`

## Key bindings
- Leader: `<Space>`, LocalLeader: `,`
- `<Space><Space>` find files, `<Space>/` grep, `<Space>b` buffers
- `gd` go-to-def, `gr` references, `K` hover, `<Space>rn` rename, `<Space>ca` code action, `<Space>f` format
- `[d`/`]d` diagnostics, `<C-h/j/k/l>` window navigation
- Conjure: `,ee` eval form, `,eb` eval buffer, `,lv` open log

## LSP
Uses `vim.lsp.config` + `vim.lsp.enable` (neovim 0.11+ built-in API). nvim-lspconfig was dropped — deprecated on neovim 0.12.3.

## Scheme REPL history
Guile stdio integration with Conjure was unreliable (prompt pattern issues, value not captured). MIT Scheme not available on macOS. Chicken Scheme was tried but abandoned.

Steel Scheme REPL added (2026-07-18): Conjure stdio client pointing at `steel` binary with prompt pattern `"λ > "`. Not yet tested end-to-end — if prompt pattern is wrong, it will need adjustment by running `steel` and observing the actual prompt string.
