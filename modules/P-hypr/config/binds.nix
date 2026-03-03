{ lib, ... }:
{
  flake.modules.hypr.binds =
    {
      config,
      pkgs,
      pkgs-unstable,
      hyprLib,
      self',
      ...
    }:
    let
      inherit (hyprLib) mapRow;
      exit-hypr =
        pkgs.writers.writeBashBin "exit-hypr"
          # bash
          ''
            if uwsm check is-active; then
              uwsm stop
            else
              hyprctl dispatch exit
            fi
          '';

      inherit (config) programs;
    in
    {
      config = {
        mainMod = "SUPER";

        runtimeInputs.land = [ exit-hypr ];

        keybinds = lib.flatten [
          # focus movement / window movement (ALT)
          (hyprLib.hjkl-ldur (
            k: d: {
              flags = "e";
              keys = k;
              action = "movefocus";
              args = d;
              altBehavior = {
                action = "movewindow";
                args = d;
              };
            }
          ))
          # resize active window
          (
            {
              "h" = "-10 0";
              "l" = "10 0";
              "k" = "0 -10";
              "j" = "0 10";
            }
            |> lib.mapAttrsToList (
              k: v: {
                flags = "e";
                mods = "CTRL";
                keys = k;
                action = "resizeactive";
                args = v;
              }
            )
          )
          # fullscreen
          {
            keys = "F";
            action = "fullscreen";
            args = 1;
            altBehavior = {
              action = "fullscreen";
              args = 0;
            };
          }
          # window management
          {
            keys = "BACKSPACE";
            action = "killactive";
            altBehavior.action = "forcekillactive";
          }

          {
            mods = "ALT";
            keys = "slash";
            exec = "${exit-hypr}/bin/exit-hypr";
          }

          {
            keys = "T";
            action = "togglefloating";
          }

          (lib.optional (config.layout == "dwindle") {
            keys = "apostrophe";
            action = "togglesplit";
          })

          {
            keys = "V";
            exec = "${programs.terminal} --class clipse -e ${programs.clipboard}";
          }
          # workspace switching / move window to workspace silently (ALT)
          (mapRow (
            k: n: {
              keys = builtins.toString k;
              action = "workspace";
              args = builtins.toString n;
              altBehavior = {
                action = "movetoworkspacesilent";
                args = builtins.toString n;
              };
            }
          ))
          # launchers
          (
            {
              "SPACE" = programs.menu;
              "Q" = programs.terminal;
              "W" = programs.browser;
              "E" = programs.fileManager;
            }
            |> lib.mapAttrsToList (
              key: cmd: {
                keys = key;
                exec = cmd;
              }
            )
          )
          # special workspace (scratchpad)
          {
            keys = "minus";
            action = "togglespecialworkspace";
            args = "magic";
            altBehavior = {
              action = "movetoworkspace";
              args = "special:magic";
            };
          }
          # bracket workspace navigation
          (
            {
              "bracketleft" = "e-1";
              "bracketright" = "e+1";
            }
            |> lib.mapAttrsToList (
              key: arg: {
                keys = key;
                action = "workspace";
                args = arg;
              }
            )
          )
        ];
      };
    };
}
