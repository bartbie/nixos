## Architecture

`flake.nix` - obv the entrypoint, but mostly used as a place to declare inputs

`system/` - default host-agnostic system config

`user/` - reusable host-agnostic modules

`packages/` - reusable host-agnostic repackaged wrappers

`hosts/` - host-specific configs

### No overlays except unstable
All packages are re-exported using nixosModules, so no point using overlay.

The only exception is nixpkgs-unstable.

### Modules Optionality
All modules are imported for each host - optional modules need to be declared disabled by default.

This arch makes it easy to enable new stuff for specific host, just modifly it's file.

### Special args
Inputs are passed to each host.

The flake itself is also passed as `self` to make module importing easier.
