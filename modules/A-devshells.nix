{
  perSystem =
    {
      self',
      pkgs,
      pkgs-unstable,
      ...
    }:
    let
      sh = self'.devShells;
    in
    {
      devShells = {
        wrappedOutputs = pkgs.mkShell {
          name = "nixon-shell-wrapped";
          packages = builtins.attrValues self'.packages;
        };

        default = sh.dev;

        devBase = pkgs.mkShell {
          name = "nixon-shell-devBase";
          packages = builtins.attrValues {
            inherit (self'.packages)
              git
              jujutsu
              ;
            inherit (pkgs)
              nil
              just
              deploy-rs
              nushell
              ;
            fmt = self'.formatter;
          };
        };

        dev = pkgs.mkShell {
          name = "nixon-shell-dev";
          inputsFrom = [
            sh.devBase
            sh.rust
            sh.qml
          ];
          env = { inherit (sh.rust) RUST_SRC_PATH; };
          shellHook = sh.qml.shellHook;
        };

        devFull = pkgs.mkShell {
          name = "nixon-shell-devFull";
          inputsFrom = [
            sh.dev
            sh.lix
            sh.nvim
          ];
        };
      };
    };
}
