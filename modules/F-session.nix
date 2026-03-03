{ lib, ... }:
{
  flake.modules.nixos.base =
    { config, ... }:
    {
      users.users.${config.meta.owner.username}.linger = true;
    };
  flake.modules.nixos.pc = lib.mkMerge [
    (
      { pkgs, ... }:
      {
        systemd.services.lock-before-suspend =
          let
            lockScript =
              pkgs.writeShellScript "lock-before-suspend"
                #sh
                ''
                  echo "lock-before-suspend.service: Attempting to lock sessions before suspension..."
                  if ${pkgs.systemd}/bin/loginctl lock-sessions; then
                    echo "lock-before-suspend.service: Successfully locked sessions."
                  else
                    echo "lock-before-suspend.service: Failed to lock sessions." >&2
                    exit 1
                  fi
                '';
          in
          {
            enable = true;
            description = "Lock sessions before suspending it.";
            before = [ "suspend.target" ];
            wantedBy = [ "suspend.target" ];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${lockScript}";
            };
          };
      }
    )
  ];
}
