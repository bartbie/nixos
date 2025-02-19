{pkgs, ...}: {
  wrappers.jujutsu = {
    basePackage = pkgs.unstable.jujutsu;
    flags = [
      "--config-file"
      # TODO
    ];
  };
}
