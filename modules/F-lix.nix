{lib, ...}: let
  lix-version = "lix_2_94";
  downstreamers = [
    "nixpkgs-review"
    "nix-eval-jobs"
    "nix-fast-build"
    "colmena"
  ];
in {
  overlays = {
    stable = [
      (_: prev:
        lib.genAttrs downstreamers (n:
          lib.recursiveUpdate prev.${n} {meta.available = false;}))
    ];
    unstable = [
      (_: prev: lib.getAttrs downstreamers prev)
      # # Make sure lix version is correct, or polyfill it with unstable
      # (_: prev: let
      #   polyfill = unstable.${prev.system}.lixPackageSets.${lix-version};
      #   set = prev.lixPackageSets.${lix-version} or polyfill;
      # in {
      #   # polyfill set if missing, noop otherwise
      #   lixPackageSets.${lix-version} = set;
      #   inherit
      #     (set)
      #     nixpkgs-review
      #     nix-eval-jobs
      #     nix-fast-build
      #     colmena
      #     ;
      # })
    ];
  };
  hosts.shared = {pkgs-unstable, ...}: {
    nix.package = pkgs-unstable.lixPackageSets.${lix-version}.lix;
  };
}
