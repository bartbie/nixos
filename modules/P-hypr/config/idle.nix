{ lib, ... }:
{
  flake.modules.hypr.idle-config =
    { pkgs, ... }:
    let
      loginctl = "${pkgs.systemd}/bin/loginctl";

      lockTimeout = 5 * 60;
      dpmsTimeout = 5 * 60;
    in
    {
      idle = {
        general = {
          before_sleep_cmd = "${loginctl} lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
          ignore_dbus_inhibit = false;
          ignore_systemd_inhibit = false;
        };

        listener = [
          {
            timeout = lockTimeout;
            on-timeout = "${loginctl} lock-session";
          }
          {
            timeout = dpmsTimeout;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
        ];
      };
    };
}
