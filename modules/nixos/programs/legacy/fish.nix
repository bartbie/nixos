{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.nixon.programs.fish;
in {
  options.nixon.programs.fish = {
    enable = mkEnableOption "fish";
    enable_vi_mode = mkEnableOption "vi key bindings";
  };
  config = lib.mkIf cfg.enable {
    programs.fish = {
      enable = true;
      interactiveShellInit =
        # fish
        ''
          set fish_greeting # Disable greeting
        ''
        + lib.optionalString cfg.enable_vi_mode
        # fish
        ''
          fish_vi_key_bindings
        '';
    };
    programs.bash = {
      interactiveShellInit = ''
        if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
        then
          shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
          exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
        fi
      '';
    };
  };
}
