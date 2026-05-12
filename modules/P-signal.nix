{
  flake.modules.darwin.pc =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.signal-desktop
      ];
    };
  flake.modules.nixos.pc =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.signal-desktop
      ];
    };
}
