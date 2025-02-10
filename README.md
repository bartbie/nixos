# Nixon

## Architecture

`flake.nix` - obv the entrypoint, but mostly used as a place to declare inputs

`hosts/` - host-specific configs

`modules/` - reusable host-agnostic modules

`packages/` - reusable host-agnostic repackaged wrappers

### Avoid overlays
They add eval perf cost, we can import them via module system or flake exports if needed.
<!-- ### No overlays except unstable -->
<!-- All packages are re-exported using nixosModules, so no point using overlay. -->
<!---->
<!-- The only exception is nixpkgs-unstable. -->

### Modules Optionality
All modules are imported for each host - optional modules need to be declared disabled by default.

This arch makes it easy to enable new stuff for specific host, just modify it's file.

### Special args
Inputs are passed to each host.

The flake itself is also passed as `self` to make module importing easier.
