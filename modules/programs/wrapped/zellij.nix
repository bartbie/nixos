{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.nixon.programs.zellij;
  package = pkgs.nixon.zellij;
in {
  options.nixon.programs.zellij = {
    enable = mkEnableOption "zellij";
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [package];
    programs.fish.interactiveShellInit = let
      zel = "${package}/bin/zellij";
    in
      lib.mkAfter
      #fish
      ''
        # eval (${zel} setup --generate-auto-start fish | string collect)

        set ZJ_SESSIONS (${zel} list-sessions)
        set NO_SESSIONS (echo "$ZJ_SESSIONS" | wc -l)
        if not set -q ZELLIJ
            if test $NO_SESSIONS -ge 2
                ${zel} attach (echo "$ZJ_SESSIONS" | ${pkgs.skim}/bin/skim)
            else
                ${zel} attach -c
            end

            if test "$ZELLIJ_AUTO_EXIT" = "true"
                kill $fish_pid
            end
        end
      '';
  };
}
