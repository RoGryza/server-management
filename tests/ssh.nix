{ pkgs, ... }:
let inherit (import <nixpkgs/nixos/tests/ssh-keys.nix> pkgs)
  snakeOilPrivateKey snakeOilPublicKey;
in
{
  nodes = {
    server = {
      imports = [../modules/ssh.nix];
      rogryza.ssh = { rootKey = snakeOilPublicKey; };
    };

    client = {};
  };

  testScript = ''
  server.wait_for_unit("sshd")
  server.wait_for_open_port(22)
  client.succeed(
      "cat ${snakeOilPrivateKey} > privkey.snakeoil"
  )
  client.succeed("chmod 600 privkey.snakeoil")
  client.succeed(
      "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o ConnectTimeout=3 -i privkey.snakeoil server true"
  )
  '';
}
