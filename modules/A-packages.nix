let
  mk = l: {add = l;};
in {
  packages = {
    generic = {
      base = {pkgs, ...}:
        mk {
          inherit
            (pkgs)
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
      pc = {
        pkgs,
        pkgs-unstable,
        ...
      }:
        mk {
          inherit
            (pkgs-unstable)
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
    };
    nixos = {
      base = {pkgs, ...}:
        mk {
          inherit
            (pkgs)
            ltrace # library call monitoring
            strace # system call monitoring
            ;
        };
      server = {pkgs, ...}: mk {};
      pc = {pkgs, ...}:
        mk {
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
    };

    darwin = {
      pc = {pkgs, ...}: mk {inherit (pkgs);};
    };
  };
}
