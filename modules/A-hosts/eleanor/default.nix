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
      systemd.network.networks."40-enp1s0" = {
        matchConfig.Name = "enp1s0";
        address = [ "2a01:4f8:1c1c:7fec::1/64" ];
        routes = [
          {
            Gateway = "fe80::1";
            GatewayOnLink = true;
          }
        ];
        networkConfig = {
          DHCP = "ipv4";
          IPv6AcceptRA = false;
        };
      };
    };
}
