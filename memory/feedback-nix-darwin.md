---
name: feedback-nix-darwin
description: Critical nix-darwin bugs hit during neovim setup and how we fixed them
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 7a0ec372-0bd9-4ec1-8ddd-b5da7c4db82c
---

## programs.neovim.plugins doesn't add to runtimepath on nix-darwin

**Why:** The nix-darwin home-manager neovim wrapper fails to add plugins to neovim's runtimepath. Plugins listed in `programs.neovim.plugins` are built but never found by nvim.

**Fix:** Symlink plugins directly into `~/.local/share/nvim/site/pack/nix/start/` using `home.file`. That path is already in `&rtp` as `pack/*/start/*`.

```nix
home.file = with pkgs.vimPlugins;
  let pack = n: p: { name = ".local/share/nvim/site/pack/nix/start/${n}"; value = { source = p; }; };
  in builtins.listToAttrs [ (pack "plugin-name" plugin-derivation) ... ];
```

**How to apply:** Always use `home.file` for neovim plugins on nix-darwin, never `programs.neovim.plugins`.

---

## programs.neovim.extraPackages doesn't add to PATH on nix-darwin

**Why:** Same wrapper issue — packages in `extraPackages` aren't reliably on PATH.

**Fix:** Add runtime dependencies (`guile`, `janet`, etc.) to `home.packages` in `common.nix` instead. LSP servers (`rust-analyzer`, `nixd`) are in `extraPackages` which works well enough for neovim's LSP use.

---

## nvim-treesitter API changed in nixpkgs 26.05 (nvim-treesitter 0.10)

**Why:** The `configs` module was removed. `require('nvim-treesitter.configs')` no longer exists.

**Fix:** Use `require('nvim-treesitter').setup()` and enable highlighting via FileType autocmd:
```lua
vim.api.nvim_create_autocmd("FileType", {
  callback = function() pcall(vim.treesitter.start) end,
})
```

---

## nvim-treesitter queries are at runtime/queries/ not queries/

**Why:** nixpkgs packages nvim-treesitter with queries under `runtime/queries/` but neovim searches for `queries/` at each rtp entry.

**Fix:** Prepend the runtime subdir to rtp in init.lua:
```lua
vim.opt.rtp:prepend(vim.fn.stdpath('data') .. '/site/pack/nix/start/nvim-treesitter/runtime')
```

---

## withAllGrammars doesn't include compiled parser .so files

**Why:** `nvim-treesitter.withAllGrammars` only ships query files, not compiled parsers.

**Fix:** Install individual parser packages from `pkgs.vimPlugins.nvim-treesitter-parsers.*` as separate `home.file` pack entries:
```nix
let parser = n: p: { name = ".local/share/nvim/site/pack/nix/start/parser-${n}"; value = { source = p; }; };
```

---

## MIT Scheme not available on macOS (aarch64-darwin)

Package is `mitscheme` in nixpkgs but refuses to evaluate on darwin. Use `chicken` or `guile` instead for Scheme on macOS.
