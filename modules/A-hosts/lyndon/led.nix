{ ... }:
{
  hosts.nixos.lyndon =
    { config, pkgs-unstable, ... }:
    {
      hardware.i2c.enable = true;
      boot.kernelParams = [ "acpi_enforce_resources=lax" ];
      services.hardware.openrgb = {
        enable = true;
        package = pkgs-unstable.openrgb-with-all-plugins;
      };
    };
}
