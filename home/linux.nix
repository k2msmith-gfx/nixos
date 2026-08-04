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

    # ray-janet: build+run inside the `janet` dev shell so JANET_HOME /
    # LIBCLANG_PATH are set for us. Ends in `--`, so trailing args flow to the
    # binary, e.g. `rayj --scene scripts/scene.janet --tcp`. The `cd` lands you
    # in the repo (needed for `.#janet`) and stays there after.
    rayj    = "cd ~/devel/ray && nix develop .#janet -c cargo run --features janet --bin ray-janet --";
    rayjr   = "cd ~/devel/ray && nix develop .#janet -c cargo run --release --features janet --bin ray-janet --";
    # Build (not run) the release ray-janet binary — e.g. to pre-build it so
    # `rays`/ray-studio starts instantly instead of building on first launch.
    rayjb   = "cd ~/devel/ray && nix develop .#janet -c cargo build --release --features janet --bin ray-janet";

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
