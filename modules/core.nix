{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkDefault mkOption types;
  cfg = config.user.core;
in {
  options.user.core = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable core system configuration.";
    };
  };
  config = lib.mkIf cfg.enable {
    time.timeZone = mkDefault "Europe/Copenhagen";
    i18n.defaultLocale = "en_150.UTF-8";

    nix.settings.experimental-features = "nix-command flakes";

    # Copy the NixOS configuration file and link it from the resulting system (/run/current-system/configuration.nix).
    # NOTE: flakes can't be pure with this
    system.copySystemConfiguration = false;

    # first version of NixOS installed.
    # DO NOT CHANGE.
    # see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
    system.stateVersion = "23.11"; # Did you read the comment?

    # Don't forget to set a password with ‘passwd’.
    users.users.bartbie = mkDefault {
      isNormalUser = true;
      extraGroups = ["wheel" "networkmanager"]; # Enable ‘sudo’ for the user.
      initialPassword = "1";
    };
  };
}
