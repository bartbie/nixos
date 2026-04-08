{
  flake.modules.hypr.io =
    {
      lib,
      nixonLib,
      hyprLib,
      config,
      ...
    }:
    let
      inherit (lib) types;
      inherit (nixonLib) dag;
      inherit (hyprLib) typed;
    in
    {
      options.land = {
        monitorv2 = typed (
          dag.appendOf (
            dag.dagConfigSubmodule {
              options.scale = typed types.numbers.positive;
              options.vrr = typed (
                hyprLib.namedEnumList [
                  "off"
                  "on"
                  "fullscreen"
                  "fullscreen-video-game"
                ]
              );
            }
          )
        );
        input.sensitivity = typed (types.numbers.between (-1) 1);
      };
      config = {
        hdr.enable = false;
        monitors = {
          primary = "DP-1";
          secondary = "HDMI-A-2";
        };
        land = {
          cursor.default_monitor = config.monitors.primary;
          monitorv2 =
            let
              mkMonitor =
                output: at:
                at |> builtins.mapAttrs (_: dag.entryAfter [ "output" ]) |> (x: x // { inherit output; });
            in
            [
              (mkMonitor config.monitors.primary {
                mode = "highres@highrr";
                position = "0x0";
                scale = 1.20;
                bitdepth = 10;
                vrr = "on";
              })
              (mkMonitor config.monitors.secondary {
                mode = "highres@highrr";
                position = "-1920x745";
                scale = 1;
              })
              # generic monitors if connected
              (mkMonitor "" {
                mode = "preferred";
                position = "auto";
                scale = 1;
              })
            ];
          input = lib.mkMerge [
            # kb
            {
              kb_layout = "pl";
              # kanata takes care of it, this kicks in if kanata is disabled
              kb_options = "caps:escape_shifted_capslock";
              repeat_rate = 33;
              repeat_delay = 133;
            }
            # mouse
            {
              accel_profile = "flat";
              sensitivity = 1;
            }
          ];
        };
      };
    };
}
