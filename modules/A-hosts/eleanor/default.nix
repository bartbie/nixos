{
  inputs,
  nixonLib,
  ...
}:
{
  hosts.nixos.eleanor =
    { pkgs, ... }:
    {
      boot.loader.grub = {
        enable = true;
      };
      boot.loader.systemd-boot.enable = false;
    };
}
