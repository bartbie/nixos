{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.nixon.impermanence;
  withMode = directory: mode: {
    inherit directory mode;
  };
  # INFO: added after 24.05
  # https://github.com/NixOS/nixpkgs/pull/373287
  osPath = pkgs.unstable.lib.types.pathWith {
    inStore = false;
    absolute = true;
  };
in {
  options.nixon.impermanence = {
    enable = mkEnableOption "impermanence";
    storagePath = lib.mkOption {
      type = osPath;
      default = "/persist";
    };
    # terrible name eh
    rootMountPath = lib.mkOption {
      type = osPath;
      default = "/dev/root_vg/root";
    };
  };
  config = lib.mkIf cfg.enable {
    boot.initrd.postDeviceCommands = lib.mkAfter ''
      mkdir /btrfs_tmp
      mount ${cfg.rootMountPath} /btrfs_tmp
      if [[ -e /btrfs_tmp/root ]]; then
          mkdir -p /btrfs_tmp/old_roots
          timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
          mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
      fi

      delete_subvolume_recursively() {
          IFS=$'\n'
          for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
              delete_subvolume_recursively "/btrfs_tmp/$i"
          done
          btrfs subvolume delete "$1"
      }

      for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
          delete_subvolume_recursively "$i"
      done

      btrfs subvolume create /btrfs_tmp/root
      umount /btrfs_tmp
    '';

    fileSystems.${cfg.storagePath}.neededForBoot = true;
    environment.persistence.${cfg.storagePath} = {
      hideMounts = true;
      directories = [
        "/var/log"
        "/var/lib/bluetooth"
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"
        "/etc/NetworkManager/system-connections"
        "/etc/nixos"
        {
          directory = "/var/lib/colord";
          user = "colord";
          group = "colord";
          mode = "u=rwx,g=rx,o=";
        }
      ];
      files = [
        "/etc/machine-id"
      ];
      users.bartbie = let
        state = x: ".local/state/${x}";
        share = x: ".local/share/${x}";
        cache = x: ".cache/${x}";
        conf = x: ".config/${x}";
      in {
        directories = [
          "Downloads"
          "Projects"
          /*
          we will keep this stuff in Eternal/
          "Music"
          "Pictures"
          "Documents"
          "Videos"
          */
          "Eternal"

          # "VirtualBox VMs"
          ".mozilla"
          ".cargo"
          "./tldrc/tldr"
          (withMode ".gnupg" "0700")
          (withMode ".ssh" "0700")
          (withMode ".nixops" "0700")
          # look ma, it's lisp
          (withMode (share "keyrings") "0700")
          (share "direnv")
          (share "nvim")
          (state "nvim")
          (conf "discord")
          (cache "bat")
        ];
        files = [
          (share "fish/fish_history")
        ];
      };
    };
  };
}
