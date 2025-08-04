{lib, ...}: let
  initialPassword = "1";
in {
  flake.modules.nixos = {
    pc = {
      security = let
        mapCmds = options:
          builtins.map (cmd: {
            inherit options;
            command = "/run/current-system/sw/bin/${cmd}";
          });
      in {
        sudo.extraRules = [
          {
            commands = mapCmds ["NOPASSWD"] ["poweroff" "reboot"];
            groups = ["wheel"];
          }
        ];
      };
    };
    users-bartbie = {
      nix.settings.trusted-users = ["bartbie"];
      users = {
        mutableUsers = false;
        users.bartbie = {
          isNormalUser = true;
          inherit initialPassword;
          uid = 1000;
          extraGroups = [
            "wheel"
            "networkmanager"
            "audio"
            "video"
            "input"
            "kvm"
            "wireshark"
          ];
        };
      };
    };
    persistPasswordFiles = {config, ...}: let
      enable = config.environment ? persistence;
    in {
      users = lib.mkIf enable (
        builtins.map (user: {
          ${user}.hashedPasswordFile = lib.mkDefault "/persist/secrets/${user}";
        })
        config.users.users
      );
    };
  };
}
