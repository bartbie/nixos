{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkOption types;
  cfg = config.user.net;
in {
  options.user.net = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable net system configuration.";
    };
  };
  config = lib.mkIf cfg.enable {
    networking.networkmanager.enable = true;
    firewall = {
      enable = true;
      allowPing = false;
      logReversePathDrops = true;
    };
    # slows down boot time
    systemd.services.NetworkManager-wait-online.enable = false;
  };
}
