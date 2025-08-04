{
  lib,
  flake,
  ...
}: {
  flake.modules.nixos.pc = {
    config,
    pkgs,
    ...
  }: let
    package = pkgs.nixon.kanata;
  in {
    hardware.uinput.enable = true;
    systemd.services.kanata = {
      wantedBy = ["multi-user.target"];
      description = "Kanata service";
      serviceConfig = flake.lib.systemd.hardenServiceConfig {
        Type = "notify";
        ExecStart = ''
          ${lib.getExe package}
        '';
        DynamicUser = true;
        # RuntimeDirectory = "kanata";
        SupplementaryGroups = flake.lib.systemd.mapGroups {
          inherit
            (config.users.groups)
            input
            uinput
            ;
        };
        # hardening
        DeviceAllow = [
          "/dev/uinput rw"
          "char-input r"
        ];
      };
    };
  };
}
