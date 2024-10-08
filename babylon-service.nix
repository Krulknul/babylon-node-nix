{ nixpkgs }:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  boolToString = b: if b then "true" else "false";
  pkgsFixed = import nixpkgs { system = pkgs.system; };
  babylon-node = import ./babylon-node.nix { pkgs = pkgsFixed; };
  options = import ./options.nix { inherit lib; };
  cfg = config.services.babylon-node;
  cfgfile = pkgsFixed.writeText "babylon.config" ''
    network.id=${toString cfg.config.network.id}
    network.host_ip=${cfg.config.network.host_ip}
    network.p2p.seed_nodes=${lib.concatStringsSep "," cfg.config.network.p2p.seed_nodes}
    network.p2p.listen_port=${toString cfg.config.network.p2p.listen_port}
    network.p2p.broadcast_port=${toString cfg.config.network.p2p.broadcast_port}
    node.key.path=${cfg.config.node.key.path}
    node.key.create_if_missing=${boolToString cfg.config.node.key.create_if_missing}
    db.location=${cfg.config.db.location}
    db.local_transaction_execution_index.enable=${boolToString cfg.config.db.local_transaction_execution_index.enable}
    db.account_change_index.enable=${boolToString cfg.config.db.account_change_index.enable}
    api.core.bind_address=${cfg.config.api.core.bind_address}
    api.core.port=${toString cfg.config.api.core.port}
    api.system.bind_address=${cfg.config.api.system.bind_address}
    api.system.port=${toString cfg.config.api.system.port}
    api.prometheus.bind_address=${cfg.config.api.prometheus.bind_address}
    api.prometheus.port=${toString cfg.config.api.prometheus.port}
    api.core.flags.enable_unbounded_endpoints=${boolToString cfg.config.api.core.flags.enable_unbounded_endpoints}
  '';
  ledger-snapshot = import ./snapshot/snapshot.nix {
    pkgs = pkgsFixed;
    dbDir = cfg.config.db.location;
    user = cfg.config.run_with.user;
    group = cfg.config.run_with.group;
  };

in
{
  options.services.babylon-node = options;
  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      environment.etc."radixdlt/babylon-node.config".source = cfgfile;

      systemd.services.babylon-node = {
        wantedBy = [ "multi-user.target" ];
        after = [
        "network-online.target"
        "local-fs.target"
        "nns-lookup.target"
        "time-sync.target"
        "systemd-journald-dev-log.socket"
        ];
        wants = [ "network-online.target" ];
        description = "RadixDLT Babylon Node Service";
        serviceConfig = {
          User = cfg.config.run_with.user;
          Group = cfg.config.run_with.group;
          ExecStart = "${pkgs.bash}/bin/bash -c 'RADIX_NODE_KEYSTORE_PASSWORD=\$(cat ${cfg.config.run_with.keystore_password_file}) exec ${babylon-node}/bin/babylon-node -config /etc/radixdlt/babylon-node.config'";
          Restart = "always";
          WorkingDirectory = cfg.config.run_with.working_directory;
          LimitNOFILE = 65536;
          LimitNPROC = 65536;
          LimitMEMLOCK = "infinity";
          SuccessExitStatus = "143";
          TimeoutStopSec = 10;
        };
        environment = {
          OVERRIDE_JAVA_OPTS = cfg.config.run_with.java_option_overrides;
        };
      };
    })
    {
      environment.systemPackages = with pkgs; [
        ledger-snapshot
      ];
    }
  ];
}
