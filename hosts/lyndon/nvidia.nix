{
  config,
  lib,
  pkgs,
  options,
  flake,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.nixon.hosts.lyndon.nvidia;
in {
  options.nixon.hosts.lyndon.nvidia = {
    enable = mkEnableOption "nvidia";
    enableGpuFirmware = mkEnableOption "enableGpuFirmware" // {default = true;};
  };
  config = lib.mkIf cfg.enable {
    hardware.graphics = {
      enable = true;
    };

    hardware.nvidia = {
      powerManagement = let
        inherit (config.hardware.nvidia) prime;
        enable = prime.offload.enable;
      in {
        enable = lib.mkDefault enable;
        finegrained = lib.mkDefault enable;
      };

      prime = {
        amdgpuBusId = "PCI:15:0:0";
        nvidiaBusId = "PCI:01:0:0";
      };

      nvidiaSettings = true;

      open = true;
      package = let
        d-565-135 = config.boot.kernelPackages.nvidiaPackages.latest;
        d-570-124 = pkgs.unstable.linuxPackages.nvidiaPackages.latest;
      in
        d-570-124;
    };

    boot = {
      blacklistedKernelModules = ["nouveau"];

      extraModprobeConfig = flake.lib.mkModprobeConfig {
        nvidia = [
          # already enabled but let's make sure
          "NVreg_UsePageAttributeTable=1"

          "NVreg_PreserveVideoMemoryAllocations=1"
        ];
        nvidia_drm = [
          "NVreg_EnableGpuFirmware=${flake.lib.boolToStringFlag cfg.enableGpuFirmware}"
        ];
      };
    };

    services = {
      xserver.videoDrivers = ["nvidia"];

      ddccontrol.enable = false;
    };

    # Set environment variables related to NVIDIA graphics
    environment.sessionVariables = {
      # Required to run the correct GBM backend for nvidia GPUs on wayland
      GBM_BACKEND = "nvidia-drm";
      # Apparently, without this nouveau may attempt to be used instead
      # (despite it being blacklisted)
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      # Hardware cursors are currently broken on nvidia
      LIBVA_DRIVER_NAME = "nvidia";
      WLR_NO_HARDWARE_CURSORS = "1";
      NIXOS_OZONE_WL = "1";
      __GL_THREADED_OPTIMIZATION = "1";
      __GL_SHADER_CACHE = "1";
    };
  };
}
