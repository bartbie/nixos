# configuration.nix(5) man page
# https://search.nixos.org/options
# NixOS manual (`nixos-help`).
{
  config,
  options,
  lib,
  pkgs,
  inputs,
  ...
}: let
  shared-aliases = {
    vim = "nvim";
  };
in {
  imports = [
    inputs.disko.nixosModules.disko
    inputs.impermanence.nixosModules.impermanence
    ./disko.nix
    ./impermanence.nix
    ./hardware-configuration.nix
    ./nvidia.nix
  ];

  nixon.hosts.lyndon.nvidia = {
    enable = true;
    prime = {
      enable = true;
      # settings = {};
    };
    # powerManagement = {
    #   enable = true;
    #   finegrained = true;
    # };
  };

  boot.loader = {
    systemd-boot.enable = true;
  };

  services.openssh.enable = true;

  environment = {
    variables = {
      # it's installed globally so make it global too
      EDITOR = "nvim";
    };
    shellAliases = shared-aliases;
  };
}
