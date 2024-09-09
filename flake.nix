{
  description = "template for developing/testing nixos modules";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs, nixos-shell }:
    {
      nixosModules.example-module = import ./module.nix;
    };
}