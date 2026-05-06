{
  flake.modules.hypr.env =
    {
      pkgs,
      pkgs-unstable,
      hyprLib,
      self',
      ...
    }:
    let
      inherit (hyprLib) getExe;

      inherit (self'.packages)
        rand-wp
        ;

      inherit (pkgs)
        swww
        ;

      notifs = getExe pkgs.swaynotificationcenter;
      statusbar = self'.packages.qkshell; # has own systemd service
      wallpaper = "${getExe swww}-daemon";

      runappLogged = pkgs.writeShellScript "runapp-logged" ''
        exec ${pkgs.systemd}/bin/systemd-cat --identifier=runapp-logged --stderr-priority=warning -- \
          ${getExe pkgs-unstable.runapp} -v "$@"
      '';
    in
    {
      runCmd = x: "${runappLogged} ${x}";

      runtimeInputs.land = [
        rand-wp
        swww
        statusbar
        pkgs-unstable.runapp
      ];

      runOnStart = [
        notifs
        "${wallpaper}"
        "${rand-wp}/bin/rand-wp --transition-step 255"
      ];

      land.exec-once = [
        "systemctl --user start hyprpolkitagent"
      ];
    };
}
