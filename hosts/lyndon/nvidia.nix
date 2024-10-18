{
  pkgs,
  config,
  libs,
  ...
}: {
  hardware.opengl = {
    enable = true;
  };

  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia.modesetting.enable = true;
  hardware.nvidia.powerManagement.enable = false;
  hardware.nvidia.powerManagement.finegrained = false;
  hardware.nvidia.open = false;
  hardware.nvidia.nvidiaSettings = true;

  # 550 in 24.05, 560 supposedly still has problems
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.production;
}
