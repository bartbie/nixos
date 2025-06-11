# this gets imported both by `modules/wrapper-manager` and `packages/`
# they have different inputs (modules vs not) so keep the args simple for compatibility
{
  lib,
  flake,
  ...
}: let
  manual = {
  };
in
  {
    base = flake.lib.import.importsToAttrs (
      flake.lib.findImports {
        from = ./default.nix;
        defaultOnly = true;
        ignored = builtins.attrValues manual;
      }
    );
  }
  // manual
