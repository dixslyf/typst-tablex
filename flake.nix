{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    "nixpkgs-typst-0.2.0".url = "github:NixOS/nixpkgs/b646bfafe911130e4478c00642646f40d5ab8949";
    "nixpkgs-typst-0.3.0".url = "github:NixOS/nixpkgs/059148a9d353a743159769fd64aedcc5a77c7847";
    "nixpkgs-typst-0.4.0".url = "github:NixOS/nixpkgs/5d120d370191484d1ba8f4b87fe63b20cbd70209";
    "nixpkgs-typst-0.5.0".url = "github:NixOS/nixpkgs/ed4e2af68da194518f9929fe617f999742f50657";
    "nixpkgs-typst-0.6.0".url = "github:NixOS/nixpkgs/b0fd86580bff587d81f6d2563edaebc80ac11e01";
    "nixpkgs-typst-0.7.0".url = "github:NixOS/nixpkgs/85963eba3a76ff2ae4928b9d5de45cbfe9eee2d8";
    "nixpkgs-typst-0.8.0".url = "github:NixOS/nixpkgs/6bac7498ba01666608ca3b5885dc7de7665e1bd4";
    "nixpkgs-typst-0.9.0".url = "github:NixOS/nixpkgs/a2046fdb713ea2637f73ab5a56600d64fe2ad30d";
  };

  outputs =
    inputs @ { flake-utils
    , nixpkgs
    , ...
    }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (nixpkgs) lib;

      typstVersions = [
        "0.2.0"
        "0.3.0"
        "0.4.0"
        "0.5.0"
        "0.6.0"
        "0.7.0"
        "0.8.0"
        "0.9.0"
      ];

      packageForTypstVersion = version: inputs."nixpkgs-typst-${version}".legacyPackages.${system}.typst;

      mkTablexTestScript = typstPkg: pkgs.stdenvNoCC.mkDerivation
        {
          pname = "test-tablex";
          inherit (typstPkg) version;

          src = ./test-tablex;

          dontUnpack = true;

          nativeBuildInputs = [
            pkgs.makeWrapper
          ];

          installPhase = ''
            mkdir -p "$out/bin"

            BIN_FILE="$out/bin/test-tablex"

            cp "$src" "$BIN_FILE"
            wrapProgram "$BIN_FILE" \
              --prefix PATH : ${lib.makeBinPath [ typstPkg pkgs.diff-pdf ]}
          '';
        };

      tablexTestScripts = map (version: mkTablexTestScript (packageForTypstVersion version)) typstVersions;
      tablexTestScriptsAttrs = builtins.listToAttrs
        (map
          (script: { inherit (script) name; value = script; })
          tablexTestScripts
        );


      testTablexForAllTypstVersions = pkgs.writeShellScriptBin "test-tablex-for-all-typst-versions" ''
        update() {
            ${
                builtins.concatStringsSep
                  "\n"
                  (map (script: "${script}/bin/test-tablex update") tablexTestScripts)
            }
        }

        compare() {
            ${
                builtins.concatStringsSep
                  "\n"
                  (map (script: "${script}/bin/test-tablex compare") tablexTestScripts)
            }
        }

        COMMAND="$1"
        case "$COMMAND" in
            update)
                update
                ;;
            compare)
                compare
                ;;
            "")
                echo "No command provided"
                ;;
            *)
                echo "Unknown command: $COMMAND"
                ;;
        esac
      '';
    in
    {
      packages = tablexTestScriptsAttrs // {
        inherit testTablexForAllTypstVersions;
      };
    });
}
