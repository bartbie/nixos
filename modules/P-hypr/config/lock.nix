{
  lib,
  theme,
  ...
}:
{
  flake.modules.hypr.lock-config =
    { ... }:
    let
      inherit (theme) palette;
      rgb = s: "rgb(${lib.removePrefix "#" s})";
      rgba = a: s: "rgba(${lib.removePrefix "#" s}${a})";
    in
    {
      lock = {
        "$bg" = rgb palette.sumiInk1;
        "$fg" = rgb palette.fujiWhite;
        "$muted" = rgb palette.fujiGray;
        "$accent" = rgb palette.oniViolet;
        "$accent2" = rgb palette.crystalBlue;
        "$wrong" = rgb palette.peachRed;
        "$check" = rgb palette.carpYellow;

        general = {
          hide_cursor = true;
          grace = 0;
          no_fade_in = false;
          no_fade_out = false;
          ignore_empty_input = true;
          disable_loading_bar = true;
          immediate_render = true;
        };

        background = [
          {
            monitor = "";
            path = "screenshot";
            blur_passes = 3;
            blur_size = 8;
            noise = "0.0117";
            contrast = "0.9";
            brightness = "0.55";
            vibrancy = "0.17";
            vibrancy_darkness = "0.0";
          }
        ];

        input-field = [
          {
            monitor = "";
            size = "320, 60";
            outline_thickness = 2;
            dots_size = "0.25";
            dots_spacing = "0.30";
            dots_center = true;
            dots_rounding = -1;
            outer_color = "$accent";
            inner_color = rgba "cc" palette.sumiInk1;
            font_color = "$fg";
            fade_on_empty = false;
            placeholder_text = "<i>password</i>";
            hide_input = false;
            check_color = "$check";
            fail_color = "$wrong";
            fail_text = "<i>$FAIL <b>($ATTEMPTS)</b></i>";
            capslock_color = "$accent2";
            numlock_color = -1;
            bothlock_color = -1;
            invert_numlock = false;
            swap_font_color = false;
            rounding = 8;
            position = "0, -120";
            halign = "center";
            valign = "center";
          }
        ];

        label = [
          {
            monitor = "";
            text = "cmd[update:30000] date +\"%H:%M\"";
            color = "$fg";
            font_size = 120;
            position = "0, 220";
            halign = "center";
            valign = "center";
          }
          {
            monitor = "";
            text = "cmd[update:60000] date +\"%A, %B %-d\"";
            color = "$muted";
            font_size = 22;
            position = "0, 120";
            halign = "center";
            valign = "center";
          }
          {
            monitor = "";
            text = "cmd[once] whoami";
            color = "$muted";
            font_size = 16;
            position = "0, -40";
            halign = "center";
            valign = "center";
          }
        ];
      };
    };
}
