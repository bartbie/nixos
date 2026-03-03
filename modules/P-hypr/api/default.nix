{
  lib,
  nixonLib,
  config,
  ...
}:
let
  inherit (config) flake;
  inherit (lib) types;
  hyprLib = nixonLib.hypr;

  mkSubmodule = nixonLib.dag.submoduleTypeWith;
in
{
  flake.modules.hypr.base =
    { ... }:
    let
      mkHyprTopOption =
        opt:
        lib.mkOption (
          {
            type = mkSubmodule {
              dag = false;
              config = true;
            } { };
          }
          // opt
        );
    in
    {
      options = {
        out = lib.mkOption {
          type = types.listOf types.str;
          internal = true;
          readOnly = true;
          default = [
            "land"
            "lock"
          ];
        };
        land = mkHyprTopOption {
          description = "Hyprland config.";
          default = { };
        };
        lock = mkHyprTopOption {
          description = "Hyprlock config.";
          default = { };
        };
        runtimeInputs = lib.mkOption {
          type = lib.types.attrsOf (lib.types.listOf lib.types.package);
          default = { };
        };
      };

      config._module.args = { inherit hyprLib; };
    };

  flake.modules.hypr.api =
    { config, ... }:
    {
      options = {
        runOnStart = lib.mkOption {
          type = types.listOf types.str;
        };

        mainMod = lib.mkOption {
          type = types.uniq types.nonEmptyStr;
          apply = lib.toUpper;
        };

        runCmd = lib.mkOption {
          type = types.functionTo types.str;
        };

        monitors = {
          primary = lib.mkOption {
            type = types.uniq types.str;
          };
          secondary = lib.mkOption {
            type = types.uniq types.str;
            default = config.monitors.primary;
          };
        };

        layout = lib.mkOption {
          type = types.enum [
            "dwindle"
            "master"
            "scrolling"
            "monocle"
          ];
          default = "dwindle";
        };
      };

      config = {
        land = {
          general = { inherit (config) layout; };
          exec-once = config.runOnStart |> builtins.map (app: config.runCmd app);
        };
      };

      config.assertions = [
        {
          assertion =
            !(builtins.elem config.layout [
              "scrolling"
              "monocle"
            ]);
          message = "${config.layout} is not supported in this version, update";
        }
      ];
    };
}
