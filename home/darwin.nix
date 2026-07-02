{ pkgs, ... }:

{
  programs.bash.shellAliases = {
    nswitch = "sudo -H darwin-rebuild switch --flake ~/nixos#kevmac";
    nbuild  = "darwin-rebuild build --flake ~/nixos#kevmac";
  };

  programs.zsh = {
    enable = true;
    shellAliases = {
      ll      = "ls -lah";
      la      = "ls -A";
      ".."    = "cd ..";
      "..."   = "cd ../..";
      grep    = "grep --color=auto";
      rg      = "rg --smart-case";
      g       = "git";

      nswitch = "sudo -H darwin-rebuild switch --flake ~/nixos#kevmac";
      nbuild  = "darwin-rebuild build --flake ~/nixos#kevmac";
    };
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
    initContent = ''
      export PATH="$HOME/.config/emacs/bin:$PATH"

      HISTSIZE=10000
      SAVEHIST=20000
      setopt HIST_IGNORE_BOTH
      setopt APPEND_HISTORY
      setopt CHECK_JOBS

      fastfetch
    '';
  };

  home.packages = with pkgs; [
    # Use plain emacs on macOS (emacs-pgtk is Linux/Wayland-only)
    emacs
  ];
}
