{
  lib,
  pkgs,
  wrapper-manager,
  self,
  ...
}: let
  fs = lib.fileset;
  importDirs = root: ignored:
    lib.pipe root [
      builtins.readDir
      (lib.attrsets.filterAttrs (n: v: v == "directory" && !(lib.hasPrefix "_" n)))
      builtins.attrNames
      (builtins.map (d: root + /${d}/default.nix))
      fs.unions
      (fs.intersection (fs.fileFilter self.lib.filterFnNonNix root))
      (x: fs.difference x (fs.unions ignored))
      fs.toList
    ];

  wrapped = let
    modules = importDirs ./wrapped [];
    specialArgs = {flake = self;};
  in
    (wrapper-manager.lib.eval {inherit pkgs modules specialArgs;}).config.build.packages;

  scripts = {};
in
  scripts // wrapped
