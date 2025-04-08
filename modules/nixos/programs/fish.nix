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
      interactiveShellInit = let
        fish-cmd = lib.getExe' package "fish";
      in ''
        if [[ $(${lib.getExe' pkgs.procps "ps"} --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
        then
          shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
          export SHELL=${fish-cmd}
          exec ${fish-cmd} $LOGIN_OPTION
        fi
      '';
    };
  };
}
