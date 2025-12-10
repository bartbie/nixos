{
  lib,
  config,
  ...
}: let
  inherit (lib) types;

  optionsModule = {config, ...}: {
    options = {
      add = lib.mkOption {
        type = lib.types.coercedTo (types.attrsOf types.package) builtins.attrValues (types.listOf types.package);
        default = [];
      };
    };
  };

  eval = mod: {
    pkgs,
    pkgs-unstable,
    nixonArgs,
    ...
  }: (
    if mod == {}
    then []
    else
      (lib.evalModules {
        modules = [
          mod
          optionsModule
          {_module.args = {inherit pkgs pkgs-unstable nixonArgs;} // nixonArgs;}
        ];
      }).config.add
  );
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

  # Add packages.generic to systemPackages filtered by systems' tags
  # This avoids flake.modules.generic.X from host-environment modules anti-pattern
  config.hosts.shared.imports =
    config.packages.generic
    |> lib.mapAttrsToList (
      tag: module: (
        # SAFETY:
        # need to request args explicitly from module system
        ({
            pkgs,
            pkgs-unstable,
            nixonArgs,
            ...
          } @ args: let
            config' = args.config;
          in {
            # TODO: make base tag attached to everyone be default
            environment.systemPackages = lib.mkIf (tag == "base" || builtins.elem tag config'.meta.tags) (
              eval module args
            );
          })
      )
    );

  # Create package module for each class and its declared tag
  # packages {<class> { <name> <module> }}
  config.flake.modules =
    config.packages
    |> (x: builtins.removeAttrs x ["generic"])
    |> builtins.mapAttrs (_class: tagged-modules:
      tagged-modules
      # |> (x: x // {base = x.base or {};})
      |> builtins.mapAttrs (
        _tag: module:
        # SAFETY:
        # need to request args explicitly from module system
        ({
            pkgs,
            pkgs-unstable,
            nixonArgs,
            ...
          } @ args: {
            environment.systemPackages = eval module args;
          })
      ));
}
