# babylon-node-nix

The new easiest way to spin up a node on [RadixDLT](https://www.radixdlt.com)'s Babylon network.

* Bare metal deployment
* Easy configuration
* Fully declarative
* No implicit dependencies

```nix
### configuration.nix ###
{ config, pkgs, ... }:

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

  # Configure the service.
  services.babylon_node.config = {
    db.location = "/home/babylon_node/db";
    node.key = {
      path = "/home/babylon_node/keystore.ks";
      create_if_missing = true;
    };
  };
  # Configuration uses the same option paths
  # as a Babylon node config file.
  # See options.nix for all options,

  # Any other NixOS configurations...
}
```

All you need is an installation of NixOS and the above snippet to launch a minimal Babylon node natively.


## What is Nix?
[Nix in 100 seconds - Fireship](https://youtu.be/FJVFXsNzYZQ?si=gsei2r4lnJhHIjqa)

In a nutshell, Nix is a collection of tools that are used to achieve reproducible package builds, environments, systems, deployments - or pretty much anything else.

### Nix Package manager
The Nix package manager uses the functional Nix programming language to achieve reproducible package builds. It achieves full reproducibility by explicitly declaring a package's dependencies and disallowing implicit dependencies.

### NixOS
NixOS is a Linux distribution that uses the Nix language for declaratively building an entire Linux system. Packages, firewall settings, users, directories and services can all be declared using the Nix language. This allows for completely reproducible deployments. Something promised by tools like Ansible, but actually delivered by NixOS.

![Ansible? Nein danke](https://i.redd.it/pgqf5k0qvuu81.jpg)

## Why Nix for your Babylon node?

While it's possible to run a babylon node in a docker container, some node runners prefer the performance of running without docker. Setting this up often comes down to having to manually set up a system by ssh-ing in and imperatively running commands. If we instead use NixOS, we can add the `babylon_node` service configuration to the `configuration.nix`, run `sudo nixos-rebuild switch` and it will simply start working. In addition to easily being able to start and configure the Babylon node service, we can also configure all other things about our node deployment in `configuration.nix`, making it very simple to deploy our node on another machine with exactly the same firewall settings / executables / services / packages etc.

Even if you're not interested in using NixOS to run your node, this project can still come in handy for you. It packages the Babylon node binaries in a reproducible manner, and with runtime dependencies baked in.
Usually, to run the node software on Ubuntu or another linux distribution, you will have to roughly go through these steps (excluding most configuration):

* Download the executable manually from GitHub
* Download the right version of the dynamic library from GitHub for your architecture and OS.
* Unzip the binaries and libraries.
* Place the contents in a dedicated directory
* Install the right version of Java
* Prepare an environment variable to make sure the dynamic library is used when you run
* Add some additional Java options that are needed to run the node software
* Run the executable

However, with the nix package from this repository:
* Install the Nix package manager
* `nix-build babylon-node.nix`, which produces the `result` directory as build output.
* `./result/bin/babylon_node`

No need to manually install Java - it's managed by Nix, and if you use Nix [flakes](https://zero-to-nix.com/concepts/flakes), the versions are pinned to make this package completely reproducible.

Note that the above doesn't provide a working node setup just yet. You still have to configure the node which can be done by passing in the path to a configuration file using the `-config` command line option. On NixOS, this is all handled in `configuration.nix`

## Important notes
This is a binary package - the build doesn't include compilation of the node software. Because the Babylon node software uses gradle as a build system, it is a bit less straightforward to build the project using Nix. It can be done with a tool like [gradle2nix](https://github.com/tadfisher/gradle2nix), and this would be nice to add in the future.

Currently however, this doesn't make the package definition any less reproducible. Checksums are calculated at build time to make sure the downloaded binaries have not changed.

Something else to note is that to achieve full reproducibility, it is recommended to use Nix Flakes, which are technically an experimental feature of Nix but are widely used at this point. Flakes pin the versions of the inputs to a build, meaning the package won't break on new versions of [nixpkgs](https://github.com/NixOS/nixpkgs), nix's package repository. Flakes can be used with NixOS to pin the version of nixpkgs used in your system.

## Getting started

### With NixOS

If you already have an installation of NixOS, for example on a server or VPS, this is the easiest way to get started.

Clone this repository

```bash
git clone git@github.com:NixOS/nixpkgs.git
```

Import the `babylon-service.nix` from the repository in your `/etc/nixos/configuration.nix` by adding the following top-level attribute:
```nix
imports = [
    /path/to/repository/babylon-service.nix
    # Any other imports you may already have...
];
```

Add some minimal configurations for the `babylon_node` service which has just been imported.

```nix
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

# Configure the service.
services.babylon_node.config = {
  db.location = "/home/babylon_node/db";
  node.key = {
    path = "/home/babylon_node/keystore.ks";
    # Just create a new key for now
    create_if_missing = true;
  };
};
```


Your `configuration.nix` should now look something like this:

```nix
### configuration.nix ###
{ config, pkgs, ... }:

{
  imports = [
    /path/to/repository/babylon-service.nix
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

  # Configure the service.
  services.babylon_node.config = {
    db.location = "/home/babylon_node/db";
    node.key = {
      path = "/home/babylon_node/keystore.ks";
      create_if_missing = true;
    };
  };

  # Any other NixOS configurations...
}
```

Now run `sudo nixos-rebuild switch`. The system will rebuild the configuration, and after a few seconds it should be finished and the Babylon node service should start running.

Just `sudo journalctl -fu babylon_node` to confirm that it's running.

You now have a minimal node installation running on your machine. To configure the node further, the service exposes a number of options that you can declaratively set. See `options.nix` for all currently available options. Most of these options are a wrapper around the regular Babylon node configuration files. In fact, such a file is generated by Nix based on our configuration in `configuration.nix` and is written to `/etc/radixdlt/babylon_node.config` when you rebuild the system.
Some required configurations however, are not possible to configure using that config file. This includes things like the user that is used by the systemd service, and the environment variable that contains the keystore password. See the `run_with` suboption in `options.nix` for these configurations.

#### More complex example
```nix
### configuration.nix ###
{ config, pkgs, ... }:

{
  imports = [
    path/to/repository/babylon-service.nix
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

  # Configure the service.
  services.babylon_node.config = {
    network = {
      # Use ID of 1 for Mainnet
      id = 1;
      # Set the IP of the host to avoid having to ask another service
      host_ip = "your.ip.goes.here";
      p2p = {
        # Change the gossip ports here
        listen_port = 30000;
        broadcast_port = 30000;
        # Add or remove some seed nodes
        seed_nodes = [
          "radix://node_rdx1qf2x63qx4jdaxj83kkw2yytehvvmu6r2xll5gcp6c9rancmrfsgfw0vnc65@babylon-mainnet-eu-west-1-node0.radixdlt.com"
          "radix://node_rdx1qgxn3eeldj33kd98ha6wkjgk4k77z6xm0dv7mwnrkefknjcqsvhuu4gc609@babylon-mainnet-ap-southeast-2-node0.radixdlt.com"
          "radix://node_rdx1qwrrnhzfu99fg3yqgk3ut9vev2pdssv7hxhff80msjmmcj968487uugc0t2@babylon-mainnet-ap-south-1-node0.radixdlt.com"
          "radix://node_rdx1q0gnmwv0fmcp7ecq0znff7yzrt7ggwrp47sa9pssgyvrnl75tvxmvj78u7t@babylon-mainnet-us-east-1-node0.radixdlt.com"
        ];
      };
    };
    db = {
      location = "/home/babylon_node/db";
      # We can turn off the transaction execution index
      local_transaction_execution_index.enable = false;
      # But leave the account change index enabled
      account_change_index.enable = true;
    };
    api = {
      # Why not bind the core api to port 3434
      core.port = 3434
      # Or expose the system API to the network
      system.bind_address = "0.0.0.0"
    };
    node.key = {
      path = "/home/babylon_node/keystore.ks";
      create_if_missing = false;
    };
    run_with = {
      # Explicitly set the user for the service
      user = "babylon_node";
      # And the group
      group = "babylon_node";
      # Override java options, which allows you to set things like memory allocation
      java_option_overrides = "-Xms12g -Xmx12g"
      # A file which contains environment variables to expose to the service.
      # One particularly important one if you're using a keystore with a password is RADIX_NODE_KEYSTORE_PASSWORD
      environment_file = "/directory/with/secrets/environment"
      # The directory where log files are written
      working_directory = "/home/babylon_node";
    };
  };

  # Any other NixOS configurations, like firewalls or services...
}
```