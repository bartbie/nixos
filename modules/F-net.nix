{ lib, ... }:
{
  flake.modules.nixos = {
    base = {
      networking = {
        firewall.enable = true;
        nftables.enable = true;
      };
      boot.kernel.sysctl = {
        # ignore ICMP redirects (MITM vector)
        "net.ipv4.conf.all.accept_redirects" = 0;
        "net.ipv4.conf.default.accept_redirects" = 0;
        "net.ipv6.conf.all.accept_redirects" = 0;
        "net.ipv6.conf.default.accept_redirects" = 0;

        # don't send redirects (you're not a router)
        "net.ipv4.conf.all.send_redirects" = 0;
        "net.ipv4.conf.default.send_redirects" = 0;

        # reject source-routed packets
        "net.ipv4.conf.all.accept_source_route" = 0;
        "net.ipv6.conf.all.accept_source_route" = 0;

        # SYN flood protection
        "net.ipv4.tcp_syncookies" = 1;

        # reverse path filtering (drops spoofed packets)
        "net.ipv4.conf.all.rp_filter" = 1;
        "net.ipv4.conf.default.rp_filter" = 1;
      };
    };
    pc = {
      networking = {
        networkmanager.enable = true;
        firewall = {
          allowPing = false;
          logReversePathDrops = true;
        };
      };
      # slows down boot time
      systemd.services.NetworkManager-wait-online.enable = false;
    };
    server =
      { config, ... }:
      {
        networking.firewall.allowPing = true;
        networking.firewall.allowedTCPPorts = [
          80
          443
        ];
      };
    ssh-client =
      { config, ... }:
      {
        programs.ssh = {
          startAgent = true;
          extraConfig =
            # sshconfig
            ''
              AddKeysToAgent yes
              IdentitiesOnly yes
              ControlMaster auto
              ControlPath /run/user/%i/ssh/%r@%h-%p
              ControlPersist 600
              ServerAliveInterval 60
              ServerAliveCountMax 3
            '';
        };
        systemd.user.tmpfiles.rules = [
          "d /run/user/%U/ssh 0700 - - -"
        ];
        services.gnome.gcr-ssh-agent.enable = false;
      };
    ssh-server =
      { config, ... }:
      {
        services.openssh = {
          enable = true;
          openFirewall = false;
        };
        users.users =
          let
            keys = config.meta.owner.keys.ssh;
          in
          {
            bartbie.openssh.authorizedKeys = { inherit keys; };
            root.openssh.authorizedKeys = { inherit keys; };
          };
      };
    ssh-server-nopasswd = {
      services.openssh.settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "prohibit-password";
      };
    };
  };
}
