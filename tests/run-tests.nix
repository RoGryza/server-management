modules:
let
  nixpkgs = builtins.fetchGit {
    name = "nixos-unstable-2018-09-12";
    url = https://github.com/nixos/nixpkgs-channels/;
    ref = "refs/heads/nixos-unstable";
    rev = "82b54d490663b6d87b7b34b9cfc0985df8b49c7d";
  };
in
import "${nixpkgs}/nixos/tests/make-test-python.nix" ({ lib, pkgs, ... }:
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
    try:
      client.wait_for_unit("network.target")
      client.wait_until_succeeds("ping -c 1 server")
    except NameError:
      pass

    ${strings.concatMapStringsSep "\n" toSubtest built.config.testScript}
    '';
  })
