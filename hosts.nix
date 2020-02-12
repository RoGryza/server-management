let
  nixpkgs = import <nixpkgs> {};
  local = import ./local.nix;
in

{
  mainServer =
    { configs, pkgs, ... }:
    {
      deployment = {
        targetHost = local.mainServerIp;
        targetPort = local.mainServerPort;
      };

      imports = [
        ./main-server/hardware-configuration.nix
        ./main-server/networking.nix
      ];

      boot.cleanTmpDir = true;
      networking = {
        hostName = "2ndh.l.time4vps.cloud";
        firewall.allowPing = true;
        publicIPv4 = local.mainServerIp;
      };

      users.mutableUsers = false;
      users.users.root.openssh.authorizedKeys.keys = [local.mainServerKey];
      services.openssh = {
        enable = true;
        listenAddresses = [{ addr = local.mainServerIp; }];
        ports = [ local.mainServerPort ];
        passwordAuthentication = false;
        permitRootLogin = "yes";
      };
    };
}
