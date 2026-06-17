{
  description = "Solana development setup with Nix.";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/86681402a45f441099243f59945d1d546f2933eb";
    flake-parts.url = "github:hercules-ci/flake-parts/f7c1a2d347e4c52d5fb8d10cb4d94b5884e546fb";
    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";
    rust-overlay = {
      url = "github:oxalica/rust-overlay/d0e019d9543f0f1215a3d961fc4dca59aa29c638";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crane.url = "github:ipetkov/crane";
    nixpkgs-python.url = "github:cachix/nixpkgs-python";
  };
  outputs =
    inputs@{
      self,
      flake-parts,
      crane,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.flake-parts.flakeModules.easyOverlay
      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
        "x86_64-windows"
      ];
      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        let
          solana-source = pkgs.callPackage ./solana-source.nix { };
          solana-platform-tools = pkgs.callPackage ./solana-platform-tools.nix {
            inherit solana-source;
            python310 = inputs.nixpkgs-python.packages.${system}."3.10";
          };
          solana-rust = pkgs.callPackage ./solana-rust.nix {
            inherit solana-platform-tools;
          };
          solana-cli = pkgs.callPackage ./solana-cli.nix {
            inherit solana-platform-tools solana-source;
            crane = crane.mkLib pkgs;
          };
          anchor-cli = pkgs.callPackage ./anchor-cli.nix {
            inherit solana-platform-tools;
            crane = crane.mkLib pkgs;
          };
          anchor-test = pkgs.callPackage ./anchor-test.nix {
            inherit anchor-cli solana-cli solana-rust;
          };
        in
        {
          overlayAttrs = {
            inherit (config.packages)
              solana-source
              solana-platform-tools
              solana-rust
              solana-cli
              anchor-cli
              anchor-test
              ;
          };
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              inputs.rust-overlay.overlays.default
              self.overlays.default
            ];
          };

          devShells.default = pkgs.mkShell {
            packages = [
              anchor-cli
              solana-cli
              solana-rust
              pkgs.yarn
              pkgs.nodejs
              pkgs.nixfmt-rfc-style
            ];
          };

          packages = {
            inherit
              anchor-cli
              solana-cli
              solana-platform-tools
              solana-rust
              anchor-test
              ;
          };
        };
    };
}
