{ nixonLib, ... }:
{
  flake.modules.nixos.pc =
    {
      config,
      pkgs,
      self',
      ...
    }:
    let
      ownername = config.meta.owner.username;
    in
    {
      security.rtkit.enable = true;
      services.playerctld.enable = true;

      security.sudo.extraRules = [
        {
          users = [ ownername ];
          commands = nixonLib.generators.mapCmdsForSudo [ "NOPASSWD" ] [ "toggle-cam-mic" ];
        }
      ];

      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
        extraConfig.pipewire = {
          "60-echo-cancel" = {
            "context.modules" = [
              {
                name = "libpipewire-module-echo-cancel";
                args = {
                  "monitor.mode" = true;
                  "node.description" = "Clean Mic";
                  "capture.props" = {
                    "node.passive" = true;
                    # Fiddle with if experiencing voice distortion/crackling
                    # Default: 0/unset
                    "node.force-quantum" = 256;
                  };
                  "source.props" = {
                    "node.name" = "source_ec";
                    "node.description" = "Echo-cancelled source";
                    "media.class" = "Audio/Source";
                  };
                  "aec.args" = {
                    "webrtc.gain_control" = false;
                    "webrtc.noise_suppression" = true;
                    "webrtc.high_pass_filter" = true;
                    "webrtc.extended_filter" = true;
                  };
                };
              }
            ];
          };
        };
        wireplumber.extraConfig = {
          "51-scarlett-mic1-higher-priority" = {
            "node.rules" = [
              # prefer mic1, survives a hardware swap
              {
                matches = [ { "node.name" = "~alsa_input.*Scarlett.*Mic1.*"; } ];
                actions.update-props = {
                  "priority.session" = 1500;
                  "priority.driver" = 1500;
                };
              }
            ];
          };
        };
      };
    };
}
