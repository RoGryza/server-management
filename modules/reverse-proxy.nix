{ config, pkgs, lib, ... }:
with lib;
{
  options.rogryza.proxy = {
    port = mkOption {
      type = types.port;
      default = 80;
    };
    services = mkOption {
      type = types.attrsOf (types.listOf types.str);
      default = {};
    };
  };

  config = let cfg = config.rogryza.proxy; in {
    networking.firewall.allowedTCPPorts = [cfg.port];
    services.traefik = {
      enable = true;
      configOptions = {
        defaultEntryPoints = ["http"];
        entryPoints = {
          http = {
            address = ":${toString(cfg.port)}";
            compress = true;
          };
        };
        file = {};
        frontends = flip attrsets.mapAttrs cfg.services
          (b: hosts: {
            backend = b;
            passHostHeader = true;
            routes.route.rule = "Host:${strings.concatStringsSep "," hosts}";
          });
        backends = attrsets.mapAttrs (b: _: { servers.server.url = b; }) cfg.services;
      };
    };
  };
}
