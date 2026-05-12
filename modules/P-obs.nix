{ lib, ... }:
{
  flake.modules.nixos.pc =
    { pkgs, config, ... }:
    {
      boot.kernelModules = [ "v4l2loopback" ];
      boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
      boot.extraModprobeConfig = ''
        options v4l2loopback devices=1 video_nr=10 card_label="OBS Virtual Camera" exclusive_caps=1
      '';
      environment.systemPackages = [
        (pkgs.wrapOBS {
          plugins = builtins.attrValues {
            inherit (pkgs.obs-studio-plugins)
              obs-backgroundremoval
              ;
          };
        })
      ];
    };
}
