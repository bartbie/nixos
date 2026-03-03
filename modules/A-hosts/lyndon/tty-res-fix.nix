{ nixonLib, ... }:
{
  hosts.nixos.lyndon =
    { pkgs, ... }:
    {
      systemd.services.fbset-tty-resolution =
        let
          # Calculate fbset pixclock from resolution and refresh rate
          # pixclock (picoseconds) = 1000000000000 / (htotal * vtotal * refresh_hz)
          calcPixclock =
            {
              xres,
              yres,
              refresh ? 60,
            }:
            let
              # Standard timing estimates (CVT reduced blanking)
              hblank = builtins.ceil (xres * 0.15);
              vblank = builtins.ceil (yres * 0.04);
              htotal = xres + hblank;
              vtotal = yres + vblank;
              pixclock = builtins.floor (1000000000000.0 / (htotal * vtotal * refresh));
            in
            {
              inherit pixclock htotal vtotal;
              xres = xres;
              yres = yres;
              refresh = refresh;
            };
          mkFbsetCmd =
            timing:
            timing
            |> builtins.mapAttrs (_: builtins.toString)
            |> (
              t: "${pkgs.fbset}/bin/fbset -g ${t.xres} ${t.yres} ${t.xres} ${t.yres} 32 -pixclock ${t.pixclock}"
            );

          timing4k144 = calcPixclock {
            xres = 3840;
            yres = 2160;
            refresh = 144;
          };
        in
        {
          description = "Set TTY framebuffer resolution to 4k";
          wantedBy = [ "multi-user.target" ];
          after = [
            "systemd-vconsole-setup.service"
            "plymouth-quit-wait.service"
            "systemd-modules-load.service" # kernel modules loaded
            "systemd-udev-settle.service" # udev settled, /dev/fb0 exists
            "nvidia-persistenced.service" # nvidia daemon if enabled
          ];
          wants = [
            "systemd-modules-load.service"
            "systemd-udev-settle.service"
          ];
          before = [
            "display-manager.service"
            "getty@tty1.service"
            "greetd.service"
          ];

          unitConfig.ConditionPathExists = "/dev/fb0";

          serviceConfig = nixonLib.systemd.hardenServiceConfig {
            Type = "oneshot";
            RemainAfterExit = false;
            ExecStart = mkFbsetCmd timing4k144;
            Restart = "on-failure";
            RestartSec = "2s";
            StartLimitBurst = 3;
            StartLimitIntervalSec = "30s";

            # Overrides for fbset access
            PrivateUsers = false; # needs root UID
            DevicePolicy = "auto"; # needs /dev/fb0
            ProtectKernelTunables = false; # writes to /sys/class/graphics
            SystemCallFilter = [
              "@system-service"
              "@privileged"
            ]; # needs ioctl on framebuffer
            CapabilityBoundingSet = [ "CAP_SYS_TTY_CONFIG" ]; # framebuffer ioctls
          };
        };
    };
}
