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

      screenshot =
        pkgs.writers.writeBashBin "screenshot"
          # bash
          ''
            set -euo pipefail
            mode="''${1:-copy}"
            target="''${2:-area}"
            if [ -d "$HOME/Eternal" ]; then
              dir="$HOME/Eternal/Pictures/screenshots"
            else
              dir="$HOME/Pictures/screenshots"
            fi
            mkdir -p "$dir"
            file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"
            case "$mode" in
              copy) ${lib.getExe pkgs.grimblast} --notify copy "$target" ;;
              save) ${lib.getExe pkgs.grimblast} --notify save "$target" "$file" ;;
              edit) ${lib.getExe pkgs.grimblast} --notify edit "$target" ;;
              *)    echo "screenshot: unknown mode '$mode'" >&2; exit 2 ;;
            esac
          '';

      inherit (config) programs;
    in
    {
      config = {
        mainMod = "SUPER";

        runtimeInputs.land = [
          exit-hypr
          screenshot
          pkgs.grimblast
          pkgs.swappy
        ];

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
            exec = {
              cmd = "${exit-hypr}/bin/exit-hypr";
              wrap = false;
            };
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
          # screenshots (kanata maps hyper+del -> print)
          {
            keys = "Print";
            exec = "${screenshot}/bin/screenshot copy area";
            altBehavior.exec = "${screenshot}/bin/screenshot edit area";
          }
          {
            mods = "SHIFT";
            keys = "Print";
            exec = "${screenshot}/bin/screenshot save area";
          }
          {
            mods = "CTRL";
            keys = "Print";
            exec = "${screenshot}/bin/screenshot save output";
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
