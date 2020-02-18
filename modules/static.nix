{ config, lib, ... }:
with lib;
{
  imports = [./reverse-proxy.nix];

  options.rogryza.static = {
    enable = mkEnableOption "enable";

    port = mkOption {
      type = types.port;
      default = 8080;
    };

    sites = mkOption {
      type = types.attrsOf types.str;
      default = {};
    };
  };

  config = let cfg = config.rogryza.static; in mkIf cfg.enable {
    services.nginx = {
      enable = true;
      virtualHosts = attrsets.mapAttrs
        (_: v: {
          listen = [{
            addr = "127.0.0.1";
            port = cfg.port;
          }];
          root = v;
        })
        cfg.sites;
    };

    rogryza.proxy.services."http://localhost:${toString cfg.port}" = attrNames cfg.sites;
  };
}
