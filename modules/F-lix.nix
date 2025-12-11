{lib, ...}: let
  lix-version = "lix_2_94";
  downstreamers = [
    "nixpkgs-review"
    "nix-eval-jobs"
    "nix-fast-build"
    "colmena"
    "lix"
  ];
in {
  # Overlay the downstreamers in unstable and disable in stable
  overlays = {
    stable = [
      (_: prev:
        lib.genAttrs downstreamers (n:
          lib.recursiveUpdate prev.${n} {meta.available = false;}))
    ];
    unstable = [
      (_: prev:
        prev.lixPackageSets.${lix-version}
        |> lib.getAttrs (lib.flatten [downstreamers]))
    ];
  };
  hosts.shared = {pkgs-unstable, ...}: {
    nix.package = pkgs-unstable.lix;
  };

  perSystem = {
    pkgs,
    pkgs-unstable,
    system,
    self',
    ...
  }: {
    devShells.devWithLix = pkgs.mkShell {
      name = "nixon-dev-lix-shell";
      packages = [
        pkgs-unstable.lix
        pkgs.nh
        pkgs.nixos-rebuild
      ];
      inputsFrom = [self'.devShells.devBasic];
    };
  };
}
