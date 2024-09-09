{
  description = "template for developing/testing nixos modules";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs }:
    {
      nixosModules.babylon_node = import ./babylon-service.nix;
    };
}