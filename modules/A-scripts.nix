{
  lib,
  nixonLib,
  ...
}:
let
  mkScripts =
    pkgs:
    let
      inherit (pkgs) writers;
      mkBash =
        script: writers.writeBashBin script (builtins.readFile (nixonLib.scriptsPath + /${script}.sh));
      mkNu = script: writers.writeNuBin script (builtins.readFile (nixonLib.scriptsPath + /${script}.nu));
    in
    {
      # home-export = mkBash "home-export";
      rand-wp = mkBash "rand-wp";
      linktree = mkBash "linktree";
      rebuild = mkNu "rebuild";
      "comma" = mkBash ",";
      "dcomma" = mkBash ",,";
      "browser" = mkBash "browser";
      "toggle-cam-mic" = mkBash "toggle-cam-mic";
    };
in
{
  perSystem =
    { pkgs, ... }:
    {
      packages = mkScripts pkgs;
    };
  flake.modules = {
    nixos.base =
      { self', ... }:
      {
        environment.systemPackages = builtins.attrValues {
          inherit (self'.packages)
            linktree
            ;
        };
      };
    nixos.pc =
      { self', ... }:
      {
        environment.systemPackages = builtins.attrValues {
          inherit (self'.packages)
            comma
            dcomma
            browser
            rebuild
            toggle-cam-mic
            ;
        };
      };
    darwin.base =
      { self', ... }:
      {
        environment.systemPackages = builtins.attrValues {
          inherit (self'.packages)
            comma
            dcomma
            rebuild
            ;
        };
      };
  };
}
