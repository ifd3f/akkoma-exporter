{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let poetryOverlay = (final: prev: { });
    in {
      overlays.default = final: prev: {
        inherit (self.packages.${prev.system}) akkoma-exporter;
      };

      nixosModules.default = ./nixos-module.nix;
    }

    // flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        packages = {
          default = self.packages.${system}.akkoma-exporter;

          akkoma-exporter = with pkgs;
            poetry2nix.mkPoetryApplication {
              projectDir = self;
              overrides =
                poetry2nix.defaultPoetryOverrides.extend poetryOverlay;
            };
        };

        devShells.default = with pkgs;
          mkShellNoCC {
            packages = [
              (poetry2nix.mkPoetryEnv {
                projectDir = self;
                overrides =
                  poetry2nix.defaultPoetryOverrides.extend poetryOverlay;
              })
              poetry
            ];
          };
      });
}
