{ config, pkgs, lib, ... }:
with lib;
{
  options.rogryza = {
    ssh = {
      port = mkOption {
        type = types.port;
        default = 22;
      };
      rootKey = mkOption {
        type = types.str;
      };
    };
  };

  config = {
    users.users.root.openssh.authorizedKeys.keys = [config.rogryza.ssh.rootKey];
    services.openssh = {
      enable = true;
      ports = [ config.rogryza.ssh.port ];
      passwordAuthentication = false;
      permitRootLogin = "yes";
    };
  };
}
