{ lib, ... }:
let
  common = {
    time.timeZone = lib.mkDefault "Europe/Copenhagen";
    i18n.defaultLocale = "C.UTF-8";

    nix.settings.experimental-features = "nix-command flakes";

    # Copy the NixOS configuration file and link it from the resulting system (/run/current-system/configuration.nix).
    # NOTE: flakes can't be pure with this
    system.copySystemConfiguration = false;

    # first version of NixOS installed.
    # DO NOT CHANGE.
    # see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
    system.stateVersion = "23.11"; # Did you read the comment?
  };
in
{
  flake.modules.nixos.base = common;
  flake.modules.darwin.base = common;
}
