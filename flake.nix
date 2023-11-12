{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";
    rust-overlay.url = "github:oxalica/rust-overlay";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs@{ self,
    nixpkgs,
    rust-overlay,
    devenv,
    fenix,
    flake-utils,
    ...
  }: 
  flake-utils.lib.eachSystem ["x86_64-linux" "aarc64-linux" ] (system: let
    mkCargoCross = pkgs: pkgs.cargo-cross.overrideAttrs (drv: rec {
        src = pkgs.fetchFromGitHub {
          owner = "cross-rs";
          repo = "cross";
          rev = "44011c8854cb2eaac83b173cc323220ccdff18ea";
          hash = "sha256-yGYs0691CPFUX9Wg/gkm6PXCX0GnfaKDyL+BCbCUrfw=";
        };
        cargoDeps = drv.cargoDeps.overrideAttrs (pkgs.lib.const {
          inherit src;
          outputHash = "sha256-Egq2+VVl6ekReoEK2k0Esz7B/zycKQan+um+c3DhbbU=";
        });
      });
  in {
    devShells = {
      default = 
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [rust-overlay.overlays.default];
          };
	  cargo-cross = mkCargoCross pkgs;
          toolchain = pkgs.rust-bin.fromRustupToolchainFile ./toolchain.toml;
        in pkgs.mkShell {
        packages = [
          pkgs.docker
          pkgs.rustup
          cargo-cross
          toolchain
        ];
      };

      devenv =
        let 
	  pkgs = nixpkgs.legacyPackages.${system};
	  cargo-cross = mkCargoCross pkgs;
	  toolchain = 
            fenix.packages.${system}.fromToolchainFile {
              file = ./toolchain.toml;
	      sha256 = "sha256-0d/UxN6sekF+iQtebQl6jj/AQiT18Uag3CKbsCxc1E0=";
            };

          # (with fenix.packages.${system}; 
          #   combine [ latest.rustc latest.cargo latest.rust-src targets.x86_64-pc-windows-gnu.latest.rust-std ]);
	in devenv.lib.mkShell {
        inherit inputs pkgs;
        modules = [{
          packages = [ 
            pkgs.rustup
            pkgs.docker
            cargo-cross
	    toolchain
          ];
          languages.rust.enable = true;
          languages.rust.channel = "nightly";
          languages.rust.components = [];
          languages.rust.toolchain = pkgs.lib.mkForce toolchain;
          env.RUST_BACKTRACE = "1";
        }];
      };
    };
  });
}
