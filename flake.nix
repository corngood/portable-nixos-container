{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    nixpkgs-compat = {
      url = "github:nixos/nixpkgs/nixos-19.09";
      flake = false;
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixpkgs-compat, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: {
      packages.container-system = import ./container-system.nix {
        pkgs = nixpkgs.legacyPackages.${system};
        lib = nixpkgs.lib;
        nixos-container = (import nixpkgs-compat {
          localSystem.system = system;
        }).nixos-container;
      };
    });

}
