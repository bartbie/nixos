{ lib, ... }:
{
  flake.modules.hypr.idle-config =
    { pkgs, ... }:
    let
      loginctl = "${pkgs.systemd}/bin/loginctl";
      systemctl = "${pkgs.systemd}/bin/systemctl";

      lockTimeout = 5 * 60;
      dpmsTimeout = 5 * 60;
    in
    {
      idle = {
        general = {
          # spawn hyprlock as its own user unit so it escapes hypridle's sandbox
          # (PAM auth needs real setuid + /etc/shadow, broken by PrivateUsers etc.)
          lock_cmd = "${systemctl} --user start hyprlock.service";
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
