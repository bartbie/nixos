{
  lib,
  pkgs,
  wrapper-manager,
  self,
  ...
} @ inputs: let
  wrapped = let
    build = module:
      wrapper-manager.lib.build {
        inherit pkgs;
        modules = [module];
        specialArgs = {flake = self;};
      };
    modules = import ../modules/wrapper-manager/list.nix inputs;
  in
    builtins.mapAttrs (_: build) modules;

  scripts = {};
in
  wrapped // scripts
