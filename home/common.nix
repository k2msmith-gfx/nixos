{ pkgs, config, lib, ... }:

let
  projectSlug = (builtins.replaceStrings [ "/" ] [ "-" ] config.home.homeDirectory) + "-nixos";
  rayProjectSlug = builtins.replaceStrings [ "/" ] [ "-" ] (config.home.homeDirectory + "/Documents/devel/rust/ray");
in
{
  imports = [ ./neovim.nix ];

  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  programs.bash = {
    enable = true;
    shellAliases = {
      ll      = "ls -lah";
      la      = "ls -A";
      ".."    = "cd ..";
      "..."   = "cd ../..";
      grep    = "grep --color=auto";
      rg      = "rg --smart-case";
      g       = "git";

      nup     = "nix flake update ~/nixos";
      ngc     = "sudo nix-collect-garbage -d";
      nrepl   = "nix repl '<nixpkgs>'";
      nsearch = "nix search nixpkgs";
    };
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
    initExtra = ''
      export PATH="$HOME/.config/emacs/bin:$PATH"

      PS1='\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '

      HISTSIZE=10000
      HISTFILESIZE=20000
      HISTCONTROL=ignoreboth
      shopt -s histappend
      shopt -s checkwinsize
      fastfetch
    '';
  };

  home.packages = with pkgs; [
    # Editors
    helix

    # AI / dev tools
    claude-code
    opencode

    # Languages / runtimes
    rustup
    sbcl
    janet
    steel

    # LSP servers
    nil                 # Nix language server

    # CLI utilities
    ripgrep
    fd
    yazi
    fastfetch
    shellcheck
    pandoc
    viu
  ];

  programs.bash.sessionVariables.STEEL_HOME = "${config.home.homeDirectory}/.local/share/steel";

  home.activation.steelHome = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "${config.home.homeDirectory}/.local/share/steel"
    $DRY_RUN_CMD ${pkgs.rsync}/bin/rsync -a --no-perms --delete \
      "${pkgs.steel}/lib/steel/" \
      "${config.home.homeDirectory}/.local/share/steel/"
  '';

  home.activation.claudeMemoryLink = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    target="${config.home.homeDirectory}/nixos/memory"
    link="${config.home.homeDirectory}/.claude/projects/${projectSlug}/memory"
    $DRY_RUN_CMD mkdir -p "$(dirname "$link")"
    if [ "$(readlink "$link" 2>/dev/null)" != "$target" ]; then
      $DRY_RUN_CMD rm -rf "$link"
      $DRY_RUN_CMD ln -s "$target" "$link"
    fi
  '';

  home.activation.claudeRayMemoryLink = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    target="${config.home.homeDirectory}/nixos/memory-ray"
    link="${config.home.homeDirectory}/.claude/projects/${rayProjectSlug}/memory"
    $DRY_RUN_CMD mkdir -p "$(dirname "$link")"
    if [ "$(readlink "$link" 2>/dev/null)" != "$target" ]; then
      $DRY_RUN_CMD rm -rf "$link"
      $DRY_RUN_CMD ln -s "$target" "$link"
    fi
  '';

  xdg.configFile."doom/init.el".source     = ../doom/init.el;
  xdg.configFile."doom/config.el".source   = ../doom/config.el;
  xdg.configFile."doom/packages.el".source = ../doom/packages.el;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.git = {
    enable = true;
    settings = {
      user.name  = "Kevin Smith";
      user.email = "k2msmith@gmail.com";
      init.defaultBranch = "main";
      pull.rebase        = true;
    };
  };

  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11.0;
    };
    settings = {
      # Window
      window_padding_width    = 12;
      background_opacity      = "0.95";
      hide_window_decorations = "yes";

      # Cursor
      cursor_shape            = "block";
      cursor_blink_interval   = "0.5";

      # Scrollback
      scrollback_lines        = 10000;

      # Clipboard / bell
      copy_on_select          = "yes";
      enable_audio_bell       = "no";

      # Shell integration (prompt tracking, marks, nvim scrollback)
      shell_integration       = "enabled";

      # Tabs
      tab_bar_style           = "powerline";
      tab_powerline_style     = "slanted";

      # Catppuccin Mocha
      background           = "#1e1e2e";
      foreground           = "#cdd6f4";
      selection_background = "#f5e0dc";
      selection_foreground = "#1e1e2e";
      cursor               = "#f5e0dc";
      cursor_text_color    = "#1e1e2e";

      color0  = "#45475a"; color8  = "#585b70";
      color1  = "#f38ba8"; color9  = "#f38ba8";
      color2  = "#a6e3a1"; color10 = "#a6e3a1";
      color3  = "#f9e2af"; color11 = "#f9e2af";
      color4  = "#89b4fa"; color12 = "#89b4fa";
      color5  = "#f5c2e7"; color13 = "#f5c2e7";
      color6  = "#94e2d5"; color14 = "#94e2d5";
      color7  = "#bac2de"; color15 = "#a6adc8";
    };
  };

  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        padding      = { x = 12; y = 12; };
        opacity      = 0.95;
        decorations  = "None";
        dynamic_title = true;
      };
      scrolling.history = 10000;
      font = {
        normal  = { family = "JetBrainsMono Nerd Font"; style = "Regular"; };
        bold    = { family = "JetBrainsMono Nerd Font"; style = "Bold"; };
        italic  = { family = "JetBrainsMono Nerd Font"; style = "Italic"; };
        size = 11.0;
      };
      colors = {
        primary   = { background = "#1e1e2e"; foreground = "#cdd6f4"; };
        cursor    = { text = "#1e1e2e"; cursor = "#f5e0dc"; };
        selection = { text = "#1e1e2e"; background = "#f5e0dc"; };
        normal = {
          black   = "#45475a"; red     = "#f38ba8";
          green   = "#a6e3a1"; yellow  = "#f9e2af";
          blue    = "#89b4fa"; magenta = "#f5c2e7";
          cyan    = "#94e2d5"; white   = "#bac2de";
        };
        bright = {
          black   = "#585b70"; red     = "#f38ba8";
          green   = "#a6e3a1"; yellow  = "#f9e2af";
          blue    = "#89b4fa"; magenta = "#f5c2e7";
          cyan    = "#94e2d5"; white   = "#a6adc8";
        };
      };
      cursor = {
        style          = { shape = "Block"; blinking = "On"; };
        blink_interval = 500;
      };
      selection.save_to_clipboard = true;
    };
  };
}
