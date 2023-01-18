{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.akkoma-prometheus-exporter;
  defaultUser = "akkoma-exporter";
in {
  options.services.akkoma-prometheus-exporter = let
    instOpts = types.submodule ({ name, config, ... }: {
      options = {
        user = mkOption {
          type = types.str;
          description = "User to run under";
          default = defaultUser;
        };

        group = mkOption {
          type = types.str;
          description = "Group to run under";
          default = defaultUser;
        };

        url = mkOption {
          description = "URL to the healthcheck endpoint.";
          type = types.str;
        };

        port = mkOption {
          description = "Port to listen on";
          type = types.port;
        };

        package = mkOption {
          description = "Package to use";
          type = types.package;
          default = pkgs.akkoma-exporter;
        };
      };

      config.url = "https://${name}/api/v1/pleroma/healthcheck";
    });

  in mkOption {
    type = with types; attrsOf instOpts;
    default = { };
    description = ''
      Instances to run. If none are defined then this module is disabled.
    '';
  };

  config.systemd.services = mkMerge (mapAttrsToList (name: instCfg: {
    "akkoma-exporter-${name}" = {
      environment = {
        URL = instCfg.url;
        PORT = builtins.toString instCfg.port;
      };

      serviceConfig = {
        User = instCfg.user;
        Group = instCfg.group;
        ExecStart = "${instCfg.package}/bin/akkoma-exporter";
      };
    };
  }) cfg);

  config.users = mkMerge (mapAttrsToList (name: instCfg: {
    users = optionalAttrs (instCfg.user == defaultUser) {
      "${defaultUser}" = {
        group = instCfg.group;
        isSystemUser = true;
      };
    };

    groups =
      optionalAttrs (instCfg.group == defaultUser) { ${defaultUser} = { }; };
  }) cfg);
}

