{ lib, ... }:
{
  flake.modules.nixos = {
    pc = {
      networking = {
        networkmanager.enable = true;
        firewall = {
          enable = true;
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
      };
    ssh = {
      programs.ssh.startAgent = true;
      services.openssh.enable = true;
      services.gnome.gcr-ssh-agent.enable = false;
    };
  };
}
