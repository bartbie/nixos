{pkgs, ...}: {
  wrappers.zellij = {
    basePackage = pkgs.zellij;
    flags = [
      "--config"
      ./config.kdl
    ];
  };
}
