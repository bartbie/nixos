{lib, ...}: let
  withMode = directory: mode: {
    inherit directory mode;
  };
  persist-dir = "/persist";
in {
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    mkdir /btrfs_tmp
    mount /dev/root_vg/root /btrfs_tmp
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

  fileSystems.${persist-dir}.neededForBoot = true;
  environment.persistence.${persist-dir} = {
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
    users.bartbie = {
      directories = [
        "Downloads"
        "Projects"
        "Eternal"
        # we will keep this stuff in Eternal/
        # "Music"
        # "Pictures"
        # "Documents"
        # "Videos"
        "VirtualBox VMs"
        (withMode ".gnupg" "0700")
        (withMode ".ssh" "0700")
        (withMode ".nixops" "0700")
        (withMode ".local/share/keyrings" "0700")
        ".local/share/direnv"
        ".mozilla"
        ".cargo"
        ".local/share/nvim"
        ".local/state/nvim"
        ".config/discord"
        "./tldrc/tldr"
      ];
      files = [
        ".local/share/fish/fish_history"
      ];
    };
  };
}
