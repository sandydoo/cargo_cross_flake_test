let
  rust-overlay = builtins.fetchTarball "https://github.com/oxalica/rust-overlay/archive/master.tar.gz";
  pkgs = import <nixpkgs> {
    overlays = [(import rust-overlay)];
  };
  toolchain = pkgs.rust-bin.fromRustupToolchainFile ./toolchain.toml;
in
  pkgs.mkShell {
    packages = [
      pkgs.docker
      pkgs.rustup
      pkgs.cargo-cross
      toolchain
    ];

    shellHook = ''
      export RUST_SRC_PATH="${toolchain}/lib/rustlib/src/rust/library"
    '';
  }
