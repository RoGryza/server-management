modules:
import <nixpkgs/nixos/tests/make-test-python.nix> ({ lib, pkgs, ... }:
  with lib;
  let
    nodeType = mkOptionType {
      name = "node";
      check = isAttrs;
      merge = loc: defs:
        let vals = map (def: def.value) defs;
        in (foldl' attrsets.recursiveUpdate {} vals) // {
          imports = concatMap ({ imports ? [], ... }: imports) vals;
          environment.systemPackages = concatMap ({ environment ? {}, ... }: (attrsets.attrByPath ["systemPackages"] [] environment)) vals;
        };
      emptyValue = {};
    };
    defaultModule = rec {
      _file = ./run-tests.nix;
      key = _file;
      options = {
        nodes = mkOption {
          type = types.attrsOf nodeType;
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
    skipLint = true;
    testScript = ''
    start_all()
    client.wait_for_unit("network.target")
    client.wait_until_succeeds("ping -c 1 server")
    ${strings.concatMapStringsSep "\n" toSubtest built.config.testScript}
    '';
  })
