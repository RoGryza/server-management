{ config, pkgs, lib, ... }:
with lib;
{
  options.rogryza.proxy = {
    port = mkOption {
      type = types.port;
      default = 80;
    };
    tls.enable = mkEnableOption "enable";
    tls.port = mkOption {
      type = types.port;
      default = 443;
    };
    tls.caServer = mkOption {
      type = types.str;
      default = "https://acme-v02.api.letsencrypt.org/directory";
    };
    services = mkOption {
      type = types.attrsOf (types.listOf types.str);
      default = {};
    };
  };

  config = let
    cfg = config.rogryza.proxy;
    tlsCfg = attrsets.optionalAttrs cfg.tls.enable {
      defaultEntryPoints = ["http" "https"];
      acme = {
        entryPoint = "https";
        tlsChallenge = {};
        caServer = cfg.tls.caServer;
        onHostRule = true;
        storage = "${config.services.traefik.dataDir}/acme.json";
      };
      entryPoints = {
        http.redirect.entrypoint = "https";
        https = {
          address = ":${toString(cfg.tls.port)}";
          compress = true;
          tls = {};
        };
      };
    };
  in
    {
      networking.firewall.allowedTCPPorts =
        if cfg.tls.enable
        then [cfg.port cfg.tls.port]
        else [cfg.port];

      services.traefik = {
        enable = true;
        configOptions = flip attrsets.recursiveUpdate tlsCfg {
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
