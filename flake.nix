{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";
    rust-overlay.url = "github:oxalica/rust-overlay";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{
    self,
    nixpkgs,
    rust-overlay,
    devenv,
    fenix,
    ...
  }: let
    system = "aarch64-linux";
    pkgs = import nixpkgs {
      inherit system;
      overlays = [rust-overlay.overlays.default];
    };
    toolchain = pkgs.rust-bin.fromRustupToolchainFile ./toolchain.toml;

    cargo-cross = pkgs.cargo-cross.overrideAttrs (drv: rec {
        # src = pkgs.fetchFromGitHub {
        #   owner = "cross-rs";
        #   repo = "cross";
        #   rev = "44011c8854cb2eaac83b173cc323220ccdff18ea";
        #   hash = "sha256-yGYs0691CPFUX9Wg/gkm6PXCX0GnfaKDyL+BCbCUrfw=";
        # };
        # cargoDeps = drv.cargoDeps.overrideAttrs (pkgs.lib.const {
        #   inherit src;
        #   outputHash = "sha256-Egq2+VVl6ekReoEK2k0Esz7B/zycKQan+um+c3DhbbU=";
        # });
      });
  in {
    devShells.${system} = {
      default = pkgs.mkShell {
        packages = [
          pkgs.docker
          pkgs.rustup
          cargo-cross
          toolchain
        ];

        shellHook = ''
          export RUST_SRC_PATH="${toolchain}/lib/rustlib/src/rust/library"
        '';
      };

      devenv = devenv.lib.mkShell {
        inherit inputs pkgs;
        modules = [{
          packages = with pkgs; [ 
            rustup
            docker
            cargo-cross
          ];
          languages.rust.enable = true;
          languages.rust.channel = "nightly";
          # languages.rust.components = [ "rustc" "cargo" "clippy" "rustfmt" "rust-analyzer" "rust-src" ];
          languages.rust.components = [];
          # languages.rust.toolchain = pkgs.lib.mkForce (with fenix.packages.${system}; 
          #   combine [ latest.rustc latest.cargo latest.rust-src targets.x86_64-pc-windows-gnu.latest.rust-std ]);
          languages.rust.toolchain = fenix.packages.${system}.fromToolchainFile {
            file = ./toolchain.toml;
            sha256 = "sha256-SS4GpScL/PIMXVvrIRJTHQyTEvX5cAXgeXz0zu7MbvU=";
          };
          env.RUST_BACKTRACE = "1";
        }];
      };
    };
  };
}
