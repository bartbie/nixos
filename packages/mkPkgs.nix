{
  lib,
  pkgs,
  wrapper-manager,
  self,
  ...
}: let

  wrapped = let
    modules = importDirs ./wrapped [];
    specialArgs = {flake = self;};
  in
    (wrapper-manager.lib.eval {inherit pkgs modules specialArgs;}).config.build.packages;

  scripts = {};
in
  scripts // wrapped
