{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkEnableOption mkDefault;
  cfg = config.nixon.users;
in {
  options.nixon.users = {
    enable = mkEnableOption "users";
  };
  config = lib.mkIf cfg.enable {
    # Don't forget to set a password with ‘passwd’.
    users.users.bartbie = mkDefault {
      isNormalUser = true;
      initialPassword = "1";
      uid = 1000;
      extraGroups = [
        "wheel"
        "networkmanager"
        "audio"
        "video"
        "input"
        "kvm"
        "wireshark"
      ];
    };
  };
}
