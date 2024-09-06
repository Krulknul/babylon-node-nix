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

  services.babylon_node.enable = true;
  services.babylon_node.config = {
    #network = {
    #  id = 1;
    #  p2p.seed_nodes = [
    #    "radix://node_rdx1qf2x63qx4jdaxj83kkw2yytehvvmu6r2xll5gcp6c9rancmrfsgfw0vnc65@babylon-mainnet-eu-west-1-node0.radixdlt.com"
    #    "radix://node_rdx1qgxn3eeldj33kd98ha6wkjgk4k77z6xm0dv7mwnrkefknjcqsvhuu4gc609@babylon-mainnet-ap-southeast-2-node0.radixdlt.com"
    #    "radix://node_rdx1qwrrnhzfu99fg3yqgk3ut9vev2pdssv7hxhff80msjmmcj968487uugc0t2@babylon-mainnet-ap-south-1-node0.radixdlt.com"
    #    "radix://node_rdx1q0gnmwv0fmcp7ecq0znff7yzrt7ggwrp47sa9pssgyvrnl75tvxmvj78u7t@babylon-mainnet-us-east-1-node0.radixdlt.com"
    #  ];
    #};
    db.location = "/home/babylon_node/db";
    node.key = {
      path = "/home/babylon_node/keystore.ks";
      create_if_missing = true;
    };
  };
}
```