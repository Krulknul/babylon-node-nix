{
  description = "A NixOS module for the RadixDLT Babylon node software";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };
  outputs =
    { self, nixpkgs }:
    let
      forAllSystems =
        function:
        nixpkgs.lib.genAttrs [
          "x86_64-linux"
          "x86_64-darwin"
          "aarch64-linux"
          "aarch64-darwin"
        ] (system: function nixpkgs.legacyPackages.${system});
      allPackages = forAllSystems (pkgs: {
        default = pkgs.callPackage ./babylon-node.nix { };
      });
    in
    {
      packages = allPackages;
      nixosModules.babylon-node = import ./babylon-service.nix {
        inherit nixpkgs;
      };
    };
}
