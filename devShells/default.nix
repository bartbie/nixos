{
  pkgs,
  self,
  ...
}: let
  inherit (pkgs) lib;
  rust-toolchain = let
    toolchain = channel: ver: pkgs.rust-bin.${channel}.${ver}.default;
  in
    (toolchain "stable" "latest").override (p: {
      extensions = p.extensions ++ ["rust-src"];
    });

  dev-pkgs = let
    flatten = lib.flip lib.pipe [
      (self.lib.attrsets.bypath.flattenToListCond (x: !(lib.isDerivation x)))
      (builtins.map (x: x.value))
    ];
  in
    flatten {
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
      rust = {
        inherit
          (pkgs)
          gobject-introspection
          ;
        inherit
          (pkgs.unstable)
          rust-analyzer
          ;
        inherit rust-toolchain;
      };
    };

  mkDevShell = {
    name,
    extraPackages ? [],
  }: (pkgs.mkShell {
    inherit name;
    packages =
      dev-pkgs
      ++ extraPackages
      ++ (builtins.attrValues {
        inherit
          (pkgs)
          pkg-config
          ;
      });
    RUST_SRC_PATH = "${rust-toolchain}/lib/rustlib/src/rust/library";
  });
in {
  default = self.devShells.${pkgs.system}.devWithLix;
  wrapped = pkgs.mkShell {
    name = "nixon-wrapped-shell";
    packages = builtins.attrValues pkgs.nixon;
  };
  all = pkgs.mkShell {
    name = "nixon-all-shell";
    packages = builtins.attrValues (pkgs.nixon // pkgs.systemPackages);
  };
  dev = mkDevShell {
    name = "nixon-dev-shell";
  };
  devWithLix = mkDevShell {
    name = "nixon-dev-lix-shell";
    extraPackages = [
      self.inputs.lix-module.packages.${pkgs.system}.default
      pkgs.nh
      pkgs.nixos-rebuild
    ];
  };
  devWithNvim = mkDevShell {
    name = "nixon-dev-nvim-shell";
    extraPackages = [pkgs.nvim];
  };
}
