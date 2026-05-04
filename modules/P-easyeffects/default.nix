{ lib, config, ... }:
{
  wrapped.easyeffects = {
    tags = config.meta.systemsNoDarwin;
    module =
      { pkgs, self', ... }:
      {
        single.package = pkgs.easyeffects;
        build.extraSetup =
          let
            lt = lib.getExe self'.packages.linktree;
          in
          # sh
          ''
            ${lt} ${pkgs.easyeffects} $out
            preset_path="$out/share/easyeffects/"
            preset_name="easyeffects-nixon-presets"
            ${lt} ${./presets/input} "$preset_path/input/$preset_name"
            ${lt} ${./presets/output} "$preset_path/output/$preset_name"
          '';
      };
  };

  flake.modules.nixos.pc =
    { self', ... }:
    let
      inherit (self'.packages) easyeffects;
    in
    {

      environment.systemPackages = [ easyeffects ];

      systemd.user.services.easyeffects = {
        description = "EasyEffects audio processor";
        wantedBy = [ "default.target" ];
        after = [ "pipewire.service" ];
        serviceConfig = {
          ExecStart = "${easyeffects}/bin/easyeffects --gapplication-service";
          Restart = "on-failure";
        };
      };

    };
}
