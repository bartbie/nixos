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
        waybar
        rand-wp
        ;

      inherit (pkgs)
        swww
        ;

      notifs = getExe pkgs.swaynotificationcenter;
      statusbar = getExe waybar;
      wallpaper = "${getExe swww}-daemon";
    in
    {
      runCmd = x: "${getExe pkgs-unstable.runapp} ${x}";

      runtimeInputs.land = [
        waybar
        rand-wp
        swww
        pkgs-unstable.runapp
      ];

      runOnStart = [
        notifs
        statusbar
        "${wallpaper}"
        "${rand-wp}/bin/rand-wp --transition-step 255"
      ];

      land.exec-once = [
        "systemctl --user start hyprpolkitagent"
      ];
    };
}
