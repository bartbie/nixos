{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.nixon.users;
in {
  options.nixon.users = {
    enable = mkEnableOption "users";
    root.useHashedPasswordFile = (mkEnableOption "hashed password") // {default = true;};
    bartbie = {
      enable = (mkEnableOption "bartbie user") // {default = true;};
      useHashedPasswordFile = (mkEnableOption "hashed password") // {default = true;};
    };
  };
  config = lib.mkIf cfg.enable {
    users = {
      mutableUsers = false;
      users = {
        root.hashedPasswordFile = lib.mkIf cfg.root.useHashedPasswordFile "/persist/secrets/root";
        bartbie = lib.mkIf cfg.bartbie.enable {
          hashedPasswordFile = lib.mkIf cfg.bartbie.useHashedPasswordFile "/persist/secrets/bartbie";
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
    };
  };
}
