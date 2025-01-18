{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkOption types;
  cfg = config.user.tmux;
in {
  options.user.tmux = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable tmux system configuration.";
    };
  };
  config = lib.mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      extraConfig =
        # sh
        ''
          set -g mouse on
          set-option -g focus-events on
          set-option -sg escape-time 10
          set-option -sa terminal-features ',*:RGB'
        '';
    };
  };
}
