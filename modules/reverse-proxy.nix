{ config, pkgs, lib, ... }:
with lib;
{
  options.rogryza.http = {
    port = mkOption {
      type = types.port;
      default = 80;
    };
  };

  config = let cfg = config.rogryza.http; in {
    networking.firewall.allowedTCPPorts = [cfg.port];
    services.traefik = {
      enable = true;
      configOptions = {
        defaultEntryPoints = ["http"];
        entryPoints = {
          http = {
            address = ":${toString(cfg.port)}";
          };
        };
      };
    };
  };
}
