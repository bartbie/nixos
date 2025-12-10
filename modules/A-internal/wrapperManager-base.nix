{lib, ...}: let
  inherit (lib) types;

  getExe = x:
    assert x ? meta;
    assert x.meta ? mainProgram;
      lib.getExe' x x.meta.mainProgram;
in {
  flake.modules.wrapperManager.base = {
    config,
    options,
    pkgs,
    pkgs-unstable,
    ...
  }: {
    imports = [
      (lib.mkAliasOptionModule ["drvName"] ["build" "drvName"])
      {
        options.single = lib.mkOption {
          default = null;
          type = types.nullOr (types.submodule {
            options = {
              package = lib.mkOption {
                type = types.package;
              };
              wrapper = lib.mkOption {
                type = types.deferredModule;
                default = {};
              };
              symlinkPackage = lib.mkOption {
                type = types.bool;
                default = false;
              };
              name = lib.mkOption {
                type = types.str;
                default = lib.getName config.single.package;
              };
            };
          });
        };
        config = let
          cfg = config.single;
          drv = cfg.package;
        in
          lib.mkIf (config.single != null) {
            build = {
              drvName = cfg.name;
              extraPassthru = drv.passthru;
              extraMeta =
                drv.meta
                // {
                  mainProgram = cfg.name;
                  maintainer = config.meta.owner.username;
                };
              extraSetup =
                drv.outputs
                |> builtins.filter (x: !(builtins.elem x ["out" "bin"]))
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
            wrappers.${cfg.name} = {...}: {
              imports = [cfg.wrapper];
              arg0 = lib.mkDefault (getExe drv);
            };
            packagesToSymlink = lib.mkIf (cfg.symlinkPackage) [drv];
            overrideAttrs = lib.mkMerge [
              (lib.mkIf (drv ? version) {
                inherit (drv) version;
              })
              {
                outputs =
                  [drv.outputs "out"]
                  |> lib.flatten
                  # TODO: after update switch stable lib
                  |> pkgs-unstable.lib.lists.uniqueStrings;
              }
            ];
          };
      }
    ];
    options = let
      oattrs = types.lazyAttrsOf types.anything;
      overrideType = types.coercedTo oattrs lib.const (types.functionTo oattrs);
    in {
      override = lib.mkOption {
        type = overrideType;
        default = {};
        description = ''
          Add extra custom override to build pipeline.
        '';
      };
      overrideAttrs = lib.mkOption {
        type = overrideType;
        default = {};
        description = ''
          Add extra custom overrideAttrs to build pipeline.
          You can only return a one-arg function or attrset.
        '';
      };
      packagesToSymlink = lib.mkOption {
        type = types.listOf types.package;
        description = ''
          Packages to be symlinked in the wrapper package.
        '';
        default = [];
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
          wrapperConfig = config;
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
