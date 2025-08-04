{
  flake.modules.nixos.pc = {
    services.gnome.gnome-keyring.enable = true;
  };
}
