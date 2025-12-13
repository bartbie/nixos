{
  lib,
  theme,
  ...
}: {
  flake.modules.hypr.ui = lib.mkMerge [
    ({hyprLib, ...}: let
      inherit (hyprLib) typed typedApply gradientType rgbType rgbaType fnStr;
    in {
      options.land = {
        general = {
          "col.active_border" = typed gradientType;
          "col.inactive_border" = typedApply rgbaType (s: s |> (lib.removePrefix "#") |> fnStr "rgba");
        };
        decoration.shadow.color = typedApply rgbType (s: s |> (lib.removePrefix "#") |> fnStr "rgb");
      };
      config = let
        inherit (theme) palette;
        alpha_vis = "ee";
        border_active_color = {
          topColor = palette.oniViolet + alpha_vis;
          bottomColor = palette.crystalBlue + alpha_vis;
          deg = 45;
        };
        border_inactive_color = palette.fujiGray + "aa";

        shadow_color = palette.sumiInk2;
      in {
        land = {
          env = [
            "XCURSOR_SIZE,24"
            "GDK_SCALE,2"
            "HYPRCURSOR_SIZE,24"
          ];
          general = {
            "col.active_border" = border_active_color;
            "col.inactive_border" = border_inactive_color;
          };
          decoration.shadow.color = shadow_color;
        };
      };
    })
    {
      land = {
        general = {
          gaps_in = 0;
          gaps_out = 0;
          border_size = 2;
          resize_on_border = true;
          hover_icon_on_border = true;
          allow_tearing = false;
        };
        misc = {
          disable_hyprland_logo = true;
          disable_autoreload = true;
          force_default_wallpaper = 0;
        };
        ecosystem = {
          no_update_news = true;
          no_donation_nag = true;
        };
        decoration = {
          rounding = 10;
          active_opacity = 1.0;
          inactive_opacity = 0.975;
          shadow = {
            enabled = true;
            range = 4;
            render_power = 3;
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
    }
  ];
}
