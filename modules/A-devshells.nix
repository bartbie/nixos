{
  lib,
  self,
  inputs,
  nixonLib,
  ...
}: {
  perSystem = {
    self',
    pkgs,
    ...
  }: {
    devShells = let
      rust-toolchain = let
        toolchain = channel: ver: pkgs.rust-bin.${channel}.${ver}.default;
      in
        (toolchain "stable" "latest").override (p: {
          extensions = p.extensions ++ ["rust-src"];
        });
      dev-pkgs = let
        flatten = lib.flip lib.pipe [
          (nixonLib.attrsets.bypath.flattenToListCond (x: !(lib.isDerivation x)))
          (builtins.map (x: x.value))
        ];
      in
        flatten {
          common = {
            inherit
              (self'.packages)
              git
              jujutsu
              ;
          };
          nix = {
            inherit
              (pkgs)
              nil
              ;
            fmt = self.formatter.${pkgs.hostPlatform.system};
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

      mkDevShell = args:
        (pkgs.mkShell {
          buildInputs = dev-pkgs;
          nativeBuildInputs = builtins.attrValues {
            inherit
              (pkgs)
              pkg-config
              ;
          };
          RUST_SRC_PATH = "${rust-toolchain}/lib/rustlib/src/rust/library";
        })
        // args;
    in {
      default = self.devShells.${pkgs.hostPlatform.system}.devWithLix;
      wrapped = pkgs.mkShell {
        name = "nixon-wrapped-shell";
        buildInputs = builtins.attrValues self'.packages;
      };
      dev = mkDevShell {
        name = "nixon-dev-shell";
      };
      devWithLix = mkDevShell {
        name = "nixon-dev-lix-shell";
        buildInputs =
          dev-pkgs
          ++ [
            inputs.lix-module.packages.${pkgs.system}.default
            pkgs.nh
            pkgs.nixos-rebuild
          ];
      };
    };
  };
}
