{
  lib,
  nixonLib,
  config,
  ...
}:
{

  perSystem =
    {
      pkgs,
      pkgs-unstable,
      inputs',
      self',
      ...
    }:
    {
      devShells.qml = pkgs.mkShell {
        name = "nixon-shell-qml";
        inputsFrom = [ self'.devShells.devBase ];
        packages = [
          inputs'.quickshell.packages.default
          pkgs.qt6.qtdeclarative # qmlls, qmllint
          pkgs.qt6.qttools # qdoc etc, maybe overkill
        ];
        shellHook = ''
          export QML_IMPORT_PATH="${inputs'.quickshell.packages.default}/lib/qml"
        '';
      };
    };

  flake.modules.nixos.pc =
    { self', pkgs, ... }:
    {
      systemd.user.services."qkshell" = {
        description = "Run Quickshell wrapper with Nixon config";
        wantedBy = [ "graphical-session.target" ];
        after = [
          "graphical-session.target"
          "pipewire.service"
        ];
        # nixonLib hardening here is too cumbersome
        partOf = [ "graphical-session.target" ];
        serviceConfig = {
          Type = "simple";
          Restart = "on-failure";
          ExecStart = lib.getExe self'.packages.qkshell;

          UnsetEnvironment = [
            "SSH_AUTH_SOCK"
            "GPG_AGENT_INFO"
          ];

          Environment = [
            "PATH=${
              lib.makeBinPath [
                pkgs.coreutils
                pkgs.curl
              ]
            }"
            "QT_LOGGING_RULES=*.debug=true;qt.*.debug=false"

          ];

          InaccessiblePaths = [
            "-%h/.ssh"
            "-%h/.gnupg"
            "-/tmp/ssh-*" # glob
            "-%t/ssh-agent.socket"
            "-%t/gnupg"
            "-%t/keyring" # gnome-keyring / libsecret also holds ssh keys
            "-%t/.local/share/keyring"
            "-%t/.mozilla"
            "-%t/.cache/mozilla"
          ];

          NoNewPrivileges = true;
          LockPersonality = true;
          ProtectClock = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          RestrictSUIDSGID = true;
          RestrictRealtime = true;
        };
      };
    };

  wrapped.qkshell = {
    tags = [ "pc" ];
    systems = config.meta.systemsNoDarwin;
    module =
      { pkgs, inputs', ... }:
      {
        single = {
          package = inputs'.quickshell.packages.default;
          programName = "qkshell";
          wrapper = {
            prependArgs = [
              "-p"
              (nixonLib.srcPath + /qkshell)
            ];
          };
        };
      };
  };
}
