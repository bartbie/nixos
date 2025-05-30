{lib}:
lib.fix (
  final: let
    paths = {
      modulesPath = ../modules;
      libPath = ./.;
      scriptsPath = ../scripts;
    };

    internalPath = ./_zinternal;

    callLibs = file: lib.fix (self: import file {inherit lib final self internalPath;});

    # check ./_zinternal/file-finding.nix docs
    inherit (callLibs ./import) findImports importsToAttrs;

    namespaces = importsToAttrs (findImports {
      from = ./default.nix;
      depth = 1;
      defaultOnly = true;
    });

    namespaces-imported = builtins.mapAttrs (_: callLibs) namespaces;
  in
    namespaces-imported
    // paths
    // (callLibs ./trivial)
    // {
      inherit findImports;
      inherit (final.attrsets) flattenAttrs optionalAttr;
    }
)
