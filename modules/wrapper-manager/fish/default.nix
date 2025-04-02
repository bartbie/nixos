{
  pkgs,
  lib,
  wrapperManagerLib,
  ...
} @ inputs: let
  writeVendor = type: x: pkgs.writeTextDir "share/fish/vendor_${type}.d/${x}";
  writeVendorConf = writeVendor "conf";

  plugins = builtins.attrValues {
    inherit
      (pkgs.fishPlugins)
      foreign-env
      fzf-fish
      ;
  };

  mapPlugins = lib.flip lib.pipe [
    (map (elem: "bartbie_load_plugin ${elem}"))
    (lib.concatStringsSep "\n")
  ];

  starship-config = (pkgs.formats.toml {}).generate "starship.toml" (import ./starship.nix inputs);

  direnv-config = pkgs.writeTextDir "direnvrc" ''
    source ${pkgs.nix-direnv}/share/nix-direnv/direnvrc
  '';

  kanagawa = pkgs.writeText "kanagawa.fish" (import ./kanagawa.nix inputs);

  zellij-hook = let
    zel = lib.getExe' pkgs.nixon.zellij "zellij";
  in
    #fish
    ''
      if not set -q TMUX
        set ZJ_SESSIONS (${zel} list-sessions)
        set NO_SESSIONS (echo "$ZJ_SESSIONS" | wc -l)
        if not set -q ZELLIJ
          if test $NO_SESSIONS -ge 2
            ${zel} attach (echo "$ZJ_SESSIONS" | ${lib.getExe' pkgs.skim "skim"})
          else
            ${zel} attach -c
          end

          if test "$ZELLIJ_AUTO_EXIT" = "true"
            kill $fish_pid
          end
        end
      end
    '';

  config =
    writeVendorConf "bartbie_config.fish"
    # fish
    ''
      source ${./load_plugin.fish}
      ${mapPlugins plugins}

      fenv source /etc/profile

      if status is-interactive
          source ${./pushd_mod.fish}

          ${builtins.readFile ./interactive.fish}

          source ${kanagawa}

          set -gx STARSHIP_CONFIG ${starship-config}
          ${lib.getExe pkgs.starship} init fish | source

          set -gx DIRENV_LOG_FORMAT "" # disables direnv logging
          set -gx direnv_config_dir ${direnv-config}
          ${lib.getExe pkgs.direnv} hook fish | source

          ${zellij-hook}
      end
    '';
in {
  wrappers.fish = {
    arg0 = lib.getExe' pkgs.fish "fish";
    xdg.dataDirs = wrapperManagerLib.getXdgDataDirs [config];
  };
}
