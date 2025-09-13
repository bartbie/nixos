{
  wrapped.direnv.module = {pkgs, ...}: let
    rc-extra =
      #sh
      '''';

    rc =
      #sh
      ''
        #Load nix-direnv
        source ${pkgs.nix-direnv}/share/nix-direnv/direnvrc
        o
        #Load direnvExtra
        ${rc-extra}

        #Load user-configuration if present (~/.direnvrc or ~/.config/direnv/direnvrc)
        direnv_config_dir_home="''${DIRENV_CONFIG_HOME:-''${XDG_CONFIG_HOME:-$HOME/.config}/direnv}"
        if [[ -f $direnv_config_dir_home/direnvrc ]]; then
          source "$direnv_config_dir_home/direnvrc" >&2
        elif [[ -f $HOME/.direnvrc ]]; then
          source "$HOME/.direnvrc" >&2
        fi

        unset direnv_config_dir_home
      '';

    zz-user =
      #sh
      ''
        direnv_config_dir_home="''${DIRENV_CONFIG_HOME:-''${XDG_CONFIG_HOME:-$HOME/.config}/direnv}"

        for lib in "$direnv_config_dir_home/lib/"*.sh; do
          source "$lib"
        done

        unset direnv_config_dir_home
      '';
  in {
    single = {
      package = pkgs.direnv;
      wrapper = {
        env = {
          "DIRENV_CONFIG".value = pkgs.linkFarm "direnv-config" {
            "direnvrc" = pkgs.writeText "direnvrc" rc;
            "direnv.toml" = (pkgs.formats.toml {}).generate "direnv.toml" {};
            "lib" = "${pkgs.writeTextDir "lib/zz-user.sh" zz-user}/lib";
          };
          # disables direnv logging by default
          "DIRENV_LOG_FORMAT" = {
            value = "";
            action = "set-default";
          };
        };
      };
    };
  };
}
