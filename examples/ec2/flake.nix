{
  description = "NixOS Flake example for babylon-node-nix usage";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    babylon-node-nix.url = "git+https://github.com/Krulknul/babylon-node-nix?tag=1.2.3+1";
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
                babylon-node-nix.nixosModules.babylon-node
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
