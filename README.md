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
  # Create a "babylon-node" user to run the process as
  users.users.babylon-node = {
    # Give the user a home directory
    isNormalUser = true;
    group = "babylon-node";
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

While it's possible to run a babylon node in a docker container, some node runners prefer the performance of running without docker. Setting this up often comes down to having to manually set up a system by ssh-ing in and imperatively running commands. If we instead use NixOS, we can add the `babylon-node` service configuration to the `configuration.nix`, run `sudo nixos-rebuild switch` and it will simply start working. In addition to easily being able to start and configure the Babylon node service, we can also configure all other things about our node deployment in `configuration.nix`, making it very simple to deploy our node on another machine with exactly the same firewall settings / executables / services / packages etc.

Even if you're not interested in using NixOS to run your node, this project can still come in handy for you. It packages the Babylon node binaries in a reproducible manner, and with runtime dependencies baked in.
Usually, to run the node software on Ubuntu or another linux distribution, you will have to roughly go through these steps (excluding most configuration):

* Download the executable manually from GitHub
* Download the right version of the dynamic library from GitHub for your architecture and OS.
* Unzip the binaries and libraries.
* Place the contents in a dedicated directory
* Install the right version of Java
* Prepare an environment variable to make sure the dynamic library is used when you run
* Hope that your system has the right version of glibc
* Add some additional Java options that are needed to run the node software
* Run the executable

However, with the nix package from this repository:
* Install the Nix package manager
* `nix-build babylon-node.nix`, which produces the `result` directory as build output.
* `./result/bin/babylon-node`

No need to manually install Java - it's managed by Nix. It should also work across Linux distributions because even glibc is an explicit dependency to this build. And if you use Nix [flakes](https://zero-to-nix.com/concepts/flakes), the versions are pinned to make this package completely reproducible.

Note that the above doesn't provide a working node setup just yet. You still have to configure the node which can be done by passing in the path to a configuration file using the `-config` command line option. On NixOS, this is all handled in `configuration.nix`

## Important notes
This is a binary package - the build doesn't include compilation of the node software. Because the Babylon node software uses gradle as a build system, it is a bit less straightforward to build the project using Nix. It can be done with a tool like [gradle2nix](https://github.com/tadfisher/gradle2nix), and this would be nice to add in the future.

Currently however, this doesn't make the package definition any less reproducible. Checksums are calculated at build time to make sure the downloaded binaries have not changed.

Something else to note is that to achieve full reproducibility, it is recommended to use Nix Flakes, which are technically an experimental feature of Nix but are widely used at this point. Flakes pin the versions of the inputs to a build, meaning the package won't break on new versions of [nixpkgs](https://github.com/NixOS/nixpkgs), nix's package repository. Flakes can be used with NixOS to pin the version of nixpkgs used in your system.

## Getting started

### With NixOS on AWS EC2

Official AMIs are published weekly for NixOS, which we can use to spin up an EC2 instance with NixOS easily.

Just create an instance with one of the AMIs [here](https://nixos.github.io/amis/). To follow along precisely, use the same AMI as I did: `ami-02ef0f744ceebd11a`

SSH into the server and copy the `flake.nix` and `configuration.nix` files from the `example` directory in this repository to `/etc/nixos/` on your NixOS system.

The `configuration.nix` imports a file:
```nix
...
imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
];
...
```
This points to a file in nixpkgs, which includes some minimal configs that are needed for the system to run on EC2. Usually when we run NixOS, a `hardware-configuration.nix` would be generated, but on EC2 it is handled for us in the AMI here.
See the file [here](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/virtualisation/amazon-image.nix).


Please read and understand the `configuration.nix` to see all the configurations that we set in this basic example.

Now run `nixos-rebuild switch --flake /etc/nixos#x86_64-linux`. (replacing `x86_64-linux` with your system) The system will rebuild the configuration, and after a few seconds it should be finished and the Babylon node service should start running.

Just `journalctl -fu babylon-node` to confirm that it's running.

Note: You may need to adjust the security group on AWS to allow port 30000, because I believe it blocks all but 22 by default.

You now have a minimal node installation running on your machine. To configure the node further, the babylon-node service exposes a number of options that you can declaratively set. See `options.nix` for all currently available options. Most of these options are a wrapper around the regular Babylon node configuration files. In fact, such a file is generated by Nix based on our configuration in `configuration.nix` and is written to `/etc/radixdlt/babylon-node.config` when you rebuild the system.
Some required configurations however, are not possible to configure using that config file. This includes things like the user that is used by the systemd service, and the environment variable that contains the keystore password. See the `run_with` suboption in `options.nix` for these configurations.

#### Advanced configurations
```nix
### configuration.nix ###
{ config, pkgs, ... }:

{
  imports = [
    # On other NixOS systems like on a regular install you'd
    # use an automatically generated hardware config.
    ./hardware-configuration.nix
    # Your other imports...
  ];

  # Create a "babylon-node" user to run the process as
  users.users.babylon-node = {
    # Give the user a home directory
    isNormalUser = true;
    group = "babylon-node";
    home = "/home/babylon-node";
  };

  # Add a group corresponding to the user
  users.groups.babylon-node = { };

  # Enable the babylon-node service
  services.babylon-node.enable = true;

  # Configure the service.
  services.babylon-node.config = {
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
      location = "/home/babylon-node/db";
      # We can turn off the transaction execution index
      local_transaction_execution_index.enable = false;
      # But leave the account change index enabled
      account_change_index.enable = true;
    };
    api = {
      # Why not bind the core api to port 3434
      core.port = 3434;
      # Or expose the system API to the network
      system.bind_address = "0.0.0.0"
    };
    node.key = {
      path = "/home/babylon-node/keystore.ks";
      create_if_missing = false;
    };
    run_with = {
      # Explicitly set the user for the service
      user = "babylon-node";
      # And the group
      group = "babylon-node";
      # Override java options, which allows you to set things like memory allocation
      java_option_overrides = "-Xms12g -Xmx12g"
      # A file which contains environment variables to expose to the service.
      # One particularly important one if you're using a keystore with a password is RADIX_NODE_KEYSTORE_PASSWORD
      environment_file = "/directory/with/secrets/environment";
      # The directory where log files are written
      working_directory = "/home/babylon-node";
    };
  };

  # Any other NixOS configurations, like firewalls or services...
}
```

### Deploying to multiple hosts a the same time using Colmena
In the ecosystem of Nix community tools, there are a few tools that allow you to automatically deploy configurations to multiple nodes over SSH. There is [deploy-rs](https://github.com/serokell/deploy-rs), [NixOps](https://github.com/NixOS/nixops), and [colmena](https://github.com/zhaofengli/colmena) to name a few. I chose to use Colmena because it can easily deploy files with secrets.

#### Quick note on secrets
To run a Radix node, you will at least need a keystore file, which contains the private keys associated with the node. A keystore file may also have a password. It is not possible to store these kinds of secrets in the Nix configuration. Configurations stored in `configuration.nix` may end up in the Nix store (`/nix`), which is the immutable cache of packages on the device. This directory is readable by all users, meaning we should avoid storing secrets in this manner.

There are multiple different secret management schemes for Nix: [nix-sops](https://github.com/Mic92/sops-nix), [agenix](https://github.com/ryantm/agenix), and more. But in this example, we will use a built in feature of the Colmena deployment tool which is to simply deploy secrets at a specific file path on the hosts without storing them in the nix store. This way we don't have to manually ssh into the hosts to deploy these files.


## Versioning

For this project, I am trying out the following versioning scheme:

`babylon-node-version+revision`

The `babylon-node-version` part specifies which version of the Babylon node software is used/compatible, and the revision is for any fixes or upgrades.

## Upgrading your node

To upgrade your node to a new version, you can wait for a new version of this repo to be released and when it is available, follow these steps:

1. Update the `tag` in the `babylon-node-nix.url` input in the `flake.nix` that you use for your NixOS configuration.
2. Run `nix flake update /etc/nixos` (or another path if your flake is not in this dir; note that a "flake" refers to the entire directory)
3. Run `nixos-rebuild switch --flake /etc/nixos#your-architecture` to rebuild and restart your node. Note that this will restart the systemd service.

Your node should now be running the git tag version you specified in the input url.