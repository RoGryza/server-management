{ pkgs, ... }:
let
  mkServer = tls: {
    imports = [ ../modules/reverse-proxy.nix ];
    rogryza.proxy = {
      inherit tls;
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
in

{
  nodes = {
    server = mkServer {};
    tlsServer = mkServer {
      enable = true;
      caServer = "https://acme-staging-v02.api.letsencrypt.org/directory";
    };
    client = {};
  };

  testScript = ''
    server.wait_for_open_port(80)
    server.wait_for_open_port(3000)
    server.wait_for_open_port(4000)

    def check_response(o, e):
      if (e != o):
        raise Exception(f"Expected {e!r}, got {o!r}")

    o = client.succeed("curl server -H 'Host: foo.com'")
    check_response(o, "foo")
    o = client.succeed("curl server -H 'Host: bar.com'")
    check_response(o, "bar")
    o = client.succeed("curl server -H 'Host: qux.com'")
    check_response(o, "qux")

    tlsServer.wait_for_open_port(443)
    tlsServer.wait_for_open_port(3000)
    tlsServer.wait_for_open_port(4000)

    o = client.succeed("curl -k https://tlsServer -H 'Host: foo.com'")
    check_response(o, "foo")
    o = client.succeed("curl -k https://tlsServer -H 'Host: bar.com'")
    check_response(o, "bar")
    o = client.succeed("curl -k https://tlsServer -H 'Host: qux.com'")
    check_response(o, "qux")
  '';
}
