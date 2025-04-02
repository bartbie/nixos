{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.nixon.programs.fish;
  package = pkgs.nixon.fish;
in {
  options.nixon.programs.fish = {
    enable = mkEnableOption "fish";
  };
  config = lib.mkIf cfg.enable {
    programs.bash = {
      interactiveShellInit = ''
        if [[ $(${lib.getExe' pkgs.procps "ps"} --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
        then
          shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
          exec ${lib.getExe' package "fish"} $LOGIN_OPTION
        fi
      '';
    };
  };
}
