{lib, ...}: let
  partitions = {
    boot = {
      size = "1M";
      type = "EF02"; # for grub MBR
    };
    ESP = {
      size = "1G";
      type = "EF00";
      content = {
        type = "filesystem";
        format = "vfat";
        mountpoint = "/boot";
        mountOptions = ["umask=0077"];
      };
    };
    root = {
      size = "100%";
      content = {
        type = "lvm_pv";
        vg = "root_vg";
      };
    };
  };

  lvs = {
    swap = {
      size = "32G";
      content = {
        type = "swap";
      };
    };
    root = {
      size = "50%FREE";
      content = {
        type = "btrfs";
        extraArgs = ["-f"];

        subvolumes = {
          "/root" = {
            mountpoint = "/";
          };

          "/persist" = {
            mountOptions = ["subvol=persist" "noatime"];
            mountpoint = "/persist";
          };

          "/nix" = {
            mountOptions = ["subvol=nix" "noatime"];
            mountpoint = "/nix";
          };
        };
      };
    };
    vm = {
      size = "50%FREE";
    };
  };
in {
  disko.devices = {
    disk.disk0 = {
      device = lib.mkDefault "/dev/nvme0n1";
      type = "disk";
      content = {
        type = "gpt";
        inherit partitions;
      };
    };
    lvm_vg.root_vg = {
      type = "lvm_vg";
      inherit lvs;
    };
  };
}
