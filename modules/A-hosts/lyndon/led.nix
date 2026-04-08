{ ... }:
{
  hosts.nixos.lyndon =
    { config, pkgs-unstable, ... }:
    {
      hardware.i2c.enable = true;
      services.hardware.openrgb = {
        enable = true;
        package = pkgs-unstable.openrgb-with-all-plugins;
      };
    };
}
