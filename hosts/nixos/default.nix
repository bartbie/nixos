# configuration.nix(5) man page
# https://search.nixos.org/options
# NixOS manual (`nixos-help`).
{
  config,
  lib,
  pkgs,
  options,
  ...
} @ inputs: let
  is-vm = options ? virtualisation.memorySize;
  shared-aliases = {
    vim = "nvim";
  };
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../../common/system/programs/fish.nix
    ../../common/system/programs/pipewire.nix
    ../../common/system/programs/hyprland.nix
  ];

  mine.nvidia.enable = true;

  boot.loader = {
    # systemd-boot.enable = true;
    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      useOSProber = true;
    };
    efi = {
      canTouchEfiVariables = true;
    };
  };

  networking.hostName = "nixos";

  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Warsaw";
  i18n.defaultLocale = "en_US.UTF-8";
  services.xserver.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  services.openssh.enable = true;

  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Don't forget to set a password with ‘passwd’.
  users.users.bartbie =
    {
      isNormalUser = true;
      extraGroups = ["wheel" "networkmanager"]; # Enable ‘sudo’ for the user.
    }
    // lib.optionalAttrs is-vm {
      initialPassword = "test";
    };

  nix.settings.experimental-features = "nix-command flakes";
  environment.systemPackages = with pkgs; [
    vim
    gcc
    git
    wget
    mine.rebuild
    mine.home-export
    mine.bartbie-nvim
  ];

  environment = {
    variables = {
      # it's installed globally so make it global too
      EDITOR = "nvim";
    };
    shellAliases = shared-aliases;
  };

  # Copy the NixOS configuration file and link it from the resulting system (/run/current-system/configuration.nix).
  # NOTE: flakes can't be pure with this
  system.copySystemConfiguration = false;

  # first version of NixOS installed.
  # DO NOT CHANGE.
  # see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "23.11"; # Did you read the comment?
}
