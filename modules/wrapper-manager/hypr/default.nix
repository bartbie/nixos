{
  pkgs,
  lib,
  flake,
  overrideArgs,
  ...
} @ args: let
  config = pkgs.writeText "Hyprland-nixon.conf" (
    flake.lib.generators.toHyprconf {attrs = import ./hyprland-config.nix args;}
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
  nixon.standalonePackages = ["Hyprland"];
  nixon.overrideAttrs = {inherit (package) version;};
}
