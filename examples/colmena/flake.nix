{
  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/nixos-24.05;
    babylon-node-nix.url = "git+https://github.com/Krulknul/babylon-node-nix?tag=1.2.3+1";
  };
  outputs =
    { nixpkgs, babylon-node-nix, ... }:
    {
      colmena = {
        meta = {
          nixpkgs = import nixpkgs {
              system = "x86_64-linux";
            };
          nodeNixpkgs = {
            host-b = import nixpkgs {
              system = "x86_64-linux";
            };
          };
        };
        host-b =
          {
            pkgs,
            config,
            modulesPath,
            ...
          }:
          {
            deployment = {
              buildOnTarget = true;
              keys."keystore" = {
                keyFile = ./keystore.ks;
                destDir = "/home/babylon-node";
                user = "boing-";
              };
            };
            imports = [
              "${modulesPath}/virtualisation/amazon-image.nix"
              babylon-node-nix.nixosModules.babylon-node
            ];
            environment.systemPackages = with pkgs; [
              vim
              htop
              git
              magic-wormhole
            ];

            networking.firewall = {
              enable = true;
              allowPing = true; # Allows ICMP echo requests
              allowedTCPPorts = [
                22
                30000
              ]; # Allow the SSH port and the default Babylon node gossip port
            };
            services.openssh.ports = [
              22
            ];

            # Create a "babylon-node" user to run the process as
            users.users.babylon-node = {
              isNormalUser = true; # Give the user a home directory to allow node to store some files there
              group = "babylon-node"; # Add the user to the group
              home = "/home/babylon-node";
            };

            # Add a group corresponding to the user
            users.groups.babylon-node = { };

            # Enable the babylon-node service
            services.babylon-node.enable = true;

            # Configure the service.
            services.babylon-node.config = {
              db.location = "/home/babylon-node/db";
              node.key = {
                path = "/home/babylon-node/keystore.ks";
                create_if_missing = true; # Create a new key if the key file is missing
              };
            };

            # system.stateVersion is an important variable that ensures compatibility between versions of some stateful services.
            # Read more here: https://search.nixos.org/options?show=system.stateVersion&query=system.StateVersion
            system.stateVersion = "24.11";
          };
      };
    };
}
