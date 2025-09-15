{
  flake.modules.nixos.base = {
    security = {
      polkit.enable = true;
      rtkit.enable = true;
      protectKernelImage = false;
    };
  };
}
