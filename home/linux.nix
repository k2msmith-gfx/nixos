{ pkgs, ... }:

{
  programs.bash.shellAliases = {
    nswitch = "sudo nixos-rebuild switch --flake ~/nixos#kevinix";
    nboot   = "sudo nixos-rebuild boot --flake ~/nixos#kevinix";
    ntest   = "sudo nixos-rebuild test --flake ~/nixos#kevinix";
    nbuild  = "sudo nixos-rebuild build --flake ~/nixos#kevinix";
    ncheck  = "sudo nixos-rebuild dry-build --flake ~/nixos#kevinix";
  };

  home.packages = with pkgs; [
    # Editors
    emacs-pgtk
    zed-editor
    code-cursor
    cursor-cli

    # Terminals
    kitty
    ghostty

    # Fonts
    nerd-fonts.jetbrains-mono

    # GUI
    feh
    thunar
    google-chrome
  ];

  xdg.configFile."niri/config.kdl".source = ../niri/config.kdl;
}
