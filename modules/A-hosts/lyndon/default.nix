{
  lib,
  inputs,
  self,
  nixonLib,
  ...
}: let
  enableGpuFirmware = true;
in {
  hosts.nixos.lyndon = {
    pkgs,
    pkgs-unstable,
    config,
    ...
  }: {
    imports = builtins.attrValues {
      inherit
        (inputs.hardware.nixosModules)
        common-pc-ssd
        common-hidpi
        common-cpu-amd
        common-cpu-amd-pstate
        common-cpu-amd-zenpower
        common-cpu-amd-raphael-igpu
        common-gpu-nvidia-sync
        ;
      hc = ./_hardware-configuration.nix;
    };

    hardware.nvidia.modesetting.enable = true;

    hardware.graphics = {
      enable = true;
    };

    hardware.nvidia = {
      powerManagement = let
        inherit (config.hardware.nvidia.prime.offload) enable;
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
        # keep the code doc fresh ~
        validateVer = supposed: {version, ...} @ package: let
          mm = v: lib.take 2 (builtins.splitVersion v);
          result = (mm supposed) == (mm version);
        in
          assert lib.assertMsg result "Nvidia driver version mismatch. ${supposed} vs actual ${version}"; package;
        stable = validateVer "570.153" config.boot.kernelPackages.nvidiaPackages.latest;
        unstable = validateVer "575.64" (pkgs-unstable.linuxPackagesFor config.boot.kernelPackages.kernel).nvidiaPackages.latest;
      in
        unstable;
    };

    boot = {
      blacklistedKernelModules = ["nouveau"];

      extraModprobeConfig = nixonLib.generators.mkModprobeConfig {
        nvidia = [
          # already enabled but let's make sure
          "NVreg_UsePageAttributeTable=1"

          "NVreg_PreserveVideoMemoryAllocations=1"
        ];
        nvidia_drm = [
          "NVreg_EnableGpuFirmware=${nixonLib.boolToString enableGpuFirmware}"
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
      # Controls if Adaptive Sync should be used. Recommended to set as “0” to avoid having problems on some games.
      __GL_VRR_ALLOWED = "0";
    };
  };
}
