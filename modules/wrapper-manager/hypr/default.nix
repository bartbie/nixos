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
  };
  basePackages = hypr.nixon-extraPackages;
  nixon.standalonePackages = ["Hyprland"];
  nixon.overrideAttrs = {inherit (package) version;};
}
