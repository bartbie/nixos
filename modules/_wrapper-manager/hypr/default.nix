{
  pkgs,
  lib,
  flake,
  overrideArgs,
  ...
} @ args: let
  hypr = import ./hyprland-config.nix args;
  config = pkgs.writeText "Hyprland-nixon.conf" (
    flake.lib.generators.toHyprconf {attrs = builtins.removeAttrs hypr ["nixon-extraPackages"];}
  );

  package = pkgs.unstable.hyprland.override overrideArgs;
in {
  wrappers = {
    Hyprland = {
      arg0 = lib.getExe' package "Hyprland";
      prependArgs = [
        "--config"
        "${config}"
      ];
    };
    # lol
    hyprctl = {
      arg0 = lib.getExe' package "hyprctl";
    };
  };
  basePackages = hypr.nixon-extraPackages;
  nixon.standalonePackages = ["Hyprland" "hyprctl"];
  nixon.overrideAttrs = {inherit (package) version;};
  nixon.enable = !pkgs.stdenv.isDarwin;
}
