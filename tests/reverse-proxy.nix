{ ... }:
{
  nodes = {
    server = {
      imports = [../modules/reverse-proxy.nix];
      rogryza.http.port = 8080;
    };

    client = {};
  };

  testScript = ''
  server.wait_for_open_port(8080)
  client.succeed("curl server:8080")
  '';
}
