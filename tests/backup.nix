{ pkgs, ... }:
{
  nodes = {
    server = {
      imports = [../modules/backup.nix];
      rogryza.backup = {
        enable = true;
        remote.type = "local";
        remoteRoot = "/root/backups";
        paths = {
          foo = {
            source = "/bkps/foo";
            dest = "foo";
          };
          bar = {
            source = "/bkps/bar";
            dest = "bar";
          };
        };
      };
    };
  };

  testScript = ''
  server.succeed("systemctl list-timers | grep -q backup-foo.timer")
  server.succeed("systemctl list-timers | grep -q backup-bar.timer")

  server.succeed("mkdir -p /bkps/{foo,bar}")
  server.succeed("echo -n 'foo' > /bkps/foo/foo")
  server.succeed("echo -n 'bar' > /bkps/bar/qux")
  server.succeed("systemctl start backup-foo")
  server.succeed("journalctl -u backup-foo | grep -q Succeeded")
  server.succeed("systemctl start backup-bar")
  server.succeed("journalctl -u backup-bar | grep -q Succeeded")

  stdout = server.wait_until_succeeds("cat /root/backups/foo/foo")
  assert stdout == 'foo'
  stdout = server.wait_until_succeeds("cat /root/backups/bar/qux")
  assert stdout == 'bar'
  '';
}
