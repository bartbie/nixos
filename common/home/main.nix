{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.mine.home;
in {
  imports = [
    ./programs/starship.nix
  ];
  options = {
    mine.home.user = with lib;
      mkOption {
        type = types.str;
      };
  };
  config = let
    inherit (cfg) user;
  in {
    home.username = user;
    home.homeDirectory = "/home/${user}";

    home.packages = with pkgs; [
      ## same as systemPackages
      vim
      gcc
      wget

      ## gui
      discord
      firefox-devedition
      spotify
      telegram-desktop

      ## rest

      # archives
      p7zip
      unzip
      xz
      zip

      # nix
      alejandra
      nix-output-monitor

      # utils
      bat
      fastfetch
      file
      fzf
      gawk
      glow
      gnused
      gnutar
      jq
      lazygit
      nnn
      ripgrep
      tldr
      erdtree
      which
      zoxide

      # system call
      lsof # list open files
      ltrace # library call monitoring
      strace # system call monitoring

      # networking
      aria2 # A lightweight multi-protocol & multi-source command-line download utility
      btop # replacement of htop/nmon
      dnsutils # `dig` + `nslookup`
      iftop # network monitoring
      iotop # io monitoring
      ipcalc # it is a calculator for the IPv4/v6 addresses
      iperf3
      ldns # replacement of `dig`, it provide the command `drill`
      mtr # A network diagnostic tool
      nmap # A utility for network discovery and security auditing
      socat # replacement of openbsd-netcat

      # system tools
      ethtool
      lm_sensors # for `sensors` command
      pciutils # lspci
      sysstat
      usbutils # lsusb

      # misc
      cowsay

      # fonts
      (nerdfonts.override {fonts = ["JetBrainsMono" "Terminus"];})
    ];

    fonts.fontconfig.enable = true;

    programs.tmux = {
      enable = true;
      extraConfig =
        # sh
        ''
          set -g mouse on
          set-option -g focus-events on
          set-option -sg escape-time 10
          set-option -sa terminal-features ',*:RGB'
        '';
    };

    programs.wezterm = {
      enable = true;
      extraConfig =
        # lua
        ''
          local wezterm = require("wezterm");
          return {
              hide_tab_bar_if_only_one_tab = true, -- i never use tabs but it may happen accidentally
              -- enable_tab_bar = false,
              window_background_opacity = 0.96,
              color_scheme = "kanagawabones",
              font = wezterm.font("JetBrains Mono Nerd Font");
          };
        '';
    };

    home.shellAliases = {
      vim = "nvim";
      tree = "erd --suppress-size --icons";
      treeh = "tree --hidden --ignore-git --ignore-git-ignore";
      tre = "tree -l 2";
      treh = "treeh -l 2";
    };

    home.sessionVariables = {
      # If your cursor becomes invisible
      WLR_NO_HARDWARE_CURSORS = "1";
      # Hint electron apps to use wayland
      NIXOS_OZONE_WL = "1";
    };

    programs.fish = {
      enable = true;
      interactiveShellInit =
        # sh
        ''
          set fish_greeting # Disable greeting
        '';
    };

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # This value determines the home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update home Manager without changing this value. See
    # the home Manager release notes for a list of state version
    # changes in each release.
    home.stateVersion = "23.11";

    # Let home Manager install and manage itself.
    programs.home-manager.enable = true;
  };
}
