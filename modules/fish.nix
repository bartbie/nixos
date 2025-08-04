{lib, ...}: let
  common = {pkgs}: let
    package = pkgs.nixon.fish;
  in {
    environment.systemPackages = [
      pkgs.nix-index
    ];
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
in {
  flake.modules = {
    nixos.base = common;
    darwin.base = common;
  };
}
