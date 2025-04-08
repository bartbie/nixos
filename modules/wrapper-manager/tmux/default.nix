{
  pkgs,
  lib,
  ...
}: let
  plugins = builtins.attrValues {
    inherit (pkgs.tmuxPlugins);
  };
  config =
    # tmux
    ''
      set -g mouse on
      set-option -g focus-events on
      set-option -sa terminal-features ',*:RGB'
      set -g status-keys vi
      set -g mode-keys vi
      # start new session if trying to attaching while none
      new-session
      set -s escape-time 10
      setw -g clock-mode-style 24
      set  -g base-index      1
      setw -g pane-base-index 1
      set-option -g renumber-windows on
      set -s set-clipboard on
      set -g default-command "''${SHELL}"
    '';
  mapPlugins = lib.flip lib.pipe [
    (map (plugin: "run-shell ${plugin.rtp}"))
    (lib.concatStringsSep "\n")
  ];
in {
  wrappers.tmux = {
    arg0 = lib.getExe' pkgs.tmux "tmux";
    prependArgs = [
      "-f"
      (pkgs.writeText "tmux-conf" ''
        ${config}

        ${mapPlugins plugins}
      '')
    ];
  };
}
