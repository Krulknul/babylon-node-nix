{
  description = "A NixOS module for the RadixDLT Babylon node software";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs }:
  let
      forAllSystems = function:
      nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ] (system: function nixpkgs.legacyPackages.${system});
  in
    rec {
        packages = forAllSystems (pkgs: {
            default = pkgs.callPackage ./babylon-node.nix {pkgs = pkgs;};
        });
        nixosModules.babylon_node = import ./babylon-service.nix { babylon_node = packages.${builtins.currentSystem}; };
    };
}