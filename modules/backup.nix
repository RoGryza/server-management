{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.rogryza.backup;
  rcloneCfgFile = remote: pkgs.writeText "rclone.conf" ''
  [remote]
  ${concatStringsSep "\n" (mapAttrsToList (name: value: "${name} = ${value}") remote)}
  '';
  backupDirOptions = {
    source = mkOption { type = types.str; };
    dest = mkOption { type = types.str; };
  };
in

{
  options.rogryza.backup = {
    enable = mkEnableOption "enable";
    remote = mkOption {
      type = types.attrs;
      default = {};
    };
    remoteRoot = mkOption {
      type = types.str;
      default = "backups";
    };
    paths = mkOption {
      type = types.attrsOf (types.submodule {
        options = backupDirOptions;
      });
      default = {};
    };
    startAt = mkOption {
      type = types.str;
      default="*:0/15";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [pkgs.rclone];

    systemd.services =
      let
        cfgFile = rcloneCfgFile cfg.remote;
      in
        mapAttrs'
          (name: {source, dest, ...}: nameValuePair "backup-${name}" {
            description = "Backup of ${source}";
            serviceConfig.Type = "oneshot";

            script = ''
          if [ -e "${source}" ]; then
             ${pkgs.rclone}/bin/rclone --config "${cfgFile}" sync "${source}" "remote:${cfg.remoteRoot}/${dest}"
          fi
          '';
          })
          cfg.paths;
    systemd.timers = genAttrs
      (map (name: "backup-${name}") (attrNames cfg.paths))
      (name: {
        enable = true;
        description = "Timer for ${name}";
        timerConfig.OnCalendar = cfg.startAt;
        timerConfig.Persistent = true;
        wantedBy = ["timers.target"];
      });
  };
}
