{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    extraPackages = with pkgs; [
      rust-analyzer
      nixd
      steel-language-server
    ];

    initLua = ''
      -- Leader keys
      vim.g.mapleader = " "
      vim.g.maplocalleader = ","  -- Conjure uses localleader

      -- Options
      local o = vim.opt
      o.number         = true
      o.relativenumber = true
      o.signcolumn     = "yes"
      o.tabstop        = 2
      o.shiftwidth     = 2
      o.expandtab      = true
      o.smartindent    = true
      o.wrap           = false
      o.termguicolors  = true
      o.scrolloff      = 8
      o.updatetime     = 250
      o.undofile       = true
      o.splitright     = true
      o.splitbelow     = true

      -- Theme
      require("catppuccin").setup({ flavour = "mocha" })
      vim.cmd.colorscheme("catppuccin")

      -- nvim-treesitter puts queries under runtime/queries/ but neovim searches queries/
      -- Prepend the runtime/ subdir so highlights.scm etc. are found
      vim.opt.rtp:prepend(vim.fn.stdpath('data') .. '/site/pack/nix/start/nvim-treesitter/runtime')
      require("nvim-treesitter").setup()
      vim.api.nvim_create_autocmd("FileType", {
        callback = function()
          local ok, err = pcall(vim.treesitter.start)
          if not ok then vim.notify(err, vim.log.levels.WARN) end
        end,
      })

      -- Completion
      local cmp = require("cmp")
      cmp.setup({
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"]      = cmp.mapping.confirm({ select = true }),
          ["<Tab>"]     = cmp.mapping.select_next_item(),
          ["<S-Tab>"]   = cmp.mapping.select_prev_item(),
          ["<C-e>"]     = cmp.mapping.abort(),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "buffer" },
          { name = "path" },
        }),
      })

      -- LSP (neovim 0.11+ built-in API)
      local caps = require("cmp_nvim_lsp").default_capabilities()
      vim.lsp.config("*", { capabilities = caps })

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local map = function(k, f) vim.keymap.set("n", k, f, { buffer = ev.buf }) end
          map("gd",          vim.lsp.buf.definition)
          map("gr",          vim.lsp.buf.references)
          map("K",           vim.lsp.buf.hover)
          map("<leader>rn",  vim.lsp.buf.rename)
          map("<leader>ca",  vim.lsp.buf.code_action)
          map("<leader>f",   function() vim.lsp.buf.format({ async = true }) end)
          map("[d",          vim.diagnostic.goto_prev)
          map("]d",          vim.diagnostic.goto_next)
        end,
      })

      -- Conjure
      vim.g["conjure#log#hud#enabled"] = true
      vim.g["conjure#log#hud#height"]  = 0.4

      -- Telescope
      local tb = require("telescope.builtin")
      vim.keymap.set("n", "<leader><leader>", tb.find_files)
      vim.keymap.set("n", "<leader>/",        tb.live_grep)
      vim.keymap.set("n", "<leader>b",        tb.buffers)
      vim.keymap.set("n", "<leader>h",        tb.help_tags)

      -- Window navigation
      vim.keymap.set("n", "<C-h>", "<C-w>h")
      vim.keymap.set("n", "<C-j>", "<C-w>j")
      vim.keymap.set("n", "<C-k>", "<C-w>k")
      vim.keymap.set("n", "<C-l>", "<C-w>l")

      -- Clear search highlight
      vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

      -- Steel Scheme: treat .steel files as scheme
      vim.filetype.add({ extension = { steel = "scheme" } })

      -- Steel language server
      -- STEEL_HOME must be writable; the Nix wrapper sets it to the store (read-only)
      -- but uses setenv(..., 0) so we can override it here.
      vim.lsp.config("steel_ls", {
        cmd = { "steel-language-server" },
        cmd_env = { STEEL_HOME = vim.fn.expand("~/.local/share/steel") },
        filetypes = { "scheme" },
        root_markers = { "steel.toml", ".git" },
      })
      vim.lsp.enable({ "rust_analyzer", "nixd", "steel_ls" })

      -- Conjure: use steel binary for scheme REPL
      vim.g["conjure#client#scheme#stdio#command"]        = "steel"
      vim.g["conjure#client#scheme#stdio#prompt_pattern"] = "λ > "
    '';
  };

  # programs.neovim.plugins doesn't add to runtimepath on nix-darwin.
  # Symlinking directly into the pack path (which is already in &rtp) is the fix.
  # withAllGrammars only ships query files; compiled parsers are separate packages.
  home.file = with pkgs.vimPlugins;
    let
      pack   = n: p: { name = ".local/share/nvim/site/pack/nix/start/${n}";        value = { source = p; }; };
      parser = n: p: { name = ".local/share/nvim/site/pack/nix/start/parser-${n}"; value = { source = p; }; };
    in builtins.listToAttrs ([
      (pack "catppuccin-nvim"  catppuccin-nvim)
      (pack "nvim-treesitter"  nvim-treesitter.withAllGrammars)
      (pack "conjure"          conjure)
      (pack "plenary-nvim"     plenary-nvim)
      (pack "telescope-nvim"   telescope-nvim)
      (pack "nvim-cmp"         nvim-cmp)
      (pack "cmp-nvim-lsp"     cmp-nvim-lsp)
      (pack "cmp-buffer"       cmp-buffer)
      (pack "cmp-path"         cmp-path)
    ] ++ (with nvim-treesitter-parsers; [
      (parser "commonlisp"      commonlisp)
      (parser "scheme"          scheme)
      (parser "rust"            rust)
      (parser "janet-simple"    janet_simple)
      (parser "lua"             lua)
      (parser "nix"             nix)
      (parser "toml"            toml)
      (parser "bash"            bash)
      (parser "markdown"        markdown)
      (parser "markdown-inline" markdown_inline)
    ]));
}
