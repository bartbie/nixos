{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.nixon.core;
in {
  imports = [
    ./base.nix
    ./net.nix
    ./audio.nix
    ./fonts.nix
    ./nix.nix

    ./packages.nix

    ./programs/cli.nix
    ./programs/starship.nix
    ./programs/direnv.nix
    ./programs/fish.nix
    ./programs/hypr.nix
    ./programs/plasma5.nix
    ./programs/tmux.nix
  ];
  options.nixon.core.enable = mkEnableOption "core";
  config.nixon = let
    tru = lib.mkDefault true;
    fal = lib.mkDefault false;
  in
    lib.mkIf cfg.enable
    {
      base.enable = tru;
      net.enable = tru;
      nix.enable = tru;
      audio.enable = tru;
      audio.bluetooth.enable = tru;
      fonts.enable = tru;
      packages.enable = tru;

      fish.enable = tru;
      direnv.enable = tru;
      zoxide.enable = tru;
      lsd.enable = tru;
      tmux.enable = tru;
      starship.enable = tru;

      plasma5.enable = tru;

      hypr.enable = fal;
    };
}
