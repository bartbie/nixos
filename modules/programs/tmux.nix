{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.nixon.tmux;
in {
  options.nixon.tmux = {
    enable = mkEnableOption "tmux";
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
