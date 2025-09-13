{lib, ...}: {
  flake.modules = {
    nixos.base = {
      wrapper-manager = {
        documentation = {
          manpage.enable = true;
        };
      };
    };
  };
}
