{
  lib,
  config,
  inputs,
  withSystem,
  ...
}: let
  inherit (lib) types;

  wrappedSubmodule = lib.types.submodule {
    options = {
      enable = (lib.mkEnableOption "this wrapperManager module") // {default = true;};

      systems = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = config.systems;
      };

      tags = lib.mkOption {
        type = types.coercedTo (types.enum [null]) (_: ["base"]) (lib.types.listOf lib.types.str);
        default = ["pc"];
      };

      module = lib.mkOption {
        type = lib.types.deferredModule;
        example = lib.options.literalExpression ''
          wrapped.mpv.module = {pkgs, ...}: {
            wrappers = {
              mpv = {
                arg0 = lib.getExe' pkgs.mpv "mpv";
              };
              mpvf = {
                arg0 = lib.getExe' pkgs.mpv "mpv";
                prependArgs = ["-fs"];
              };
            };
          };
        '';
      };
    };
  };

  mkWrapper = {
    modules,
    pkgs,
    nixonArgs,
  }:
    assert nixonArgs ? theme;
    assert nixonArgs ? pkgs-unstable;
      lib.makeOverridable (
        {extraWrapperModules ? [], ...} @ overrideArgs: let
          cfg =
            (inputs.wrapper-manager.lib.eval {
              inherit pkgs;
              modules = lib.flatten [
                config.flake.modules.wrapperManager.base
                config.flake.modules.generic.meta
                modules
                extraWrapperModules
              ];
              specialArgs = withSystem pkgs.hostPlatform.system ({
                self',
                inputs',
                ...
              }:
                {
                  inherit
                    overrideArgs
                    self'
                    inputs'
                    nixonArgs
                    ;
                }
                // nixonArgs);
            }).config;
          overriden = cfg.build.toplevel.override cfg.override;
        in (overriden.overrideAttrs cfg.overrideAttrs)
      ) {};
in {
  options.wrapped = lib.mkOption {
    type = lib.types.lazyAttrsOf wrappedSubmodule;
    default = {};
  };

  config = let
    wrapped =
      config.wrapped
      |> (x: builtins.removeAttrs x ["base"])
      |> lib.filterAttrs (_: v: v.enable);

    wrappedForSystem = system:
      wrapped
      |> lib.filterAttrs (_: v: builtins.elem system v.systems);

    toModules = wrapped: wrapped |> builtins.mapAttrs (_: v: v.module);
  in {
    flake.modules.wrapperManager = toModules wrapped;

    # packages.nixos.pc = {};
    packages.generic =
      wrapped
      |> builtins.mapAttrs (
        name: {
          module,
          tags,
          systems,
          ...
        }:
          lib.genAttrs tags (_: {
            ${name} = {
              pkgs,
              nixonArgs,
              system,
              ...
            }:
              lib.optionalAttrs (builtins.elem system systems)
              {
                add =
                  lib.singleton
                  ((mkWrapper {
                      inherit pkgs nixonArgs;
                      modules = module;
                    }).override {
                      extraWrapperModules = [
                        {locale.enable = lib.mkDefault false;}
                      ];
                    });
              };
          })
      )
      |> builtins.attrValues
      |> (builtins.foldl' lib.recursiveUpdate {});

    perSystem = {
      pkgs,
      system,
      nixonArgs,
      ...
    }: {
      packages =
        (wrappedForSystem system)
        |> toModules
        |> builtins.mapAttrs (
          _: x:
            mkWrapper {
              inherit pkgs nixonArgs;
              modules = [x];
            }
        );
    };
  };
}
