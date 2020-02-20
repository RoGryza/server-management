{ ... }:
{
  nodes = {
    server = {
      imports = [
        ../modules/reverse-proxy.nix
        ../modules/static.nix
      ];
      rogryza.static = {
        enable = true;
        port = 8000;
        sites = {
          "statica.com" = "/var/www/foo";
          "staticb.com" = "/var/www/bar";
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

  client.fail("curl server:8000 -H 'Host: statica.com' --max-time 2")
  client.fail("curl server:8000 -H 'Host: staticb.com' --max-time 2")
  o = client.succeed("curl server -H 'Host: statica.com'")
  check_response(o, "hello foo\n")
  o = client.succeed("curl server -H 'Host: staticb.com'")
  check_response(o, "hello bar\n")
  '';
}
