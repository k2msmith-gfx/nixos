{ pkgs, ... }:

{
  programs.bash.shellAliases = {
    nswitch = "sudo nixos-rebuild switch --flake ~/nixos#kevinix";
    nboot   = "sudo nixos-rebuild boot --flake ~/nixos#kevinix";
    ntest   = "sudo nixos-rebuild test --flake ~/nixos#kevinix";
    nbuild  = "sudo nixos-rebuild build --flake ~/nixos#kevinix";
    ncheck  = "sudo nixos-rebuild dry-build --flake ~/nixos#kevinix";
    msync   = "cd ~/nixos && git add memory-devel/ && git commit -m 'memory: sync from Linux' && git push && cd -";
    kj      = "lsof -ti :4007 | xargs kill -9";
  };

  home.packages = with pkgs; [
    # Editors
    emacs-pgtk
    zed-editor
    code-cursor
    cursor-cli

    # Terminals
    ghostty

    # Fonts
    nerd-fonts.jetbrains-mono

    # GUI
    feh
    thunar
    google-chrome
  ];

  gtk = {
    enable = true;
    cursorTheme = {
      name = "Adwaita";
      size = 24;
    };
  };

  xdg.configFile."niri/config.kdl".source = ../niri/config.kdl;
}
