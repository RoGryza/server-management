{
  nodes = {
    server = {
      imports = [
        ../modules/python-exercises.nix
        ../modules/reverse-proxy.nix
        ../modules/static.nix
      ];
      rogryza.static = {
        enable = true;
        port = 8000;
      };
      rogryza.python-exercises = {
        enable = true;
        domain = "aulas.rogryza.me";
      };
    };

    client = {};
  };

  testScript = ''
  server.wait_for_open_port(8000)
  server.wait_for_open_port(80)

  def check_response(o, e):
    if (e != o):
      raise Exception(f"Expected {e!r}, got {o!r}")

  client.succeed("curl server -H 'Host: aulas.rogryza.me'")
  '';
}
