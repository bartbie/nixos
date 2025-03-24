{pkgs, ...}: {
  inherit
    (pkgs.unstable)
    ;
  inherit
    (pkgs)
    vim
    bartbie-nvim-nightly
    gcc
    wget
    ## gui
    discord
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
    lsd
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
    ;
}
