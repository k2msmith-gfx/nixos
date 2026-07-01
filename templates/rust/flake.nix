{
  description = "Rust development shell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          # System libraries commonly needed by Rust crates.
          # Add/remove as your project requires.
          buildInputs = with pkgs; [
            # Rust toolchain — managed by rustup, not nix, so we just
            # need rustup itself here. Run `rustup show` after entering
            # the shell to confirm your toolchain is active.
            rustup

            # Common native deps
            pkg-config
            openssl

            # Useful CLI tools
            rust-analyzer   # LSP (standalone Nix build, always available)
            cargo-watch     # cargo watch -x check
            cargo-expand    # expand macros
            cargo-nextest   # faster test runner
          ];

          # Tell pkg-config where to find libraries.
          PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";

          # Ensure rust-analyzer can find the stdlib source.
          RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";

          shellHook = ''
            echo "Rust dev shell active"
            echo "  rustup: $(rustup show active-toolchain 2>/dev/null || echo 'no toolchain set')"
            echo "  rust-analyzer: $(rust-analyzer --version 2>/dev/null)"
          '';
        };
      });
}
