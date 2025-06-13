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
    inherit (callLibs ./import) findImports;
    inherit (callLibs ./trivial) last;

    namespaces =
      lib.pipe (findImports {
        from = ./default.nix;
        depth = 1;
        defaultOnly = true;
      })
      [
        (builtins.map (x: let
          name = lib.pipe x [
            (y: "./${builtins.toString y}")
            lib.path.subpath.components
            (lib.dropEnd 1)
            last
            (lib.removeSuffix ".nix")
          ];
        in
          lib.nameValuePair name x))
        builtins.listToAttrs
      ];

    ignore-when-merging = ["theme"];
    namespaces-imported = builtins.mapAttrs (_: callLibs) namespaces;
    namespaces-imported-merged = lib.pipe namespaces-imported [
      (lib.flip builtins.removeAttrs ignore-when-merging)
      builtins.attrValues
      (builtins.foldl' lib.mergeAttrs {})
    ];
  in
    paths // namespaces-imported // namespaces-imported-merged
)
