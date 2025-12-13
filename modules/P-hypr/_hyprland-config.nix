{
  pkgs,
  lib,
  kdePackages,
  swaynotificationcenter,
  rofi,
  alacritty,
  clipse,
  waybar,
  swww,
  nixonLib,
  rand-wp,
  theme,
}: let
  inherit (theme) palette;
  fn_str = name: arg: "${name}(${arg})";

  join_sp = lib.join " ";
  join_cm = lib.join ",";

  rgb_hex = val: let
    normalized = builtins.replaceStrings ["#"] [""] val;
    len = builtins.stringLength normalized;
  in
    assert len == 6; fn_str "rgb" normalized;

  rgba_hex = val: let
    normalized = builtins.replaceStrings ["#"] [""] val;
    len = builtins.stringLength normalized;
  in
    assert len == 8; fn_str "rgba" normalized;

  rgba_hex_alpha = val: alpha: let
    normalized = builtins.replaceStrings ["#"] [""] val;
    len = builtins.stringLength normalized;
  in
    assert len == 6;
    assert builtins.stringLength alpha == 2;
      fn_str "rgba" (normalized + alpha);

  deg = num:
    assert num >= 0; "${builtins.toString num}deg";

  # extra bins to package with in env
  getExe = x:
    assert x ? meta;
    assert x.meta ? mainProgram;
      lib.getExe' x x.meta.mainProgram;

  hjkl-ldur = let
    mapping = {
      h = "l";
      j = "d";
      k = "u";
      l = "r";
    };
  in
    fn: lib.mapAttrsToList fn mapping;

  mapRange = from: to: fn: lib.range from to |> builtins.map fn;

  mapRow = fn: mapRange 1 10 (n: fn (lib.mod 10 n) n);

  alpha_vis = "ee";

  shadow_color = rgb_hex palette.sumiInk2;
  border_active_color = join_sp [(rgba_hex_alpha palette.oniViolet alpha_vis) (rgba_hex_alpha palette.crystalBlue alpha_vis) (deg 45)];
  border_inactive_color = rgba_hex_alpha palette.fujiGray "aa";

  notifs = getExe swaynotificationcenter;
  statusbar = getExe waybar;
  wallpaper = getExe swww;

  menu = "${getExe rofi} -show combi -combi-modes drun,window,power_menu";
  clipboard = getExe clipse;
  terminal = getExe alacritty;
  fileManager = lib.getExe' kdePackages.dolphin "dolphin"; # doesn't have mainProgram set
  browser = "xdg-open 'http://'";

  mainMod = "SUPER";
  config = {
    exec-once = [
      "${clipboard} -listen"
      notifs
      terminal
      statusbar
      "${wallpaper} & ${rand-wp}/bin/rand-wp"
      "systemctl --user start hyprpolkitagent"
    ];

    env = [
      "XCURSOR_SIZE,24"
      "GDK_SCALE,2"
      "HYPRCURSOR_SIZE,24"
    ];

    general = {
      gaps_in = 0;
      gaps_out = 0;
      border_size = 1;
      "col.active_border" = border_active_color;
      "col.inactive_border" = border_inactive_color;
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
      new_window_takes_over_fullscreen = 2;
    };

    xwayland = {
      force_zero_scaling = true;
    };

    monitor = [
      "DP-4, highres@highrr, 0x0, 1.20"
      "HDMI-A-3, highres@highrr, -1920x745"
      ", preferred, auto, 1"
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

    ecosystem = {
      no_update_news = true;
      no_donation_nag = true;
    };

    binds = {
      allow_workspace_cycles = true;
    };

    gestures = [
      "3, horizontal, workspace"
    ];

    binde = [
      "${mainMod} CTRL, h, resizeactive, -10 0"
      "${mainMod} CTRL, l, resizeactive, 10 0"
      "${mainMod} CTRL, k, resizeactive, 0 -10"
      "${mainMod} CTRL, j, resizeactive, 0 10"
    ];

    bind = builtins.concatLists [
      (hjkl-ldur (k: d: "${mainMod}, ${k}, movefocus, ${d}"))
      (hjkl-ldur (k: d: "${mainMod} ALT, ${k}, movewindow, ${d}"))

      "${mainMod}, F, fullscreen, 1"
      "${mainMod} ALT, F, fullscreen, 0"

      "${mainMod}, bracketleft, workspace, e-1"
      "${mainMod}, bracketright, workspace, e+1"

      # what more do you need
      "${mainMod}, Q, exec, ${terminal}"
      "${mainMod}, W, exec, ${browser}"
      "${mainMod}, E, exec, ${fileManager}"

      "${mainMod}, BACKSPACE, killactive,"
      "${mainMod} ALT, BACKSPACE, forcekillactive,"

      # TODO: replace with script that handles uwsm
      "${mainMod} ALT, M, exit,"

      "${mainMod}, T, togglefloating,"

      "${mainMod}, I, togglesplit," # dwindle

      "${mainMod}, TAB, workspace, previous"

      # Open clipboard manager
      "${mainMod}, V, exec, ${terminal} --class clipse -e ${clipboard}"

      # menu
      "${mainMod}, SPACE, exec, ${menu}"

      # Switch workspaces with mainMod + [0-9]
      (mapRow (
        k: n: "${mainMod}, ${builtins.toString k}, workspace, ${builtins.toString n}"
      ))
      # Move active window to a workspace with mainMod + SHIFT + [0-9]
      (mapRow (
        k: n: "${mainMod} ALT, ${builtins.toString k}, movetoworkspacesilent, ${builtins.toString n}"
      ))

      # game workspace
      "${mainMod}, G, workspace, name:game"

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
    workspace = [
      "100, defaultName:game"
    ];
    windowrule = [
      # Ignore maximize requests from apps. You'll probably like this.
      "suppressevent maximize, class:.*"
      # Fix some dragging issues with XWayland
      "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
      # send games to their workspace and maximize them
      "workspace name:game, class:^(steam_app.*)$"
      "fullscreen, class:^(steam_app.*)$"
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
        color = shadow_color;
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
  };
in
  (pkgs.writeText "Hyprland-nixon.conf" (nixonLib.generators.toHyprconf {attrs = config;})).overrideAttrs (prev: {
    passthru = lib.recursiveUpdate prev.passthru {
      runtimeInputs = [
        kdePackages.dolphin
        swaynotificationcenter
        rofi
        alacritty
        clipse
        waybar
        swww
        rand-wp
      ];
    };
  })
