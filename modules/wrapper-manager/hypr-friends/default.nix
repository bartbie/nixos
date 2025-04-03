{
  pkgs,
  lib,
  flake,
  ...
} @ args: let
  writHyprConf = x:
    pkgs.writeText "${x}.conf" (
      flake.lib.generators.toHyprconf {attrs = import ./configs/${x}.nix args;}
    );
  pkg = pkgs.unstable.hyprland;
in {
  wrappers = {
  };

  nixon.standalonePackages = [];
}
