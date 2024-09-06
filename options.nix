{ lib, ... }:

let
  mkOption = lib.mkOption;
  types = lib.types;
in
{
  enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Whether to enable the Babylon node service.";
  };
  config = mkOption {
    default = { };
    type = types.submodule {
      options = {
        network = mkOption {
          default = { };
          type = types.submodule {
            options = {
              id = mkOption {
                type = types.int;
                default = 1;
                description = "The ID of the network to connect to (Mainnet=1, Stokenet=2)";
              };
              p2p = mkOption {
                default = { };
                type = types.submodule {
                  options = {
                    listen_port = mkOption {
                      type = types.int;
                      default = 30000;
                      description = "The gossop port for listening";
                    };
                    broadcast_port = mkOption {
                      type = types.int;
                      default = 30000;
                      description = "The gossip port for broadcasting";
                    };
                    seed_nodes = mkOption {
                      type = types.listOf (types.str);
                      default = [
                        "radix://node_rdx1qf2x63qx4jdaxj83kkw2yytehvvmu6r2xll5gcp6c9rancmrfsgfw0vnc65@babylon-mainnet-eu-west-1-node0.radixdlt.com"
                        "radix://node_rdx1qgxn3eeldj33kd98ha6wkjgk4k77z6xm0dv7mwnrkefknjcqsvhuu4gc609@babylon-mainnet-ap-southeast-2-node0.radixdlt.com"
                        "radix://node_rdx1qwrrnhzfu99fg3yqgk3ut9vev2pdssv7hxhff80msjmmcj968487uugc0t2@babylon-mainnet-ap-south-1-node0.radixdlt.com"
                        "radix://node_rdx1q0gnmwv0fmcp7ecq0znff7yzrt7ggwrp47sa9pssgyvrnl75tvxmvj78u7t@babylon-mainnet-us-east-1-node0.radixdlt.com"
                      ];
                      description = "A list of network seed nodes. The defaults specified are the mainnet seed nodes.";
                    };
                  };
                };
              };
            };
          };
        };
        node = mkOption {
          default = { };
          type = types.submodule {
            options = {
              key = mkOption {
                default = { };
                type = types.submodule {
                  options = {
                    path = mkOption {
                      type = types.path;
                      default = "";
                      description = "The path to the node key file";
                    };
                    create_if_missing = mkOption {
                      type = types.bool;
                      default = false;
                      description = "Create a new key if the key file is missing";
                    };
                  };
                };
              };
            };
          };
        };
        db = mkOption {
          default = { };
          type = types.submodule {
            options = {
              location = mkOption {
                type = types.path;
                default = "";
                description = "The path to the database";
              };
              local_transaction_execution_index.enable = mkOption {
                type = types.bool;
                default = true;
                description = "An additional ledger index for transaction data";
              };
              account_change_index.enable = mkOption {
                type = types.bool;
                default = true;
                description = "An additional ledger index for transactions that change accounts";
              };
            };
          };
        };
        api = mkOption {
          default = { };
          type = types.submodule {
            options = {
              core = mkOption {
                default = { };
                type = types.submodule {
                  options = {
                    bind_address = mkOption {
                      type = types.str;
                      default = "127.0.0.1";
                      description = "The address to bind the core API to";
                    };
                    port = mkOption {
                      type = types.int;
                      default = 3333;
                      description = "The port to bind the core API to";
                    };
                    flags.enable_unbounded_endpoints = mkOption {
                      type = types.bool;
                      default = true;
                      description = "Allows to disable a subset of Core API endpoints whose responses are potentially unbounded";
                    };
                  };
                };
              };
              system = mkOption {
                default = { };
                type = types.submodule {
                  options = {
                    bind_address = mkOption {
                      type = types.str;
                      default = "127.0.0.1";
                      description = "The address to bind the system API to";
                    };
                    port = mkOption {
                      type = types.int;
                      default = 3334;
                      description = "The port to bind the system API to";
                    };
                  };
                };
              };
              prometheus = mkOption {
                default = { };
                type = types.submodule {
                  options = {
                    bind_address = mkOption {
                      type = types.str;
                      default = "127.0.0.1";
                      description = "The address to bind the Prometheus API to";
                    };
                    port = mkOption {
                      type = types.int;
                      default = 3335;
                      description = "The port to bind the Prometheus API to";
                    };
                  };
                };
              };
            };
          };
        };
        run_with = mkOption {
          default = { };
          type = types.submodule {
            options = {
              user = mkOption {
                type = types.str;
                default = "babylon_node";
                description = "The user to run the service as";
              };
              group = mkOption {
                type = types.str;
                default = "babylon_node";
                description = "The group to run the service as";
              };
              java_option_overrides = mkOption {
                type = types.str;
                default = "";
                description = "Java option overrides";
                example = "-Xms12g -Xmx12g";
              };
              environment_file = mkOption {
                type = types.str;
                default = "";
                description = "The environment file that contains the environment variable RADIX_NODE_KEYSTORE_PASSWORD";
              };
              working_directory = mkOption {
                type = types.str;
                default = "/home/babylon_node";
                description = "The working directory for the service";
              };
            };
          };
        };
      };
    };
  };
}
