{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.nixon.hosts.lyndon.nvidia;
in {
  options.nixon.hosts.lyndon.nvidia = {
    enable = mkEnableOption "nvidia";
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

    services.xserver.videoDrivers = ["nvidia"];

    hardware.nvidia = {
      modesetting.enable = true;

      prime =
        lib.mkIf cfg.prime.enable {
          offload.enable = cfg.powerManagement.finegrained;
          intelBusId = "PCI:15:0:0";
          nvidiaBusId = "PCI:01:0:0";
        }
        // cfg.prime.settings;

      powerManagement = cfg.powerManagement;

      nvidiaSettings = true;

      open = true;
      package = let
        d-565-77 = config.boot.kernelPackages.nvidiaPackages.latest;
        d-570-86 = pkgs.unstable.linuxPackages.nvidiaPackages.beta;
      in
        d-565-77;
    };
  };
}
