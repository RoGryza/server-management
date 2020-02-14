modules:
import <nixpkgs/nixos/tests/make-test-python.nix> ({ lib, pkgs, ... }:
  with lib;
  let
    defaultModule = rec {
      _file = ./run-tests.nix;
      key = _file;
      options = {
        nodes = mkOption {
          type = types.attrsOf types.attrs;
          default = {
            server = {};
            client = {};
          };
        };

        testScript = mkOption {
          type = mkOptionType {
            name = "str";
            check = isString;
            merge = _: map
              ({ file, value }: { name = baseNameOf file; script = value; });
          };
          default = {};
        };
      };
      config = {
        _module.args.pkgs = pkgs;
      };
    };
    built = evalModules({
      modules = [defaultModule] ++ modules;
    });
    toSubtest = {name, script}: ''
    with subtest("${ name }"):
        ${script}
    '';
  in {
    inherit (built.config) nodes;
    testScript = ''
    start_all()
    ${strings.concatMapStringsSep "\n" toSubtest built.config.testScript}
    client.wait_for_unit("network.target")
    client.wait_until_succeeds("ping -c 1 server")
    '';
  })
