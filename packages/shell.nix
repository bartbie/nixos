{
  pkgs,
  lib,
  self,
  ...
}: let
  mkShell = name: pkgset:
    pkgs.mkShell {
      inherit name;
      buildInputs = pkgset;
    };
  flatten = lib.flip lib.pipe [
    (self.lib.attrsets.bypath.flattenToListCond (x: !(lib.isDerivation x)))
    (builtins.map (x: x.value))
  ];
  dev-pkgs = flatten {
    common = {
      inherit
        (pkgs.nixon)
        git
        jujutsu
        ;
    };
    nix = {
      inherit
        (pkgs)
        nil
        ;
      fmt = self.formatter.${pkgs.system};
    };
    nushell = {
      inherit
        (pkgs)
        nushell
        ;
    };
    rust = let
      toolchain = channel: ver: pkgs.rust-bin.${channel}.${ver}.default;
    in {
      inherit
        (pkgs.unstable)
        rust-analyzer
        ;
      rs = (toolchain "stable" "latest").override (p: {
        extensions = p.extensions ++ ["rust-src"];
      });
    };
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
