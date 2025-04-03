{
  flake,
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.nixon.core;
  tru = lib.mkDefault true;
  fal = lib.mkDefault false;
in {
  imports = flake.lib.findImports ./core.nix [./default.nix];
  options.nixon.core.enable = mkEnableOption "core";
  config.nixon = lib.mkIf cfg.enable {
    base.enable = tru;
    audio = {
      enable = tru;
      bluetooth.enable = tru;
    };
    boot.enable = tru;
    fonts.enable = tru;
    net.enable = tru;
    nix.enable = tru;
    ssh.enable = tru;
    users.enable = tru;
    wayland.enable = tru;

    packages.enable = tru;

    programs = {
      fish.enable = tru;
      firefox.enable = tru;
      plasma5.enable = fal;
      hypr.enable = tru;
    };
  };
}
