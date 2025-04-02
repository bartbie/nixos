# Nixon

## Architecture

`flake.nix` - obv the entrypoint, but mostly used as a place to declare inputs.

`lib/` - flake's library, independent of `pkgs`.

`hosts/` - host-specific configs.

`modules/` - reusable host-agnostic modules split based on respective environments.

`packages/` - `outputs.{packages, overlays, devShells}`

`scripts/` - custom programs and scripts.


### Wrapped packages
Virtually all package configurations are defined as standalone wrappers via [wrapper-manager-fds](https://github.com/foo-dogsquared/nix-module-wrapper-manager-fds).

Those are then loaded by `nixos` modules, flake's `packages`, `overlays` and `devShells`.


### Modules Optionality
Each hosts imports `outputs.nixosModules.nixon` and enables `nixon.core` by default.

Besides that, almost all modules are declared disabled by default.


### Special args
The flake itself (`self`) is also passed as `flake` to make code reuse easier.

Nixon's lib also provides its own `modulesPath` if needed;

`wrapper-manager` environment gets passed `lib.theme` as `theme` to make color-scheme configuring shorter;


## Disko & Impermanence

By default Impermanence is disabled; this can be configured via `nixon.impermanence`.

Disko will get enabled for a host if any devices are defined under its environment.
