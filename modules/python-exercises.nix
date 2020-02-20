{ config, lib, pkgs, ... }:
with lib;
{
  options.rogryza.python-exercises = {
    enable = mkEnableOption "enable";
    domain = mkOption {
      type = types.str;
    };
    version = mkOption {
      type = types.str;
      default = "0.1.0";
    };
    repo = mkOption {
      type = types.str;
      default = "RoGryza/python-exercises";
    };
    sha256 = mkOption {
      type = types.str;
      default = "0a6q0wzxblwjs2xc08wb9sibpknp273003zqab6x5iw78b84wd07";
    };
  };

  config =
    let
      cfg = config.rogryza.python-exercises;
      drv = pkgs.stdenv.mkDerivation {
        name = "python-exercises-${version}";

        src = pkgs.fetchurl {
          url = "https://github.com/${cfg.repo}/releases/download/v${cfg.version}/python-exercises.tar.gz";
          inherit (cfg) sha256;
        };

        phases = [ "unpackPhase" "installPhase" ];

        installPhase = ''
        mkdir -p $out
        cp -r . $out/static
        '';
      };
    in

      mkIf cfg.enable {
        rogryza.static.enable = true;
        rogryza.static.sites = {
          "${cfg.domain}" = "${drv}/static/";
        };
      };
}
