{ pkgs, nixSystem, ... }:

{
  programs.bash.shellAliases = {
    nswitch = "sudo nixos-rebuild switch --flake ~/nixos#${nixSystem}";
    nboot   = "sudo nixos-rebuild boot --flake ~/nixos#${nixSystem}";
    ntest   = "sudo nixos-rebuild test --flake ~/nixos#${nixSystem}";
    nbuild  = "sudo nixos-rebuild build --flake ~/nixos#${nixSystem}";
    ncheck  = "sudo nixos-rebuild dry-build --flake ~/nixos#${nixSystem}";
    # Commit-if-changed, then pull --rebase, then push: both directions sync,
    # and a collision stops at the rebase instead of committing conflict markers.
    msync   = "git -C ~/nixos add memory-devel/ && (git -C ~/nixos diff --cached --quiet || git -C ~/nixos commit -m 'memory: sync from Linux') && git -C ~/nixos pull --rebase && git -C ~/nixos push";
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
    # like ray-janet it builds+runs inside the `janet` dev shell. winit owns the
    # window (no terminal), so this is a plain run, not a `rays`-style script.
    # Defaults to loading the SciFiHelmet sample model (we cd into the repo
    # first, so the relative path resolves).
    raym    = "cd ~/devel/ray && nix develop .#janet -c cargo run --release --features janet -p modeler -- assets/models/SciFiHelmet.gltf";
    # Build (not run) the release modeler binary.
    raymb   = "cd ~/devel/ray && nix develop .#janet -c cargo build --release --features janet -p modeler";

    # ray-view: terminal render window (kitty graphics protocol under
    # WezTerm/kitty/Ghostty, sixel/iTerm2/half-block elsewhere). Pure Rust and
    # independent of `janet` — no nix shell needed. Release for smooth in-place
    # repaint. Ends in `--`, so trailing args flow to the binary, e.g.
    # `rayv 4010` or `rayv host:4008`. Pair with a `--tcp` ray-janet, whose
    # image-push server it dials (default port 4008).
    rayv    = "cd ~/devel/ray && cargo run --release --features view --bin ray-view --";
    # Build (not run) the release ray-view binary — e.g. to pre-build it so
    # `rayv` starts instantly instead of compiling on first launch.
    rayvb   = "cd ~/devel/ray && cargo build --release --features view --bin ray-view";

    # ray-zig: Zig port. The Janet lib path is baked into the binary as an
    # rpath at build time (pkg-config --libs-only-L janet), so no
    # LD_LIBRARY_PATH is needed. Ends in `--` so trailing args flow to
    # the binary, e.g. `rayz --scene scripts/scene.janet`.
    rayz    = "cd ~/devel/ray-zig && nix develop -c zig build run --";
    rayzr   = "cd ~/devel/ray-zig && nix develop -c zig build -Doptimize=ReleaseFast run --";
    rayzb   = "cd ~/devel/ray-zig && nix develop -c zig build -Doptimize=ReleaseFast";

    # Fullscreen Emacs live workbench: scene.janet | render image / *janet*.
    # Builds the release binary if missing, then Emacs runs it and connects.
    rays    = "~/devel/ray/scripts/ray-studio";
    rayzs   = "~/devel/ray-zig/scripts/ray-zig-studio";
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

    # Office / presentations (Macs use native PowerPoint instead)
    libreoffice-fresh
    pdfpc

    # COSMIC system monitor + panel sysinfo applet
    cosmic-monitor
    cosmic-ext-applet-sysinfo
  ];

  gtk = {
    enable = true;
    cursorTheme = {
      name = "Adwaita";
      size = 24;
    };
    # Prefer the dark Adwaita variant so GTK apps (Thunar) render dark.
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
  };

  # libadwaita / GTK4 apps read this instead of the flag above.
  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

  # Run a user ssh-agent (systemd user service, lives for the login session).
  services.ssh-agent.enable = true;

  # SSH client config (Linux-only; the Macs manage their own ~/.ssh/config).
  # AddKeysToAgent loads the key into the agent on first use, prompting for the
  # passphrase once per boot so later git pushes over SSH don't re-prompt.
  programs.ssh = {
    enable = true;
    # Home Manager replaced `matchBlocks` (camelCase opts) with `settings` (a
    # DAG keyed by host pattern, using literal ssh_config directive names).
    # `enableDefaultConfig = false` opts out of HM's injected `Host *` legacy
    # defaults — they only mirror OpenSSH's own built-in defaults (ForwardAgent
    # no, Compression no, ControlMaster no, UserKnownHostsFile ~/.ssh/known_hosts
    # …), so dropping them changes no effective behaviour and silences the
    # deprecation warning. We keep just the two directives we actually set.
    enableDefaultConfig = false;
    settings."*" = {
      AddKeysToAgent = "yes";
      IdentityFile   = "~/.ssh/id_ed25519";
    };
  };

  xdg.configFile."niri/config.kdl".source = ../niri/config.kdl;
}
