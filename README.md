# babylon-node-nix

The new easiest way to spin up a node on the Radix Babylon network.

```nix
{
  imports = [
    /home/krulk/nix/babylon-service.nix
    # Your other imports...
  ];

  # Create a "babylon_node" user to run the process as
  users.users.babylon_node = {
    # Give the user a home directory
    isNormalUser = true;
    group = "babylon_node";
    home = "/home/babylon_node";
  };

  # Add a group corresponding to the user
  users.groups.babylon_node = { };

  # Enable the babylon_node service
  services.babylon_node.enable = true;

  # Configure the service
  services.babylon_node.config = {
    db.location = "/home/babylon_node/db";
    node.key = {
      path = "/home/babylon_node/keystore.ks";
      create_if_missing = true;
    };
  };
}
```