{
  lib,
  self,
  inputs,
  nixonLib,
  ...
}: let
  rustToolchain = {
    channel,
    version,
    extraExtensions ? [],
  }: set:
    set.rust-bin.${channel}.${version}.default.override (p: {
      extensions = p.extensions ++ extraExtensions;
    });
in {
  perSystem = {
    self',
    pkgs,
    pkgs-unstable,
    ...
  } @ args: {
    devShells = let
      # CORRECTNESS:
      # only extend here to avoid unnecessary global overlay
      pkgs-unstable = args.pkgs-unstable.extend inputs.rust-overlay.overlays.default;

      rust-toolchain =
        rustToolchain {
          channel = "stable";
          version = "latest";
          extraExtensions = ["rust-src"];
        }
        pkgs-unstable;

      RUST_SRC_PATH = "${rust-toolchain}/lib/rustlib/src/rust/library";

      dev-pkgs = let
        flatten = l:
          l
          |> nixonLib.attrsets.bypath.flattenToListCond (x: !(lib.isDerivation x))
          |> builtins.map (x: x.value);
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
              (pkgs-unstable)
              rust-analyzer
              ;
            inherit rust-toolchain;
          };
        };
    in {
      default = self.devShells.${pkgs.hostPlatform.system}.devWithLix;
      wrapped = pkgs.mkShell {
        name = "nixon-wrapped-shell";
        packages = builtins.attrValues self'.packages;
      };
      dev = pkgs.mkShell {
        name = "nixon-dev-shell";
        inputsFrom = [
          self'.devShells.devWithLix
          self'.devShells.devWithNvim
        ];
      };
      devBasic = pkgs.mkShell {
        name = "nixon-dev-shell-basic";
        inherit RUST_SRC_PATH;
        buildInputs = dev-pkgs;
        nativeBuildInputs = builtins.attrValues {
          inherit
            (pkgs)
            pkg-config
            ;
        };
      };
    };
  };
}
