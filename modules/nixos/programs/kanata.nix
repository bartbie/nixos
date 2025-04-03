{
  config,
  lib,
  pkgs,
  options,
  flake,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.nixon.programs.kanata;

  package = pkgs.nixon.kanata;
in {
  options.nixon.programs.kanata = {
    enable = mkEnableOption "kanata";
  };
  config = lib.mkIf cfg.enable {
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
