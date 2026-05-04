{ lib, ... }:
let
  initialPassword = "1";
in
{
  flake.modules.nixos = {
    base =
      { config, ... }:
      let
        ownername = config.meta.owner.username;
      in
      {
        nix.settings.trusted-users = [ ownername ];
        users = {
          mutableUsers = false;
          users.${ownername} = {
            isNormalUser = true;
            uid = 1000;
            extraGroups = [ "wheel" ];
          };
        };
      };
    server =
      { config, ... }:
      let
        ownername = config.meta.owner.username;
      in
      {
        security = {
          sudo.enable = false;
          doas = {
            enable = true;
            extraRules = [
              {
                users = [ ownername ];
                noPass = true;
                keepEnv = true;
              }
            ];
          };
        };
      };
    pc =
      { config, ... }:
      let
        ownername = config.meta.owner.username;
        mapCmds =
          options:
          builtins.map (cmd: {
            inherit options;
            command = "/run/current-system/sw/bin/${cmd}";
          });
      in
      {
        security.sudo.extraRules = [
          {
            commands = mapCmds [ "NOPASSWD" ] [ "poweroff" "reboot" ];
            groups = [ "wheel" ];
          }
        ];
        users.users.${ownername} = {
          inherit initialPassword;
          extraGroups = [
            "networkmanager"
            "audio"
            "video"
            "input"
            "kvm"
            "wireshark"
            "i2c"
          ];
        };
      };
    persist-password-files =
      { config, ... }:
      let
        enable = config.environment ? persistence;
        ownername = config.meta.owner.username;
        users = [
          "root"
          ownername
        ];
        mapUsers = fn: l: lib.genAttrs l fn;
      in
      {
        users.users = lib.mkIf enable (
          users
          |> mapUsers (name: {
            hashedPasswordFile = lib.mkDefault "/persist/secrets/${name}";
          })
        );
        virtualisation.vmVariant.users.users =
          users
          |> mapUsers (name: {
            hashedPasswordFile = null;
          });
      };
  };
}
