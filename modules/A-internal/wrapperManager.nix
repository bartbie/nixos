{
  lib,
  config,
  inputs,
  withSystem,
  nixonLib,
  ...
}:
let
  inherit (lib) types;

  wrappedSubmodule = lib.types.submodule {
    options = {
      enable = (lib.mkEnableOption "this wrapperManager module") // {
        default = true;
      };

      systems = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = config.systems;
      };

      tags = lib.mkOption {
        type = types.coercedTo (types.enum [ null ]) (_: [ "base" ]) (lib.types.listOf lib.types.str);
        default = [ "pc" ];
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

  mkWrapper =
    {
      modules,
      pkgs,
      nixonArgs,
    }:
    assert nixonArgs ? theme;
    assert nixonArgs ? pkgs-unstable;
    lib.makeOverridable (
      {
        extraWrapperModules ? [ ],
        ...
      }@overrideArgs:
      let
        result =
          (inputs.wrapper-manager.lib.eval {
            inherit pkgs;
            modules = lib.flatten [
              config.flake.modules.wrapperManager.base
              config.flake.modules.generic.meta
              # NOTE:
              # wrapper-manager already imports assertions from pgks.path
              modules
              extraWrapperModules
            ];
            specialArgs = withSystem pkgs.stdenv.hostPlatform.system (
              {
                self',
                inputs',
                system,
                ...
              }:
              {
                inherit
                  self'
                  inputs'
                  nixonArgs
                  ;
                overrideArgs = builtins.removeAttrs overrideArgs [ "extraWrapperModules" ];
              }
              // nixonArgs
            );
          }).config;
        cfg = builtins.removeAttrs result [ "assertions" ];
        overriden-1 = cfg.build.toplevel.override cfg.override;
        overriden-2 = overriden-1.overrideAttrs cfg.overrideAttrs;
        final = cfg.finalMapDrv overriden-2;
      in
      assert nixonLib.assertions.checkAssertions result.assertions;
      assert lib.isDerivation final;
      final
    ) { };
in
{
  options.wrapped = lib.mkOption {
    type = lib.types.lazyAttrsOf wrappedSubmodule;
    default = { };
    description = ''
      Set of modules defining package wrappers with attached respective metadata.
    '';
  };

  config =
    let
      wrapper-modules-attr =
        config.wrapped |> (x: builtins.removeAttrs x [ "base" ]) |> lib.filterAttrs (_: v: v.enable);

      wrappedForSystem =
        system: wrapper-modules-attr |> lib.filterAttrs (_: v: builtins.elem system v.systems);

      toModules = wrapped: wrapped |> builtins.mapAttrs (_: v: v.module);
    in
    {
      flake.modules.wrapperManager = toModules wrapper-modules-attr;

      flake.modules.nixos.pc =
        { inputs, system, ... }:
        {
          environment.systemPackages = inputs.wrapper-manager.devPackages.${system} |> builtins.attrValues;
        };
      packages.generic =
        let
          mkWrapperModForTag = (
            {
              tag,
              systems,
              module,
              module-name,
            }:
            let
              inner =
                {
                  pkgs,
                  nixonArgs,
                  system,
                  ...
                }:
                {
                  _file = __curPos.file;
                  config.add = lib.mkIf (builtins.elem system systems) [
                    (
                      (mkWrapper {
                        inherit pkgs nixonArgs;
                        modules = module;
                      }).override
                      {
                        extraWrapperModules = [
                          { locale.enable = lib.mkDefault false; }
                        ];
                      }
                    )
                  ];
                };
            in
            {
              key = "${module-name}-${tag}";
              _file = __curPos.file;
              imports = [ inner ];
            }
          );
        in
        wrapper-modules-attr
        # {name module}
        |> lib.mapAttrsToList (
          module-name:
          {
            module,
            tags,
            systems,
            ...
          }:
          lib.forEach tags (
            tag:
            lib.nameValuePair tag (mkWrapperModForTag {
              inherit
                tag
                systems
                module
                module-name
                ;
            })
          )
        )
        |> builtins.concatLists
        |> builtins.groupBy (x: x.name)
        |> builtins.mapAttrs (_: v: { imports = lib.getValues v; });

      perSystem =
        {
          pkgs,
          system,
          nixonArgs,
          ...
        }:
        {
          packages =
            (wrappedForSystem system)
            |> toModules
            |> builtins.mapAttrs (
              _: x:
              mkWrapper {
                inherit pkgs nixonArgs;
                modules = [ x ];
              }
            );
        };
    };
}
