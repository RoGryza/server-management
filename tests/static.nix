{ ... }:
{
  nodes = {
    server = {
      imports = [../modules/static.nix];
      rogryza.static = {
        enable = true;
        port = 8000;
        sites = {
          "foo.com" = "/var/www/foo";
          "bar.com" = "/var/www/bar";
        };
      };
    };

    client = {};
  };

  testScript = ''
  server.succeed("mkdir -p /var/www/{foo,bar}")
  server.succeed("echo 'hello foo' > /var/www/foo/index.html")
  server.succeed("echo 'hello bar' > /var/www/bar/index.html")
  server.wait_for_open_port(8000)

  def check_response(o, e):
    if (e != o):
      raise Exception(f"Expected {e!r}, got {o!r}")

  o = server.succeed("curl localhost:8000 -H 'Host: foo.com'")
  check_response(o, "hello foo\n")
  o = server.succeed("curl localhost:8000 -H 'Host: bar.com'")
  check_response(o, "hello bar\n")
  '';
}
