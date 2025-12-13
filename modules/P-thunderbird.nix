{lib, ...}: {
  flake.modules.nixos.pc = {
    programs.thunderbird.enable = true;
  };
}
