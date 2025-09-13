{
  lib,
  config,
  ...
}: let
  inherit (lib) types;

  scaffolding = {config, ...}: {
    options = {
      add = lib.mkOption {
        type = lib.types.coercedTo (types.attrsOf types.package) builtins.attrValues (types.listOf types.package);
        default = [];
      };
    };
  };
in {
  options = {
    packages = lib.mkOption {
      #       class              tag/mod-name
      type = types.lazyAttrsOf (types.lazyAttrsOf types.deferredModule);
      description = ''
        Define systemPackages for class and tag/module name.
        Can be packages.<class>.<name> = <module> or packages.generic.<name> = <module>
      '';
      default = {};
    };
  };
  config.flake.modules =
    config.packages
    |> (x: builtins.removeAttrs x ["generic"])
    |> builtins.mapAttrs (_class: per-tag:
      per-tag
      |> builtins.mapAttrs (modName: pkgSubmodule: (
        {config, ...}: let
          eval = mod:
            if mod == {}
            then []
            else
              (lib.evalModules {
                specialArgs = builtins.removeAttrs config._module.args ["config" "options"];
                modules = [scaffolding mod];
              }).config.add;
        in {
          environment.systemPackages =
            (eval pkgSubmodule)
            ++ (eval (config.packages.generic.${modName} or {}));
        }
      )));
}
