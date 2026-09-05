{ pkgs, nixSystem, ... }:

{
  programs.bash.shellAliases = {
    nswitch = "sudo -H darwin-rebuild switch --flake ~/nixos#${nixSystem}";
    nbuild  = "darwin-rebuild build --flake ~/nixos#${nixSystem}";
    msync   = "git -C ~/nixos add memory-devel/ && (git -C ~/nixos diff --cached --quiet || git -C ~/nixos commit -m 'memory: sync from macOS') && git -C ~/nixos pull --rebase && git -C ~/nixos push";
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
      dv      = "cd ~/devel/ray";

      nswitch = "sudo -H darwin-rebuild switch --flake ~/nixos#${nixSystem}";
      nbuild  = "darwin-rebuild build --flake ~/nixos#${nixSystem}";
      msync   = "git -C ~/nixos add memory-devel/ && (git -C ~/nixos diff --cached --quiet || git -C ~/nixos commit -m 'memory: sync from macOS') && git -C ~/nixos pull --rebase && git -C ~/nixos push";
      kj      = "lsof -ti :4007 | xargs kill -9";

      # ray-janet: build+run inside the `janet` dev shell so JANET_HOME /
      # LIBCLANG_PATH are set for us. Ends in `--`, so trailing args flow to the
      # binary, e.g. `rayj --scene scripts/scene.janet --tcp`. The `cd` lands you
      # in the repo (needed for `.#janet`) and stays there after.
      rayj    = "cd ~/devel/ray && nix develop .#janet -c cargo run --features janet --bin ray-janet --";
      rayjr   = "cd ~/devel/ray && nix develop .#janet -c cargo run --release --features janet --bin ray-janet --";
      # Build (not run) the release ray-janet binary — e.g. to pre-build it so
      # `rays`/ray-studio starts instantly instead of building on first launch.
      rayjb   = "cd ~/devel/ray && nix develop .#janet -c cargo build --release --features janet --bin ray-janet";

      # modeler: the Emacs-shaped 3D editor (sibling crate). Its whole UI —
      # keymaps, mouse dispatch, REPL, AI — lives behind `--features janet`, so
      # like ray-janet it builds+runs inside the `janet` dev shell. winit owns
      # the window (no terminal), so this is a plain run, not a `rays`-style
      # script. Ends in `--`, so a model path flows to the binary, e.g.
      # `raym assets/foo.glb`.
      raym    = "cd ~/devel/ray && nix develop .#janet -c cargo run --features janet -p modeler --";
      raymr   = "cd ~/devel/ray && nix develop .#janet -c cargo run --release --features janet -p modeler --";
      # Build (not run) the release modeler binary.
      raymb   = "cd ~/devel/ray && nix develop .#janet -c cargo build --release --features janet -p modeler";

      # ray-view: WezTerm/kitty-native terminal render window (kitty graphics
      # protocol under WezTerm/kitty/Ghostty, sixel/iTerm2/half-block elsewhere).
      # Pure Rust and independent of `janet` — no nix shell needed. Release for
      # smooth in-place repaint. Ends in `--`, so trailing args flow to the
      # binary, e.g. `rayv 4010` or `rayv host:4008`. Pair with a `--tcp`
      # ray-janet, whose image-push server it dials (default port 4008).
      rayv    = "cd ~/devel/ray && cargo run --release --features view --bin ray-view --";
      # Build (not run) the release ray-view binary — e.g. to pre-build it so
      # `rayv` starts instantly instead of compiling on first launch.
      rayvb   = "cd ~/devel/ray && cargo build --release --features view --bin ray-view";

      # Fullscreen Emacs live workbench: scene.janet | render image / *janet*.
      # Builds the release binary if missing, then Emacs runs it and connects.
      rays    = "~/devel/ray/scripts/ray-studio";
      rayzs   = "~/devel/ray-zig/scripts/ray-zig-studio";

      # ray-zig: Zig 0.16 port. The Janet lib path is baked into the binary as
      # an rpath at build time (pkg-config --libs-only-L janet), so no
      # DYLD_LIBRARY_PATH is needed. Ends in `--` so trailing args flow to
      # the binary, e.g. `rayz --scene scripts/scene.janet`.
      rayz    = "cd ~/devel/ray-zig && zig build run --";
      rayzr   = "cd ~/devel/ray-zig && zig build -Doptimize=ReleaseFast run --";
      rayzb   = "cd ~/devel/ray-zig && zig build -Doptimize=ReleaseFast";
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
