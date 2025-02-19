{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.nixon.programs.tmux;
in {
  options.nixon.programs.tmux = {
    enable = mkEnableOption "tmux";
  };
  config = lib.mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      keyMode = "vi";
      newSession = true;
      escapeTime = 10;
      baseIndex = 1;
      extraConfig =
        # sh
        ''
          set -g mouse on
          set-option -g focus-events on
          set-option -sa terminal-features ',*:RGB'
        '';
      plugins = builtins.attrValues {
        inherit (pkgs.tmuxPlugins);
      };
    };
  };
}
