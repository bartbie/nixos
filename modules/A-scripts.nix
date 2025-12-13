{
  lib,
  nixonLib,
  ...
}: let
  mkScripts = pkgs: let
    inherit (pkgs) writers;
    mkBash = script: writers.writeBashBin script (builtins.readFile (nixonLib.scriptsPath + /${script}.sh));
    mkNu = script: writers.writeNuBin script (builtins.readFile (nixonLib.scriptsPath + /${script}.nu));
  in {
    # home-export = mkBash "home-export";
    rand-wp = mkBash "rand-wp";
    linktree = mkBash "linktree";
    rebuild = mkNu "rebuild";
    "comma" = mkBash ",";
    "dcomma" = mkBash ",,";
    "browser" = mkBash "browser";
  };
in {
  hosts.shared = {pkgs, ...}: {
    environment.systemPackages = builtins.attrValues (mkScripts pkgs);
  };
  perSystem = {pkgs, ...}: {
    packages = mkScripts pkgs;
  };
}
