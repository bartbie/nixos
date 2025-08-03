# Nixon

## Architecture

> [!IMPORTANT]
> This is in process of getting refactored to flake-parts and dendritic pattern

`flake.nix` - obv the entrypoint, but mostly used as a place to declare inputs.

`lib/` - flake's library, independent of `pkgs`.

`hosts/` - host-specific configs.

`modules/` - reusable host-agnostic modules split based on respective environments.

`packages/` - `outputs.{packages, overlays}`, `systemPackages`

`devShells/` - `outputs.devShells`

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

`wrapper-manager` environment gets passed:

- `lib.theme` as `theme` to make color-scheme configuring shorter;
- `overrideArgs` to get args passed by consumers via `.override` to pass to base package
- `wrapperArgs` to get args passed by consumers via `.override {wrapperArgs = {...};}` for its own usage


## Disko & Impermanence

To add their dependency modules add `"disko"` and/or `"impermanence"` tags to a host.

By default Impermanence is disabled; this can be configured via `nixon.impermanence`.
