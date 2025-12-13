{
  lib,
  nixonLib,
  config,
  ...
}: let
  inherit (config) flake;
in {
  flake.modules.hypr.api-apps = {
    config,
    hyprLib,
    ...
  }: let
    inherit (lib) types;
    inherit (hyprLib) mkSubmodule;
  in {
    options.apps = lib.mkOption {
      default = [];
      type = types.listOf (types.submodule ({config, ...}: {
        imports = [flake.modules.generic.assertions];
        options = {
          name = lib.mkOption {
            type = types.nullOr types.str;
            default = null;
          };
          windows = lib.mkOption {
            type = types.listOf types.deferredModule;
            default = [];
          };

          rules = lib.mkOption {
            type = types.listOf types.deferredModule;
            default = [];
          };

          slot = lib.mkOption {
            description = "Workspace associated with unique keybind";
            default = null;
            type = types.nullOr (types.submodule {
              options = {
                key = lib.mkOption {type = types.str;};
                id = lib.mkOption {
                  type = types.ints.unsigned;
                };
                monitor = lib.mkOption {
                  type = types.nullOr types.str;
                  default = null;
                };
                default = lib.mkOption {
                  type = types.bool;
                  default = false;
                };
                extraRules = lib.mkOption {
                  type = types.deferredModule;
                  default = {};
                };
              };
            });
          };
        };
        config.assertions = [
          {
            assertion = (config.slot != null) -> (config.name != null);
            message = "Name is required when using slot.";
          }
        ];
      }));
    };
    config = let
      inherit (builtins) toString;
      inherit (config) apps;
      here = __curPos.file;
    in {
      assertions = nixonLib.assertions.propagateAssertions apps;

      windowRules =
        apps
        |> lib.imap0 (
          i: {
            name,
            windows,
            rules,
            slot,
            ...
          }:
            windows
            |> lib.imap0 (i: w: let
              _file = "${here}#windowRules@${name}#window[${toString i}]";
            in ({...}: {
              inherit _file;
              key = _file;
              imports = lib.flatten [
                (lib.setDefaultModuleLocation "${_file}.def" w)
                # global rules
                (
                  rules
                  |> lib.imap0 (j: r:
                    lib.setDefaultModuleLocation "${_file}.rules[${toString j}]" r)
                )
              ];
              config = lib.mkIf (slot != null) {
                name = lib.mkDefault "${name}-rule${toString i}";
                workspace = lib.mkDefault "name:${name}";
              };
            }))
        )
        |> lib.flatten;

      keybinds =
        apps
        |> builtins.map (
          {slot, ...}:
            lib.optional (slot != null) {
              useMainMod = true;
              keys = [slot.key];
              action = "workspace";
              args = slot.id;
              altBehavior = {
                action = "movetoworkspace";
                args = slot.id;
              };
            }
        )
        |> lib.flatten;

      workspaceRules =
        apps
        |> lib.imap0 (i: {
          slot,
          name,
          ...
        }: ({...}: {
          _file = "${here}#workspaceRules[${toString i}]";
          key = "${here}#workspaceRules[${toString i}]";
          imports = [
            (lib.setDefaultModuleLocation "${here}#workspaceRules[${toString i}].extraRules" slot.extraRules)
          ];
          config = lib.mkMerge [
            (builtins.removeAttrs slot ["extraRules" "id" "key" "name" "assertions"])
            {
              defaultName = name;
              match.goto.id = slot.id;
            }
          ];
        }));
    };
  };
}
