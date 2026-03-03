{ lib, ... }:
{
  flake.modules.hypr.apps =
    {
      config,
      hyprLib,
      pkgs,
      pkgs-unstable,
      self',
      ...
    }:
    let
      inherit (hyprLib) getExe typed;
      inherit (config) monitors;
    in
    {
      options =
        let
          inherit (lib) types;
        in
        {
          _programs = lib.mkOption {
            type = types.attrsOf (
              types.submodule (
                { config, ... }:
                {
                  options = {
                    package = typed types.pathInStore;
                    cmd = lib.mkOption {
                      type = types.nullOr (
                        types.oneOf [
                          types.str
                          (types.functionTo types.str)
                        ]
                      );
                      default = null;
                    };
                    toplevel = lib.mkOption {
                      type = types.str;
                      readOnly = true;
                      internal = true;
                    };
                  };
                  config.toplevel =
                    let
                      inherit (config) package cmd;
                      mkIf = t: lib.mkIf ((builtins.typeOf cmd) == t);
                    in
                    lib.mkMerge [
                      (lib.mkIf (cmd == null) (getExe package))
                      (mkIf "string" cmd)
                      # functionTo wraps it in a functor set...
                      (mkIf "set" (cmd package))
                    ];
                }
              )
            );
          };
          programs = lib.mkOption {
            type = types.attrsOf types.str;
            readOnly = true;
            internal = true;
          };
        };
      config.programs = config._programs |> builtins.mapAttrs (_: x: x.toplevel);
      config.runtimeInputs.land = config._programs |> builtins.attrValues |> builtins.map (x: x.package);

      ###

      config._programs = {
        clipboard.package = pkgs.clipse;
        browser.package = self'.packages.browser;
        terminal.package = self'.packages.alacritty;
        fileManager = {
          package = pkgs.kdePackages.dolphin;
          cmd = "dolphin";
        };
        menu = {
          package = pkgs.rofi;
          cmd =
            x:
            "${getExe x} -show combi -combi-modes drun,window,power_menu -run-command '${config.runCmd "{cmd}"}'";
        };
      };

      config.runOnStart =
        let
          inherit (config) programs;
        in
        [
          "${programs.clipboard} -listen"
          programs.terminal
        ];

      config.apps = [
        {
          name = "steam";
          slot = {
            key = "S";
            id = 99;
            monitor = monitors.primary;
          };
          windows = [
            { match.class = "^(steam)$"; }
          ];
        }
        {
          name = "discord";
          slot = {
            key = "D";
            id = 98;
            monitor = monitors.secondary;
            default = true;
          };
          windows = [
            { match.class = "(d|D)iscord"; }
            {
              name = "ignore-discord-updater-focus";
              match.class = "(d|D)iscord(.*)(u|U)pdater";
              no_initial_focus = true;
              suppress_event = "activatefocus";
            }
          ];
        }
        {
          name = "game";
          slot = {
            key = "G";
            id = 100;
            monitor = monitors.primary;
          };
          rules = [
            { content = "game"; }
            { fullscreen = lib.mkDefault true; }
          ];
          windows = [
            { match.class = "^(steam_app.*)$"; }
          ];
        }

        {
          name = "music";
          slot = {
            key = "M";
            id = 96;
            monitor = monitors.secondary;
          };
          windows = [
            # TODO: change
            { match.class = "spotify"; }
          ];
        }
        {
          name = "mail";
          slot = {
            key = "N";
            id = 97;
            monitor = monitors.primary;
          };
          windows = [
            { match.class = "thunderbird"; }
          ];
        }
      ];
    };
}
