let
  nixpkgs = import <nixpkgs> {};
  local = import ./local.nix nixpkgs;
in
with nixpkgs.lib;

{
  network.description = "Production";

  mainServer =
    {
      deployment = {
        targetHost = local.mainNetworking.publicIPv4;
        targetPort = local.mainServerPort;
      };

      imports = [
        <nixpkgs/nixos/modules/profiles/qemu-guest.nix>
        ./modules/ssh.nix
        ./modules/reverse-proxy.nix
        ./modules/static.nix
      ];

      boot.cleanTmpDir = true;
      boot.loader.grub.device = "/dev/sda";
      fileSystems."/" = {
        device = "/dev/sda1";
        fsType = "ext4";
      };

      networking = recursiveUpdate
        { firewall.allowPing = true; }
        local.mainNetworking;

      rogryza.ssh = {
        port = local.mainServerPort;
        rootKey = local.mainServerKey;
      };
    };
}
