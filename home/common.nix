{ pkgs, ... }:

{
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
    neovim
    helix

    # AI / dev tools
    claude-code
    opencode

    # Languages / runtimes
    rustup
    sbcl

    # Language servers
    nixd

    # CLI utilities
    ripgrep
    fd
    yazi
    fastfetch
    shellcheck
    pandoc
    viu
  ];

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
