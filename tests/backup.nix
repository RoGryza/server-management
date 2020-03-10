{ pkgs, ... }:
{
  nodes = {
    server = {
      imports = [../modules/backup.nix];
      rogryza.backup = {
        enable = true;
        remote = {
          type = "local";
        };
        paths = {
          foo = {
            source = "/srv/foo";
            dest = "foo";
          };
          bar = {
            source = "/srv/bar";
            dest = "bar";
          };
        };
      };
    };
  };

  testScript = ''
  server.succeed("mkdir -p /srv/bar")
  server.succeed("echo -n 'foo' > /srv/foo")
  server.succeed("echo -n 'bar' > /srv/bar/qux")
  server.succeed("systemctl start backup-foo")
  server.succeed("systemctl start backup-bar")
  stdout = server.wait_until_succeeds("cat /srv/foo")
  assert stdout == 'foo'
  stdout = server.succeed("cat /srv/bar/qux")
  assert stdout == 'bar'
  '';
}
