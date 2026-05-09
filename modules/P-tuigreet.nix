{
  lib,
  config,
  ...
}:
{
  # TODO: maybe in future export as much as possible to a wrapper package vs system config
  #
  # wrapped.tuigreet = {
  #   systems = config.meta.systemsNoDarwin;
  #   module = {
  #     pkgs,
  #     pkgs-unstable,
  #     inputs',
  #     theme,
  #     ...
  #   }: let
  #     tuigreet-config-wrapper = {
  #     };
  #   in {
  #     single = {
  #       package = inputs'.tuigreet.packages.default;
  #       wrapper = {
  #         prependArgs = ["--config" ((pkgs.formats.toml {}).generate "tuigreet-config.toml" tuigreet-config-wrapper)];
  #         env.TUIGREET_DEBUG.value = "true";
  #         env.TUIGREET_LOG_FILE.value = "/var/log/tuigreet.log";
  #       };
  #     };
  #   };
  # };

  flake.modules.nixos.pc =
    {
      config,
      pkgs,
      self',
      inputs',
      theme,
      ...
    }:
    let
      ownername = config.meta.owner.username;

      tuigreet-config =
        let
          uwsmCfg = config.programs.uwsm;
          compositors = uwsmCfg.waylandCompositors |> builtins.attrNames;
          only-one-uwsm = compositors |> builtins.length |> (x: x == 1);
        in
        lib.mergeAttrsList [
          {
            display = {
              show_time = true;
              show_title = true;
              issue = true;
            };
            layout = {
              # window_padding = 1;
              widgets = {
                time_position = "top";
                # status_position = "hidden";
              };
            };
            secret = {
              mode = "characters";
              characters = "*";
            };
            theme =
              let
                inherit (theme.termcolors.simple)
                  ansi
                  area
                  brights
                  rest
                  ;
              in
              {
                text = ansi.white;
                time = area.comment;
                container = area.primary.bg;
                border = area.split;
                title = ansi.magenta;
                greet = brights.blue;
                prompt = brights.magenta;
                input = area.primary.fg;
                action = ansi.yellow;
                button = brights.yellow;
              };
          }
          {
            remember.default_user = ownername;
            power = {
              use_setsid = false;
              shutdown = "systemctl poweroff";
              reboot = "systemctl reboot";
            };
          }
          (lib.optionalAttrs (uwsmCfg.enable && !only-one-uwsm) {
            session.session_wrapper = "uwsm start";
          })
          (lib.optionalAttrs (uwsmCfg.enable && only-one-uwsm) {
            session.command = "uwsm start ${builtins.head compositors}-uwsm.desktop";
          })
        ];

      command = lib.getExe' inputs'.tuigreet.packages.default "tuigreet";
    in
    {
      config = {
        services.greetd = {
          enable = true;
          useTextGreeter = true;
          settings = {
            default_session = {
              inherit command;
              user = "greeter";
            };
          };
        };

        environment.etc."tuigreet/config.toml".source =
          (pkgs.formats.toml { }).generate "tuigreet-config.toml"
            tuigreet-config;

        # https://git.sr.ht/~kennylevinsen/greetd/tree/26bf71eb43e4caaffc7371ffa7c1009a6b25ab9d/item/greetd.service
        systemd.services.greetd.description = "Greeter daemon";

        systemd.tmpfiles.rules = [
          "f /var/log/tuigreet.log 0644 greeter greeter -"
        ];
      };
    };
}
