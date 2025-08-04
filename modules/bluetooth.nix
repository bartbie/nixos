{
  flake.modules.nixos.pc = {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = false;
    };
  };
}
