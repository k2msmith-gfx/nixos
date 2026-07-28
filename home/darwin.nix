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
      kj      = "lsof -ti :4007 | xargs kill -9";

      # ray-janet: build+run inside the `janet` dev shell so JANET_HOME /
      # LIBCLANG_PATH are set for us. Ends in `--`, so trailing args flow to the
      # binary, e.g. `rayj --scene scripts/scene.janet --tcp`. The `cd` lands you
      # in the repo (needed for `.#janet`) and stays there after.
      rayj    = "cd ~/Documents/devel/rust/ray && nix develop .#janet -c cargo run --features janet --bin ray-janet --";
      rayjr   = "cd ~/Documents/devel/rust/ray && nix develop .#janet -c cargo run --release --features janet --bin ray-janet --";

      # Fullscreen Emacs live workbench: scene.janet | render image / *janet*.
      # Builds the release binary if missing, then Emacs runs it and connects.
      rays    = "~/Documents/devel/rust/ray/scripts/ray-studio";
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
