{
  config,
  lib,
  pkgs,
  flake,
  ...
}: {
  imports =
    [
      ./disko.nix
      ./hardware-configuration.nix
      ./nvidia.nix
    ]
    ++ (builtins.attrValues {
      inherit
        (flake.inputs.hardware.nixosModules)
        common-pc-ssd
        common-hidpi
        common-cpu-amd
        common-cpu-amd-pstate
        common-cpu-amd-zenpower
        common-cpu-amd-raphael-igpu
        common-gpu-nvidia-sync
        ;
    });

  nixon.impermanence.enable = true;

  hardware.nvidia.modesetting.enable = true;
  nixon.hosts.lyndon.nvidia = {
    enable = true;
  };

  environment = {
    variables = {
      # it's installed globally so make it global too
      EDITOR = "nvim";
    };
    shellAliases = {
      vim = "nvim";
    };
  };
}
