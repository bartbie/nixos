# this gets imported both by `modules/wrapper-manager` and `packages/`
# they have different inputs (modules vs not) so keep the args simple for compatibility
{
  lib,
  flake,
  ...
}: let
  modulesToAttr = modules: let
    getName = lib.flip lib.pipe [
      lib.path.splitRoot
      (x: x.subpath)
      lib.path.subpath.components
      lib.reverseList
      (x: builtins.elemAt x 1)
    ];
  in
    lib.pipe modules [
      (builtins.map (x: lib.nameValuePair (getName x) x))
      lib.attrsets.listToAttrs
    ];
  withIgnored = lib.flip lib.pipe [
    (flake.lib.findImportDirs ./.)
    modulesToAttr
  ];
in
  withIgnored []
