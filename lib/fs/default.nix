{ lib, ... }:
let
  fs = lib.fileset;
in
{
  set = {
    ffintersection = fn: path: (fs.intersection (fs.fileFilter fn path));
    rdifference = lib.flip fs.difference;

    ffilters = {
      isImportable = f: (f.hasExt "nix") && !(lib.hasPrefix "_" f.name);
      isNix = f: (f.hasExt "nix");
      isDefaultNix = f: f.name == "default.nix";
    };
  };
}
