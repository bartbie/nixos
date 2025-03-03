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
    modesetting.enable = mkEnableOption "modesetting";
    enableGpuFirmware = mkEnableOption "enableGpuFirmware" // {default = true;};
    powerManagement = {
      enable = (mkEnableOption "nvidia power management") // {default = cfg.prime.enable;};
      finegrained = (mkEnableOption "nvidia finegrained power management") // {default = cfg.prime.enable;};
    };
    prime = {
      enable = mkEnableOption "nvidia prime";
      settings = lib.mkOption {
        description = "extra settings for prime";
        type = lib.types.attrs;
        default = {};
      };
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.prime.enable -> cfg.powerManagement.enable;
        message = "powerManagement needs to be enabled when enabling prime";
      }
      {
        assertion = cfg.prime.enable -> cfg.powerManagement.finegrained;
        message = "powerManagement.finegrained needs to be enabled when enabling prime";
      }
    ];

    hardware.graphics = {
      enable = true;
    };

    hardware.nvidia = {
      inherit (cfg) powerManagement modesetting;

      prime =
        lib.mkIf cfg.prime.enable {
          offload.enable = cfg.powerManagement.finegrained;
          intelBusId = "PCI:15:0:0";
          nvidiaBusId = "PCI:01:0:0";
        }
        // cfg.prime.settings;

      nvidiaSettings = true;

      open = true;
      package = let
        d-565-77 = config.boot.kernelPackages.nvidiaPackages.latest;
        d-570-86 = pkgs.unstable.linuxPackages.nvidiaPackages.beta;
      in
        d-565-77;
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
    environment.variables = {
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
