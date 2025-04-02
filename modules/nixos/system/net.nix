{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.nixon.net;
in {
  options.nixon.net = {
    enable = mkEnableOption "net";
  };
  config = lib.mkIf cfg.enable {
    networking = {
      networkmanager.enable = true;
      firewall = {
        enable = true;
        allowPing = false;
        logReversePathDrops = true;
      };
    };
    # slows down boot time
    systemd.services.NetworkManager-wait-online.enable = false;
    programs.ssh.startAgent = lib.mkDefault true;
  };
}
