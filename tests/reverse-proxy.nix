{ pkgs, ... }: {
  nodes = {
    server = {
      imports = [ ../modules/reverse-proxy.nix ];
      rogryza.proxy = {
        port = 8080;
        services = {
          "http://localhost:3000" = [ "foo.com" ];
          "http://localhost:4000" = [ "bar.com" "qux.com" ];
        };
      };
      services.nginx = {
        enable = true;
        virtualHosts = let
          vhost = port: resp: {
            listen = [{
              inherit port;
              addr = "127.0.0.1";
            }];
            locations."/".return = "200 '${resp}'";
          };
        in {
          "foo.com" = vhost 3000 "foo";
          "bar.com" = vhost 4000 "bar";
          "qux.com" = vhost 4000 "qux";
        };
      };
    };

    client = { };
  };

  testScript = ''
    server.wait_for_open_port(8080)
    server.wait_for_open_port(3000)
    server.wait_for_open_port(4000)

    def check_response(o, e):
      if (e != o):
        raise Exception(f"Expected {e!r}, got {o!r}")

    o = client.succeed("curl server:8080 -H 'Host: foo.com'")
    check_response(o, "foo")
    o = client.succeed("curl server:8080 -H 'Host: bar.com'")
    check_response(o, "bar")
    o = client.succeed("curl server:8080 -H 'Host: qux.com'")
    check_response(o, "qux")
  '';
}
