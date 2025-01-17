# configuration.nix(5) man page
# https://search.nixos.org/options
# NixOS manual (`nixos-help`).
{
  config,
  lib,
  pkgs,
  options,
  inputs,
}: let
  shared-aliases = {
    vim = "nvim";
  };
in {
  imports = [
    inputs.disko.nixosModules.disko
    inputs.impermanence.nixosModules
    ./disko.nix
    ./impermanence.nix
    ./hardware-configuration.nix
    ./nvidia.nix
  ];

  boot.loader = {
    systemd-boot.enable = true;
  };

  services.xserver.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = false;

  services.openssh.enable = true;

  # environment.systemPackages = with pkgs; [
  #   vim
  #   gcc
  #   git
  #   wget
  #   mine.scripts.rebuild
  #   mine.scripts.home-export
  #   mine.bartbie-nvim
  # ];

  environment = {
    variables = {
      # it's installed globally so make it global too
      EDITOR = "nvim";
    };
    shellAliases = shared-aliases;
  };
}
