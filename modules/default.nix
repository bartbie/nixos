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
    ./programs/fish.nix
    ./programs/hypr.nix
    ./programs/plasma5.nix
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
      fish.enable = tru;
      plasma5.enable = tru;

      hypr.enable = fal;
    };
  };
}
