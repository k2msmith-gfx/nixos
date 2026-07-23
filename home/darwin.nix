{ pkgs, nixSystem, ... }:

{
  programs.bash.shellAliases = {
    nswitch = "sudo -H darwin-rebuild switch --flake ~/nixos#${nixSystem}";
    nbuild  = "darwin-rebuild build --flake ~/nixos#${nixSystem}";
    msync   = "cd ~/nixos && git add memory-devel/ && git commit -m 'memory: sync from macOS' && git push && cd -";
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
      dv      = "cd ~/Documents/devel/rust/ray";

      nswitch = "sudo -H darwin-rebuild switch --flake ~/nixos#${nixSystem}";
      nbuild  = "darwin-rebuild build --flake ~/nixos#${nixSystem}";
      msync   = "cd ~/nixos && git add memory-devel/ && git commit -m 'memory: sync from macOS' && git push && cd -";
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
