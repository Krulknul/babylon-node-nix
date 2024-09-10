{
  description = "NixOS Flake example for babylon-node-nix usage";

  inputs =
  let
    version = "1.2.2+1";
  in
  {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    babylon-node-nix.url = "github:Krulknul/babylon-node-nix/${version}";
  };

  outputs =
    {
      self,
      nixpkgs,
      babylon-node-nix,
    }:
    {
      nixosConfigurations =
        let
          nixosSystem =
            system:
            nixpkgs.lib.nixosSystem {
              inherit system;
              modules = [
                ./configuration.nix
                babylon-node-nix.nixosModules.babylon_node
              ];
            };
        in
        {
          x86_64-linux = nixosSystem "x86_64-linux";
          x86_64-darwin = nixosSystem "x86_64-darwin";
          aarch64-darwin = nixosSystem "aarch64-darwin";
          aarch64-linux = nixosSystem "aarch64-linux";
        };
    };
}
