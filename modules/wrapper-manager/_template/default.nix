{pkgs, ...}: {
  wrappers._TEMPLATE = {
    basePackage = pkgs._TEMPLATE;
    flags = [];
  };
}
