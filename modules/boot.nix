{lib, ...}: {
  flake.modules.nixos.pc = {pkgs, ...}: {
    boot = {
      loader = {
        systemd-boot = {
          enable = lib.mkDefault true;
          configurationLimit = 10;
        };
      };

      kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
    };
  };
}
