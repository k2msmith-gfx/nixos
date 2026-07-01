{ pkgs, ... }:

{
  programs.bash.shellAliases = {
    nswitch = "darwin-rebuild switch --flake ~/nixos#kevmac";
    nbuild  = "darwin-rebuild build --flake ~/nixos#kevmac";
  };

  home.packages = with pkgs; [
    # Use plain emacs on macOS (emacs-pgtk is Linux/Wayland-only)
    emacs
  ];
}
