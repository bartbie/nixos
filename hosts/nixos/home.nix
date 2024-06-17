{
  config,
  pkgs,
  ...
}: let
  user = "bartbie";
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
    wezterm

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
    tree
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
  ];

  programs.git = {
    enable = true;
    userName = "bartbie37";
    userEmail = "bartbie37@gmail.com";
  };

  programs.starship = {
    enable = true;
    # custom settings
    # settings = {
    #   add_newline = false;
    #   aws.disabled = true;
    #   gcloud.disabled = true;
    #   line_break.disabled = true;
    # };
  };

  # programs.alacritty = {
  #   enable = true;
  #   # custom settings
  #   settings = {
  #     env.TERM = "xterm-256color";
  #     font = {
  #       size = 12;
  #       draw_bold_text_with_bright_colors = true;
  #     };
  #     scrolling.multiplier = 5;
  #     selection.save_to_clipboard = true;
  #   };
  # };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting # Disable greeting
    '';
    shellAliases = {
      vim = "nvim";
    };
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
}
