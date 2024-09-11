{
  config,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
  ];

  environment.systemPackages = with pkgs; [
    vim
    htop
    git
  ];

  networking.hostName = "babylon-node";

  # We need to enable these experimental features
  # for some features of NixOS - like flakes - to work
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
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
}
