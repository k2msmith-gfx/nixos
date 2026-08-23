{ pkgs, ... }:

{
  system.stateVersion = 5;

  nixpkgs.hostPlatform = "aarch64-darwin";

  nix.settings.experimental-features = "nix-command flakes";

  nixpkgs.config.allowUnfree = true;

  system.primaryUser = "kevinsmith";

  users.users.kevinsmith.home = "/Users/kevinsmith";

  # macOS system defaults
  system.defaults = {
    dock.autohide = true;
    finder.AppleShowAllExtensions = true;
    NSGlobalDomain.ApplePressAndHoldEnabled = false;
  };

  programs.zsh.enable = true;

  # LibreOffice isn't in nixpkgs for darwin (Linux-only meta.platforms), so we
  # install it as a Homebrew cask. Requires Homebrew itself to be installed:
  #   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # cleanup = "none" leaves any manually-installed brew packages untouched.
  homebrew = {
    enable = true;
    onActivation.cleanup = "none";
    casks = [ "libreoffice" ];
  };
}
