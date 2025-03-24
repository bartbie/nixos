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
    package = lib.mkPackageOption pkgs ["nixon" "fish"] {};
  };
  config = lib.mkIf cfg.enable {
    programs.fish = {
      inherit (cfg) package;
      enable = true;
    };
    programs.bash = {
      interactiveShellInit = ''
        if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
        then
          shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
          exec ${cfg.package}/bin/fish $LOGIN_OPTION
        fi
      '';
    };
  };
}
