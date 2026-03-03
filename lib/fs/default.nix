{
  lib,
  final,
  self,
  internalPath,
  ...
}@args:
let
  fs = lib.fileset;
  _ff = import (internalPath + /file-finding.nix) args;
in
{
  inherit (_ff) listRecursive;
  set = {
    ffintersection = fn: path: (fs.intersection (fs.fileFilter fn path));
    rdifference = lib.flip fs.difference;

    ffilters = {
      isImportable = f: (f.hasExt "nix") && !(lib.hasPrefix "_" f.name);
      isNix = f: (f.hasExt "nix");
      isDefaultNix = f: f.name == "default.nix";
    }
    // _ff.ffilters;
  };
}
