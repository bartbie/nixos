{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkOption types;
  cfg = config.user.fish;
in {
  options.user.fish = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable fish system configuration.";
    };
    enable_vi_mode = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable vi key bindings.";
    };
  };
  config = lib.mkIf cfg.enable {
    programs.fish.enable = true;
    programs.bash = {
      interactiveShellInit = ''
        if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
        then
          shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
          exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
        fi
      '';
    };
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
}
