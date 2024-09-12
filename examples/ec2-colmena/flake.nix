{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    babylon-node-nix.url = "github:Krulknul/babylon-node-nix/add-example-for-usage-with-the-colmena-deployment-tool";
  };
  outputs =
    { nixpkgs, babylon-node-nix, ... }:
    {
      colmena = {
        meta = {
          nixpkgs = import nixpkgs {
            system = "x86_64-linux";
          };
        };
        # Here's one host, but you can add more hosts with different names.
        # For the SSH credentials, it finds a host with the same name in the SSH config file in this directory.
        host-b =
          {
            # Colmena-specific configuration related to the deployment
            deployment = {
              buildOnTarget = true;
              keys."keystore.ks" = {
                keyFile = ./keystore.ks;
                destDir = "/home/babylon-node";
                user = "babylon-node";
                group = "babylon-node";
              };
            };
            imports = [
              babylon-node-nix.nixosModules.babylon-node
              # using the same system configuration as the EC2 example
              ../ec2/configuration.nix
            ];
          };
      };
    };
}
