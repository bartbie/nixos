{
  pkgs,
  lib,
  self',
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

  starship-config = (pkgs.formats.toml {}).generate "starship.toml" (import ./_starship.nix inputs);

  kanagawa = pkgs.writeText "kanagawa.fish" (import ./_kanagawa.nix inputs);

  zellij-hook = let
    zel = lib.getExe' self'.packages.zellij "zellij";
  in
    # fish
    ''
      if not set -q TMUX
        set ZJ_SESSIONS (${zel} list-sessions)
        set NO_SESSIONS (echo "$ZJ_SESSIONS" | wc -l)
        # ignore when no GUI
        if not set -q ZELLIJ; and set -q DISPLAY
          if test $NO_SESSIONS -ge 2
            ${zel} attach $(echo "$ZJ_SESSIONS" | ${lib.getExe' pkgs.skim "skim"})
          else
            ${zel} attach -c
          end

          if test "$ZELLIJ_AUTO_EXIT" = "true"
            kill $fish_pid
          end
        end
      end
    '';

  tmux-hook = let
    tmux = lib.getExe' self'.packages.tmux "tmux";
  in
    # fish
    ''
      # ignore when no GUI
      if not set -q TMUX; and set -q DISPLAY
        set TMUX_SESSIONS (${tmux} list-sessions)
        set NO_SESSIONS (echo "$TMUX_SESSIONS" | wc -l)
        if test $NO_SESSIONS -ge 2
          ${tmux} attach $(echo "$TMUX_SESSIONS" | ${lib.getExe' pkgs.skim "skim"})
        else
          ${tmux} new -A
        end
      end
    '';

  # TODO: maybe add override so standalone installs without this by default
  command-not-found-hook = let
    wrapper = pkgs.writeScript "command-not-found" ''
      #!${pkgs.bash}/bin/bash
      source ${pkgs.nix-index}/etc/profile.d/command-not-found.sh
      command_not_found_handle "$@"
    '';
  in
    # fish
    ''
      function __fish_command_not_found_handler --on-event fish_command_not_found
        ${wrapper} $argv
      end
    '';
in
  writeVendorConf "bartbie_config.fish"
  # fish
  ''
    source ${./files/load_plugin.fish}
    ${mapPlugins plugins}

    fenv source /etc/profile

    if status is-interactive
        source ${./files/pushd_mod.fish}
        ${builtins.readFile ./files/interactive.fish}

        source ${kanagawa}

        set -gx STARSHIP_CONFIG ${starship-config}
        ${lib.getExe pkgs.starship} init fish | source

        set -gx DIRENV_LOG_FORMAT = ""
        ${lib.getExe self'.packages.direnv} hook fish | source

        ${tmux-hook}

        ${command-not-found-hook}
    end
  ''
