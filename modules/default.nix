{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkOption types;
  cfg = config.user.default;
in {
  imports = [
    ./core.nix
    ./net.nix
    ./audio.nix
    ./fonts.nix

    ./packages.nix

    ./programs/cli.nix
    ./programs/direnv.nix
    ./programs/fish.nix
    ./programs/hypr.nix
    ./programs/plasma5.nix
    ./programs/tmux.nix
  ];
  options.user = {
    default.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable default system configuration.";
    };
  };
  config = lib.mkIf cfg.enable {
    user = let
      tru = lib.mkDefault true;
      fal = lib.mkDefault false;
    in {
      core.enable = tru;
      net.enable = tru;
      audio.enable = tru;
      audio.bluetooth.enable = tru;
      fonts.enable = tru;
      packages.enable = tru;

      fish.enable = tru;
      direnv.enable = tru;
      zoxide.enable = tru;
      lsd.enable = tru;
      tmux.enable = tru;

      plasma5.enable = tru;

      hypr.enable = fal;
    };
  };
}
