{
  lib,
  final,
  self,
  internalPath,
  ...
}@args:
let
  _ff = import (internalPath + /file-finding.nix) args;
in
{
  inherit (_ff) findImports importsToAttrs;
}
