{ self }:

{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  # babylon-node = self.packages.${pkgs.system}.default;
  options = import ./options.nix { inherit lib; };
  cfg = config.services.babylon_node;
  boolToString = b: if b then "true" else "false";
  cfgfile = pkgs.writeText "babylon.config" ''
    network.id=${toString cfg.config.network.id}
    network.host_ip=${cfg.config.network.host_ip}
    network.p2p.seed_nodes=${pkgs.concatStringsSep "," cfg.config.network.p2p.seed_nodes}
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
  babylon-node = import ./babylon-node.nix { inherit pkgs; };

in
{
  options.services.babylon_node = options;

  config = pkgs.mkIf cfg.enable {
    environment.etc."radixdlt/babylon_node.config".source = cfgfile;

    systemd.services.babylon_node = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      description = "RadixDLT Babylon Node Service";
      serviceConfig = {
        User = cfg.config.run_with.user;
        Group = cfg.config.run_with.group;
        ExecStart = "${babylon-node}/bin/babylonnode -config /etc/radixdlt/babylon_node.config";
        Restart = "always";
        WorkingDirectory = cfg.config.run_with.working_directory;
        EnvironmentFile = cfg.config.run_with.environment_file;
      };
      environment = {
        OVERRIDE_JAVA_OPTS = cfg.config.run_with.java_option_overrides;
      };
    };
  };
}
