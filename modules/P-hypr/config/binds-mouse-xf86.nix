{lib, ...}: {
  flake.modules.hypr.binds-mouse.keybinds = lib.flatten [
    # scroll workspace
    (
      {
        "mouse_down" = "+1";
        "mouse_up" = "-1";
      }
      |> lib.mapAttrsToList (key: arg: {
        useMainMod = false;
        keys = key;
        action = "workspace";
        args = arg;
      })
    )
    # mouse drag binds
    (
      {
        "mouse:272" = "movewindow";
        "mouse:273" = "resizewindow";
      }
      |> lib.mapAttrsToList (key: action: {
        flags = "m";
        keys = key;
        inherit action;
      })
    )
  ];
  flake.modules.hypr.binds-xf86.keybinds = lib.flatten [
    # volume raise/lower (repeatable + locked)
    (
      {
        "XF86AudioRaiseVolume" = "set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+";
        "XF86AudioLowerVolume" = "set-volume @DEFAULT_AUDIO_SINK@ 5%-";
      }
      |> lib.mapAttrsToList (key: cmd: {
        useMainMod = false;
        flags = ["e" "l"];
        keys = key;
        exec = "wpctl ${cmd}";
      })
    )
    # mute toggles (locked only)
    (
      {
        "XF86AudioMute" = "set-mute @DEFAULT_AUDIO_SINK@ toggle";
        "XF86AudioMicMute" = "set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
      }
      |> lib.mapAttrsToList (key: cmd: {
        useMainMod = false;
        flags = "l";
        keys = key;
        exec = "wpctl ${cmd}";
      })
    )
    # playerctl (locked only)
    (
      {
        "XF86AudioNext" = "next";
        "XF86AudioPause" = "play-pause";
        "XF86AudioPlay" = "play-pause";
        "XF86AudioPrev" = "previous";
      }
      |> lib.mapAttrsToList (key: cmd: {
        useMainMod = false;
        flags = "l";
        keys = key;
        exec = "playerctl ${cmd}";
      })
    )
  ];
}
