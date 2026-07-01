{ pkgs, ... }:

{
  system.stateVersion = 5;

  nixpkgs.hostPlatform = "aarch64-darwin";

  nix.settings.experimental-features = "nix-command flakes";

  # macOS system defaults
  system.defaults = {
    dock.autohide = true;
    finder.AppleShowAllExtensions = true;
    NSGlobalDomain.ApplePressAndHoldEnabled = false;
  };

  programs.zsh.enable = true;
}
