{ lib, ... }:
let
  inherit (lib) types;

  getExe =
    x:
    assert x ? meta;
    assert x.meta ? mainProgram;
    lib.getExe' x x.meta.mainProgram;
in
{
  flake.modules.wrapperManager.base =
    {
      config,
      options,
      pkgs,
      pkgs-unstable,
      ...
    }:
    {
      imports = [
        (lib.mkAliasOptionModule [ "drvName" ] [ "build" "drvName" ])
        {
          options.single = lib.mkOption {
            default = null;
            type = types.nullOr (
              types.submodule {
                options = {
                  package = lib.mkOption {
                    type = types.package;
                    description = ''
                      Base package to wrap.
                    '';
                  };
                  wrapper = lib.mkOption {
                    type = types.deferredModule;
                    default = { };
                    description = ''
                      WrapperManager-fds module defining wrapper's options
                    '';
                  };
                  symlinkPackage = lib.mkOption {
                    type = types.bool;
                    default = false;
                    description = ''
                      Whether to symlink base package
                    '';
                  };
                  drvName = lib.mkOption {
                    type = types.str;
                    default = "${lib.getName config.single.package}-${config.single.programName}";
                    description = ''
                      Name of the derivation.
                    '';
                  };
                  programName = lib.mkOption {
                    type = types.str;
                    default = config.single.package.meta.mainProgram;
                    # or throw "${config.single.drvName}' base package has no meta.mainProgram set!";
                    description = ''
                      Filename wrapper will be under.
                    '';
                  };
                  # TODO: fun api for declaring which files to copy
                  # perOutputSymlink = lib.mkOption {
                  #   type = let
                  #     infAttrsOfStr = lib.mkOptionType {
                  #       name = "infinitely-deep-attrsOf-str";
                  #       check = builtins.isAttrs;
                  #       merge = loc: defs: let
                  #         # Returns the common type of all definitions, throws an error if they
                  #         # don't have the same type
                  #         commonType =
                  #           builtins.foldl' (
                  #             type: def:
                  #               if builtins.typeOf def.value == type
                  #               then type
                  #               else
                  #                 throw "The option `${lib.options.showOption loc}' has conflicting option types:${lib.options.showDefs [
                  #                   (builtins.head defs)
                  #                   def
                  #                 ]}\n"
                  #           ) (builtins.typeOf (builtins.head defs).value)
                  #           defs;
                  #
                  #         mergeFunction =
                  #           if commonType == "set"
                  #           then (types.attrsOf infAttrsOfStr).merge
                  #           else types.str.merge;
                  #       in
                  #         mergeFunction loc defs;
                  #     };
                  #   in
                  #     types.attrsOf infAttrsOfStr;
                  #
                  #   description = ''
                  #     Base package to wrap.
                  #   '';
                  # };
                };
              }
            );
          };
          config =
            let
              cfg = config.single;
              drv = cfg.package;
            in
            lib.mkIf (cfg != null) (
              lib.mkMerge [
                {
                  build = {
                    inherit (cfg) drvName;
                    extraMeta = drv.meta // {
                      mainProgram = cfg.programName;
                      maintainer = config.meta.owner.username;
                    };
                    extraPassthru = drv.passthru;
                  };
                  wrappers.${cfg.programName} =
                    { ... }:
                    {
                      imports = [ cfg.wrapper ];
                      arg0 = lib.mkDefault (getExe drv);
                    };
                }
                {
                  overrideAttrs = lib.mkMerge [
                    (lib.mkIf (drv ? version) {
                      inherit (drv) version;
                    })
                    {
                      outputs =
                        [
                          "out"
                          drv.outputs
                        ]
                        |> lib.flatten
                        |> lib.lists.unique;
                    }
                  ];
                }
                {
                  build = {
                    extraSetup =
                      drv.outputs
                      |> builtins.filter (
                        x:
                        !(builtins.elem x [
                          "out"
                          "bin"
                        ])
                      )
                      |> lib.concatMapStringsSep "\n" (output:
                      #sh
                      ''
                        # Symlink everything from original output
                        if [ -d "${drv.${output}}" ]; then
                          echo "Symlinking ${output}"
                          set -x
                          cp -rs --no-preserve=mode "${drv.${output}}" "''${${output}}" || {
                            set +x
                            echo "Failed to symlink ${output}" >&2
                            exit 1
                          }
                          set +x
                        else
                          echo "Warning: ${output} output not found" >&2
                        fi
                      '');
                  };
                  packagesToSymlink = lib.mkIf (cfg.symlinkPackage) [ drv ];
                }
              ]
            );
        }
      ];
      options =
        let
          oattrs = types.lazyAttrsOf types.anything;
          overrideType = types.coercedTo oattrs lib.const (types.functionTo oattrs);
        in
        {
          override = lib.mkOption {
            type = overrideType;
            default = { };
            description = ''
              Add extra custom override to build pipeline.
            '';
          };
          overrideAttrs = lib.mkOption {
            type = overrideType;
            default = { };
            description = ''
              Add extra custom overrideAttrs to build pipeline.
              You can only return a one-arg function or attrset.
            '';
          };
          finalMapDrv = lib.mkOption {
            type = types.functionTo (types.pathInStore);
            default = x: x;
            description = ''
              Add extra custom mapping of derivation to build pipeline.
              Prefer to use override instead if possible.
              You can only return a one-arg function.
            '';
          };
          packagesToSymlink = lib.mkOption {
            type = types.listOf types.package;
            description = ''
              Packages to be symlinked in the wrapper package.
            '';
            default = [ ];
            example = lib.literalExpression ''
              with pkgs; [
                yt-dlp
              ]
            '';
          };
        };
      config = {
        locale.enable = lib.mkForce (!pkgs.stdenv.isDarwin);
        build = lib.mkIf (builtins.isList config.basePackages) {
          extraPassthru = {
            wrapperConfig = builtins.removeAttrs config [ "_module" ];
            inherit (config) basePackages packagesToSymlink;
          };
          extraSetup =
            config.packagesToSymlink
            |> lib.concatMapStringsSep "\n" (
              pkg:
              pkg.outputs
              |> lib.concatMapStringsSep "\n" (output:
              #sh
              ''
                # Symlink everything from original output of ${pkg.name}
                if [ -d "${pkg.${output}}" ]; then
                  echo "Symlinking ${output}"
                  set -x
                  cp -rs --no-preserve=mode "${pkg.${output}}" "''${${output}}" || {
                    set +x
                    echo "Failed to symlink ${output}" >&2
                    exit 1
                  }
                  set +x
                else
                  echo "Warning: ${output} output not found" >&2
                fi
              '')
            );
        };
      };
    };
}
