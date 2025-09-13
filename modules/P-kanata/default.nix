{
  lib,
  nixonLib,
  ...
}: {
  wrapped.kanata.module = {pkgs-unstable, ...}: {
    single = {
      package = pkgs-unstable.kanata;
      wrapper.prependArgs = [
        "--cfg"
        # for live-reload
        # "/etc/nixos/modules/wrapper-manager/kanata/config.kbd"
        ./config.kbd
      ];
    };
  };

  flake.modules.nixos.pc = {
    config,
    pkgs,
    self',
    ...
  }: let
    package = self'.packages.kanata;
  in {
    hardware.uinput.enable = true;
    systemd.services.kanata = {
      wantedBy = ["multi-user.target"];
      description = "Kanata service";
      serviceConfig = nixonLib.systemd.hardenServiceConfig {
        Type = "notify";
        ExecStart = ''
          ${lib.getExe package}
        '';
        DynamicUser = true;
        # RuntimeDirectory = "kanata";
        SupplementaryGroups = nixonLib.systemd.mapGroups {
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
