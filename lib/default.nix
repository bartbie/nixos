{lib}: let
  paths = {
    modulesPath = ../modules;
    libPath = ./.;
    scriptsPath = ../scripts;
  };

  lib-inputs = {inherit lib final;};
  inherit (import ./import lib-inputs) findImports;

  namespaces = lib.pipe (findImports ./default.nix []) [
    (builtins.map (x: lib.nameValuePair (builtins.baseNameOf x) x))
    builtins.listToAttrs
  ];

  namespaces-imported = builtins.mapAttrs (_: v: import v lib-inputs) namespaces;
  namespaces-imported-merged = builtins.foldl' lib.mergeAttrs {} (builtins.attrValues namespaces-imported);

  final = paths // namespaces-imported // namespaces-imported-merged;
in
  final
