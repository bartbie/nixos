{lib, ...}: let
  common = pkgs: {
    inherit
      (pkgs)
      nvim
      gcc
      vim
      wget
      # archives
      p7zip
      unzip
      xz
      zip
      # utils
      file
      fd
      fzf
      gawk
      gnused
      gnutar
      jq
      ripgrep
      tldr
      tokei
      which
      ipcalc # it is a calculator for the IPv4/v6 addresses
      # system call
      lsof # list open files
      ;
  };

  perClass = pkgs: {
    nixos = {
      inherit
        (pkgs)
        ltrace # library call monitoring
        strace # system call monitoring
        ;
    };

    darwin = {
      inherit
        (pkgs)
        ;
    };
  };

  perTag = pkgs: {
    pc = {
      inherit
        (pkgs.unstable)
        ;
      inherit
        (pkgs)
        ## gui
        discord-canary
        spotify
        telegram-desktop
        ## rest
        fastfetch
        ffmpeg
        lazygit
        glow
        zoxide
        # nix
        alejandra
        nix-output-monitor
        nnn
        # networking
        aria2 # A lightweight multi-protocol & multi-source command-line download utility
        btop # replacement of htop/nmon
        dnsutils # `dig` + `nslookup`
        iftop # network monitoring
        iperf3
        ldns # replacement of `dig`, it provide the command `drill`
        mtr # A network diagnostic tool
        nmap # A utility for network discovery and security auditing
        socat # replacement of openbsd-netcat

        # misc
        cowsay
        # langs
        rustup
        ;
    };
    server = {};
  };

  nixos-pc = pkgs: {
    inherit
      (pkgs)
      # clipboard
      wl-clipboard
      clipse
      # gui
      qimgv
      # utils
      # system tools
      sysstat
      usbutils # lsusb
      ethtool
      lm_sensors # for `sensors` command
      pciutils # lspci
      iotop # io monitoring
      ;
  };

  concatPkgs = pkgs: fns:
    fns
    |> builtins.map (fn: fn pkgs)
    |> builtins.map builtins.attrValues
    |> lib.concatLists;

  switch = name: attrsFn: pkgs: (attrsFn pkgs).${name} or {};

  mapTags = tags: builtins.map (t: switch t perTag) tags;

  mkPkgs = config: pkgs: rest: concatPkgs pkgs ([(mapTags config.meta.tags) (switch config.meta.class perClass) common] ++ rest);
  mkMod = rest: ({
    pkgs,
    config,
    ...
  }: {
    environment.systemPackages = mkPkgs pkgs config rest;
  });
in {
  flake.modules = {
    nixos = {
      pc = mkMod [nixos-pc];
      server = mkMod [];
    };
    darwin.base = mkMod [];
  };
}
#TODO
#   wrapper-manager = {
#     packages = flake.wrapperManagerModules.list.base;
#     sharedModules = [flake.wrapperManagerModules.options];
#     extraSpecialArgs = {
#       inherit flake;
#       inherit (flake.lib) theme;
#     };
#     enableInstall = cfg.wrapped.enable;
#   };

