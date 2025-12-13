{lib, ...}: {
  flake.modules.nixos.pc = {pkgs, ...}: {
    environment.systemPackages = [pkgs.brightnessctl];
  };
}
