{lib, ...}: let
  prime = {
    amdgpuBusId = "PCI:15:0:0";
    nvidiaBusId = "PCI:01:0:0";
  };
  # keep in sync after nixpkgs lock update
  driver-versions = {
    stable = "580.105";
    unstable = "590.48";
  };
  useStableDriver = false;
  # modified slightly from
  # https://github.com/TLATER/dotfiles/tree/dd079c7c0faa5ff1b9af7e23943c9443c0cc61dd/nixos-modules/nvidia
  # thank you TLATER.
in {
  hosts.nixos.lyndon = lib.mkMerge [
    # extra
    {
      boot.blacklistedKernelModules = ["nouveau"];

      environment.sessionVariables = {
        __GL_THREADED_OPTIMIZATION = "1";
        __GL_SHADER_CACHE = "1";
        # Controls if Adaptive Sync should be used. Recommended to set as “0” to avoid having problems on some games.
        __GL_VRR_ALLOWED = "0";
      };
    }
    # driver
    ({
      config,
      pkgs-unstable,
      ...
    }: {
      hardware.nvidia.package =
        if useStableDriver
        then config.boot.kernelPackages.nvidiaPackages.latest
        else (pkgs-unstable.linuxPackagesFor config.boot.kernelPackages.kernel).nvidiaPackages.beta;

      assertions = let
        eqMajorMinor = supposed: {version, ...} @ _package: let
          mm = v: lib.take 2 (builtins.splitVersion v);
        in
          (mm supposed) == (mm version);
        expected =
          driver-versions.${
            if useStableDriver
            then "stable"
            else "unstable"
          };
        actual = config.hardware.nvidia.package;
      in
        lib.singleton {
          assertion = eqMajorMinor expected actual;
          message = "Nvidia driver version mismatch. ${expected} vs actual ${actual.version}. Update ${__curPos.file}.";
        };
    })
    # kernel assertion
    # ({
    #   pkgs,
    #   config,
    #   ...
    # }: {
    #   assertions = lib.singleton {
    #     assertion =
    #       lib.strings.compareVersions config.boot.kernelPackages.kernel.version pkgs.linuxKernel.kernels.linux_default.version
    #       <= 0;
    #     message = "The nvidia driver can only support the LTS kernel.";
    #   };
    # })
    # general
    {
      services.xserver.videoDrivers = ["nvidia"];

      hardware.nvidia = {
        # This will no longer be necessary when
        # https://github.com/NixOS/nixpkgs/pull/326369 hits stable
        modesetting.enable = true;
        # Power management is nearly always required to get nvidia GPUs to
        # behave on suspend, due to firmware bugs.
        powerManagement.enable = true;
        # The open driver is recommended by nvidia now, see
        # https://download.nvidia.com/XFree86/Linux-x86_64/565.57.01/README/kernel_open.html
        open = true;

        dynamicBoost.enable = true;
      };

      boot.extraModprobeConfig = let
        options = [
          "NVreg_UsePageAttributeTable=1"
          "NVreg_RegistryDwords=RMUseSwI2c=0x01;RMI2cSpeed=100"
        ];
      in "options nvidia ${lib.join " " options}";
    }
    # prime
    ({
      config,
      pkgs,
      ...
    }: {
      hardware.nvidia = {
        prime = lib.mkMerge [
          prime
          {offload.enable = true;}
          {offload.enableOffloadCmd = true;}
        ];
        powerManagement.finegrained = true;
      };

      # Set up a udev rule to create named symlinks for the pci paths.
      #
      # This is necessary because wlroots splits the DRM_DEVICES on
      # `:`, which is part of the pci path.
      services.udev.packages = let
        normalizeHex = n: i: i |> lib.fixedWidthNumber n |> lib.toLower;
        isDecimal = x: builtins.tryEval (lib.toIntBase10) |> (x: x.success);

        # "PCI:15:0:0" -> "pci-0000:15:00.0-card"
        toPciPath = xorgBusId: let
          split = lib.splitString ":" xorgBusId;
          components = lib.drop 1 split;
          compAt = builtins.elemAt components;

          # Apparently the domain is practically always set to 0000
          domain = "0000";
          # 00-FF hex
          bus = compAt 0 |> normalizeHex 2;
          # 00-1F hex
          device = compAt 1 |> normalizeHex 2;
          # 00-07 hex ie always decimal
          function = compAt 2 |> normalizeHex 1;
        in
          assert isDecimal function;
          assert (builtins.elemAt split 0) == "PCI"; "dri/by-path/pci-${domain}:${bus}:${device}.${function}-card";

        pCfg = config.hardware.nvidia.prime;
        igpuPath = toPciPath (
          if pCfg.intelBusId != ""
          then pCfg.intelBusId
          else pCfg.amdgpuBusId
        );
        dgpuPath = toPciPath pCfg.nvidiaBusId;
      in
        lib.singleton (
          pkgs.writeTextDir "lib/udev/rules.d/61-gpu-offload.rules" ''
            SYMLINK=="${igpuPath}", SYMLINK+="dri/igpu1"
            SYMLINK=="${dgpuPath}", SYMLINK+="dri/dgpu1"
          ''
        );
    })
    # decompat
    {
      environment.variables = let
        WLR_DRM_DEVICES = "/dev/dri/igpu1:/dev/dri/dgpu1";
      in {
        inherit WLR_DRM_DEVICES;
        # too much lag lol
        # AQ_DRM_DEVICES = WLR_DRM_DEVICES;
      };
    }
    # further fixes
    {
      boot.initrd.kernelModules = ["nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm"];
      # boot.kernelParams = [
      #   "nvidia.NVreg_EnableGpuFirmware=0"
      # ];
    }
  ];
}
