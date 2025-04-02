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

  dev-pkgs = {
    inherit
      (pkgs)
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
in {
  default = self.devShells.${pkgs.system}.dev;
  wrapped = mkShell "nixon-wrapped-shell" pkgs.nixon;
  all = mkShell "nixon-all-shell" (pkgs.nixon // pkgs.systemPackages);
  dev = mkShell "nixon-dev-shell" dev-pkgs;
  devWithNvim = mkShell "nixon-dev-shell" (dev-pkgs
    // {
      inherit
        (pkgs)
        bartbie-nvim-nightly
        ;
    });
}
