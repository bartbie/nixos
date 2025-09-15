{
  lib,
  self,
  ...
}: let
  # TODO: make this options in future
  # maybe make them meta internal options
  rootMountPath = "/dev/root_vg/root";
  storagePath = "/persist";

  withMode = directory: mode: {
    inherit directory mode;
  };
in {
  flake.modules.nixos = {
    impermanence-pc = {config, ...}: {
      environment.persistence.${storagePath} = {
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
        users.${config.meta.owner.username} = let
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
            "tldrc/tldr"
            (withMode ".gnupg" "0700")
            (withMode ".ssh" "0700")
            (withMode ".nixops" "0700")
            # look ma, it's lisp
            (withMode (share "keyrings") "0700")
            (share "direnv")
            (share "nvim")
            (state "nvim")
            (cache "bat")
            (cache "nix-index")
            (share "Steam")
            ".steam"
            (conf "discord")
            (conf "discordcanary")
            (conf "spotify")
            (cache "spotify")
            (share "TelegramDesktop")
            (cache "swww")
          ];
          files = [
            (share "fish/fish_history")
          ];
        };
      };
    };

    impermanence-btrfs = {pkgs, ...}: let
      # INFO: added after 24.05
      # https://github.com/NixOS/nixpkgs/pull/373287
      osPath = pkgs.unstable.lib.types.pathWith {
        inStore = false;
        absolute = true;
      };
    in {
      boot.initrd.postDeviceCommands = lib.mkAfter ''
        mkdir /btrfs_tmp
        mount ${rootMountPath} /btrfs_tmp
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

      # Systemd service to create baseline snapshot
      systemd.services.create-baseline-snapshot = {
        description = "Create baseline snapshot for tracking new files";
        after = ["local-fs.target" "remote-fs.target"];
        wantedBy = ["multi-user.target"];
        unitConfig = {
          RequiresMountsFor = "/";
        };
        serviceConfig = self.lib.systemd.hardenServiceConfig {
          Type = "oneshot";
          ExecStart = let
            btrfs = lib.getExe' pkgs.btrfs-progs "btrfs";
            script =
              pkgs.writeShellScript "create-baseline-snapshot"
              #sh
              ''
                set -euxo pipefail
                echo "Current working directory: $(pwd)"
                # echo "Filesystem info:"
                # findmnt /
                echo "Checking if / is a btrfs subvolume:"
                ${btrfs} subvolume show / || { echo "Not a subvolume"; exit 1; }
                FILENAME="/.btrfs-snapshot-$(date +%Y%m%d-%H%M%S)"
                echo "Creating snapshot $FILENAME"
                ${btrfs} subvolume snapshot -r / "$FILENAME"
              '';
          in "${script}";
          # run as root
          User = "root";
          Group = "root";

          # allow subvolume operations
          CapabilityBoundingSet = ["CAP_SYS_ADMIN" "CAP_DAC_OVERRIDE"];
          # allow seeing block devices
          PrivateDevices = false;
          # allow access to block devices
          DevicePolicy = "auto";
          # allow access filesystem structures
          PrivateUsers = false;
          # allow access to filesystem proc entries
          ProcSubset = "all";
          # allow touching kernel tunables
          ProtectKernelTunables = false;
          # allow privileged syscalls for filesystem operations
          SystemCallFilter = ["@system-service" "@privileged"];
          # may allow namespace operations for subvolumes
          RestrictNamespaces = false;
        };
      };

      fileSystems.${storagePath}.neededForBoot = true;
    };
  };
}
