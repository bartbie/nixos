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
  ];

  # Use the systemd-boot EFI boot loader.
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;
  boot.loader = {
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

  # Pick only one of the below networking options.
  # networking.wireless.enable = true;
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Warsaw";
  i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  services.xserver.enable = true;
  # plasma5
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";
  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  services.openssh.enable = true;

  sound.enable = true;
  hardware.pulseaudio.enable = true;

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
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    vim
    gcc
    git
    wget
    mine.rebuild
    mine.bartbie-nvim
  ];

  environment = {
    variables = {
      EDITOR = "nvim";
    };
    shellAliases = shared-aliases;
  };

  programs.fish.enable = true;
  programs.bash = {
    interactiveShellInit = ''
      if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
      then
        shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
        exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
      fi
    '';
  };

  fonts.packages = with pkgs; [
    (nerdfonts.override {fonts = ["JetBrainsMono"];})
  ];

  # Copy the NixOS configuration file and link it from the resulting system (/run/current-system/configuration.nix).
  # NOTE: flakes can't be pure with this
  system.copySystemConfiguration = false;

  # first version of NixOS installed.
  # DO NOT CHANGE.
  # see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "23.11"; # Did you read the comment?
}
