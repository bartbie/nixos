{ lib }:
lib.fix (
  final:
  let
    paths = {
      modulesPath = ../modules;
      libPath = ./.;
      scriptsPath = ../scripts;
      templatesPath = ../templates;
      srcPath = ../src;
    };

    # self: intra-module recursion. final: cross-namespace references.
    callLibs = name: lib.fix (self: import (./. + "/${name}") { inherit lib final self; });

    nsPaths = [
      ./attrsets
      ./assertions
      ./builders
      ./dag
      ./fs
      ./generators
      ./hypr
      ./options
      ./path
      ./pkgh
      ./systemd
      ./theme
    ];
    namespaces = lib.genAttrs (map baseNameOf nsPaths) callLibs;
  in
  namespaces
  // paths
  // {
    inherit (final.attrsets) flattenAttrs optionalAttr;
  }
)
