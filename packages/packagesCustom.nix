{
  lib,
  pkgs,
  wrapper-manager,
  self,
  ...
} @ inputs: let
  wrapped = let
    # wrapper around wrapper-manager.lib.build that sets meta.mainProgram correctly
    build = name: mod: let
      cfg =
        (wrapper-manager.lib.eval {
          inherit pkgs;
          modules = lib.flatten mod;
          specialArgs = {flake = self;};
        })
        .config;
    in
      assert lib.assertMsg (builtins.elem name (builtins.attrNames cfg.wrappers)) "name is not in wrappers!";
        cfg
        .build
        .toplevel
        .overrideAttrs (final: prev: {
          pname = name;
          meta =
            (prev.meta or {})
            // {
              name = final.pname;
              mainProgram = cfg.wrappers.${name}.executableName;
            };
        });
    modules = import (self.lib.modulesPath + /wrapper-manager/list.nix) inputs;
  in
    builtins.mapAttrs build modules;

  scripts = {};
in
  wrapped // scripts
