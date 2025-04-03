{
  pkgs,
  lib,
  flake,
  ...
}: let
  exes = flake.lib.pkgh.getExeAttrsFlat pkgs {
    dolphin = "dolphin";
    swaynotificationcenter = "swaync";
    wofi = "wofi";
    nixon = {
      alacritty = "alacritty";
      clipse = "clipse";
      waybar = "waybar";
    };
  };

  fileManager = exes.dolphin;
  notifs = exes.swaynotificationcenter;
  menu = "${exes.wofi} --show drun";
  terminal = exes.alacritty;
  clipboard = exes.clipse;
  statusbar = exes.waybar;

  mainMod = "SUPER";
in {
  exec-once = [
    "${clipboard} -listen"
    notifs
    terminal
    statusbar
    #   "nm-applet &"
    #   "waybar & hyprpaper & firefox"
  ];

  env = [
    "XCURSOR_SIZE,24"
    "HYPRCURSOR_SIZE,24"
  ];

  general = {
    gaps_in = 0;
    gaps_out = 0;
    border_size = 1;
    # TODO set colors here;
    "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
    "col.inactive_border" = "rgba(595959aa)";
    resize_on_border = true;
    hover_icon_on_border = true;
    allow_tearing = false;
    layout = "dwindle";
    no_focus_fallback = true;
  };

  dwindle = {
    pseudotile = true;
    preserve_split = true;
  };

  misc = {
    disable_autoreload = true;
    force_default_wallpaper = 0;
  };

  monitor = [
    ", highres@highrr, auto, 1.20"
  ];

  input = {
    kb_layout = "pl";
    kb_options = "caps:escape_shifted_capslock";
    repeat_rate = 33;
    repeat_delay = 133;

    accel_profile = "flat";
    sensitivity = 0.9; # -1.0 - 1.0, 0 means no modification.

    follow_mouse = 1;

    touchpad = {
      # macbook-like
      natural_scroll = true;
      clickfinger_behavior = true;
    };
  };

  gestures = {
    workspace_swipe = true;
  };

  ecosystem = {
    no_update_news = true;
    no_donation_nag = true;
  };

  binds = [
  ];
  bind = [
    "${mainMod}, h, movefocus, l"
    "${mainMod}, l, movefocus, r"
    "${mainMod}, k, movefocus, u"
    "${mainMod}, j, movefocus, d"

    "${mainMod} ALT, h, movewindow, l"
    "${mainMod} ALT, l, movewindow, r"
    "${mainMod} ALT, k, movewindow, u"
    "${mainMod} ALT, j, movewindow, d"

    "${mainMod} CTRL, h, resizeactive, -10 0"
    "${mainMod} CTRL, l, resizeactive, 10 0"
    "${mainMod} CTRL, k, resizeactive, 0 -10"
    "${mainMod} CTRL, j, resizeactive, 0 10"

    "${mainMod}, F, fullscreen, 1"
    "${mainMod} ALT, F, fullscreen, 0"

    "${mainMod}, bracketleft, workspace, e-1"
    "${mainMod}, bracketright, workspace, e+1"

    "${mainMod} ALT, Q, exec, ${terminal}"

    "${mainMod} ALT, BACKSPACE, killactive,"

    "${mainMod} ALT, M, exit,"

    "${mainMod}, T, togglefloating,"
    "${mainMod}, P, pseudo,"
    "${mainMod}, I, togglesplit," # dwindle

    # Open clipboard manager
    "${mainMod}, V, exec, ${terminal} --class clipse -e ${clipboard}"

    # Switch workspaces with mainMod + [0-9]
    "${mainMod}, 1, workspace, 1"
    "${mainMod}, 2, workspace, 2"
    "${mainMod}, 3, workspace, 3"
    "${mainMod}, 4, workspace, 4"
    "${mainMod}, 5, workspace, 5"
    "${mainMod}, 6, workspace, 6"
    "${mainMod}, 7, workspace, 7"
    "${mainMod}, 8, workspace, 8"
    "${mainMod}, 9, workspace, 9"
    "${mainMod}, 0, workspace, 10"

    # Move active window to a workspace with mainMod + SHIFT + [0-9]
    "${mainMod} ALT, 1, movetoworkspacesilent, 1"
    "${mainMod} ALT, 2, movetoworkspacesilent, 2"
    "${mainMod} ALT, 3, movetoworkspacesilent, 3"
    "${mainMod} ALT, 4, movetoworkspacesilent, 4"
    "${mainMod} ALT, 5, movetoworkspacesilent, 5"
    "${mainMod} ALT, 6, movetoworkspacesilent, 6"
    "${mainMod} ALT, 7, movetoworkspacesilent, 7"
    "${mainMod} ALT, 8, movetoworkspacesilent, 8"
    "${mainMod} ALT, 9, movetoworkspacesilent, 9"
    "${mainMod} ALT, 0, movetoworkspacesilent, 10"

    # Example special workspace (scratchpad)
    "${mainMod}, S, togglespecialworkspace, magic"
    "${mainMod} ALT, S, movetoworkspace, special:magic"

    # Scroll through existing workspaces with mainMod + scroll
    "${mainMod}, mouse_down, workspace, +1"
    "${mainMod}, mouse_up, workspace, -1"
  ];
  bindm = [
    # Move/resize windows with mainMod + LMB/RMB and dragging
    "${mainMod}, mouse:272, movewindow"
    "${mainMod}, mouse:273, resizewindow"
  ];
  bindel = [
    # Laptop multimedia keys for volume and LCD brightness
    ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
    ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
    ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
    ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
    ",XF86MonBrightnessUp, exec, brightnessctl s 10%+"
    ",XF86MonBrightnessDown, exec, brightnessctl s 10%-"
  ];
  bindl = [
    # Requires playerctl
    ", XF86AudioNext, exec, playerctl next"
    ", XF86AudioPause, exec, playerctl play-pause"
    ", XF86AudioPlay, exec, playerctl play-pause"
    ", XF86AudioPrev, exec, playerctl previous"
  ];
  windowrule = [
    # Ignore maximize requests from apps. You'll probably like this.
    "suppressevent maximize, class:.*"

    # Fix some dragging issues with XWayland
    "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
  ];
  windowrulev2 = [
    "float, class:(clipse)"
    "size 622 652, class:(clipse)"
    "stayfocused, class:(clipse)"
  ];

  decoration = {
    rounding = 10;
    active_opacity = 1.0;
    inactive_opacity = 0.975;

    shadow = {
      enabled = true;
      range = 4;
      render_power = 3;
      # TODO set colors here
      color = "rgba(1a1a1aee)";
    };

    blur = {
      enabled = true;
      size = 3;
      passes = 1;

      vibrancy = 0.1696;
    };
  };

  animations = {
    enabled = false;
  };
}
