{
  inputs,
  nixonLib,
  ...
}: {
  hosts.nixos.lyndon = {pkgs, ...}: {
    imports = builtins.attrValues {
      inherit
        (inputs.hardware.nixosModules)
        common-pc-ssd
        common-hidpi
        common-cpu-amd
        common-cpu-amd-pstate
        common-cpu-amd-zenpower
        common-cpu-amd-raphael-igpu
        ;
      hc = ./_hardware-configuration.nix;
    };
  };
}
