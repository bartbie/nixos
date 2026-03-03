{ lib, ... }:
{
  flake.modules.nixos.base =
    {
      pkgs,
      config,
      ...
    }:
    let
      ownername = config.meta.owner.username;
      just-one-normal-user =
        config.users.users |> builtins.attrValues |> lib.count (x: x.isNormalUser) |> (x: x == 1);
      owner-user-exists =
        config.users.users
        |> builtins.attrNames
        |> lib.findFirst (x: x == ownername) null
        |> (x: x != null);
      # just-owner-user = config.users.users |> builtins.attrNames |> builtins.length |> (x: x == 1);
    in
    {
      config = lib.mkMerge [
        {
          console = {
            font = "ter-v32n";
            packages = [ pkgs.terminus_font ];
            earlySetup = true;
          };
        }
        (lib.mkIf (!(config.services.greetd.enable) && owner-user-exists && just-one-normal-user) {
          # Skip username only for tty1
          systemd.services."getty@tty1" = {
            overrideStrategy = "asDropin";
            serviceConfig.ExecStart = [
              ""
              "@${pkgs.util-linux}/sbin/agetty agetty -o '-p -- ${ownername}' --noclear --skip-login %I $TERM"
            ];
          };
        })
      ];
    };
}
