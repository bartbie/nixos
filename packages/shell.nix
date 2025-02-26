{
  pkgs,
  lib,
  self,
  ...
}: let
  mkShell = name: pkgset:
    pkgs.mkShell {
      inherit name;
      buildInputs = builtins.attrValues pkgset;
    };
in {
  default = self.devShells.${pkgs.system}.dev;
  wrapped = mkShell "nixon-wrapped-shell" pkgs.nixon;
  all = mkShell "nixon-all-shell" (pkgs.nixon // pkgs.systemPackages);
  dev = mkShell "nixon-dev-shell" {
    inherit
      (pkgs)
      bartbie-nvim-nightly
      nil
      ;
    inherit
      (pkgs.nixon)
      git
      jujutsu
      zellij
      ;
    fmt = self.formatter.${pkgs.system};
  };
}
