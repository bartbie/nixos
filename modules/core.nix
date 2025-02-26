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
in {
  imports = flake.lib.findImports ./core.nix [./default.nix];
  options.nixon.core.enable = mkEnableOption "core";
  config.nixon = let
    tru = lib.mkDefault true;
    fal = lib.mkDefault false;
  in
    lib.mkIf cfg.enable
    {
      base.enable = tru;
      users.enable = tru;
      net.enable = tru;
      nix.enable = tru;
      audio = {
        enable = tru;
        bluetooth.enable = tru;
      };
      fonts.enable = tru;
      packages.enable = tru;
      programs = {
        # git.enable = tru;
        fish.enable = tru;
        fish.enable_vi_mode = tru;
        direnv.enable = tru;
        zoxide.enable = tru;
        lsd.enable = tru;

        tmux.enable = fal;
        zellij.enable = tru;

        starship.enable = tru;
        firefox.enable = tru;

        plasma5.enable = tru;

        hypr.enable = fal;
      };
    };
}
