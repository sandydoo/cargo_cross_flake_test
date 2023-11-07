# {
#   inputs = {
#     nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
#     rust-overlay.url = "github:oxalica/rust-overlay";
#   };

#   outputs = {
#     self,
#     nixpkgs,
#     rust-overlay,
#   }: let
#     system = "x86_64-linux";
#     pkgs = import nixpkgs {
#       inherit system;
#       overlays = [rust-overlay.overlays.default];
#     };
#     toolchain = pkgs.rust-bin.fromRustupToolchainFile ./toolchain.toml;
#   in {
#     devShells.${system}.default = pkgs.mkShell {
#       packages = [
#         pkgs.docker
#         pkgs.rustup
#         pkgs.cargo-cross
#         toolchain
#       ];

#       shellHook = ''
#         export RUST_SRC_PATH="${toolchain}/lib/rustlib/src/rust/library"
#       '';
#     };
#   };
# }


{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devenv.flakeModule
      ];
      systems = nixpkgs.lib.systems.flakeExposed;

      perSystem = { config, self', inputs', pkgs, system, ... }: {
        devenv.shells.default = {
          packages = with pkgs; [ 
            rustup
            docker
            cargo-cross
          ];
          languages.rust.enable = true;
          languages.rust.channel = "nightly";
          languages.rust.components = [ "rustc" "cargo" "clippy" "rustfmt" "rust-analyzer" "rust-src" "rust-std" ];
          env.RUST_BACKTRACE = "1";
        };
      };
    };
}