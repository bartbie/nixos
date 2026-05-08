flake := env('FLAKE', justfile_directory())

[private]
default:
    @just --list --unsorted
 
boot *args:
    nh os boot --accept-flake-config {{ args }}

build-host host=`hostname` *args:
    nh os build --accept-flake-config .#{{ host }} {{ args }}

switch *args:
    nh os switch --accept-flake-config {{ args }}

fmt *args:
    nix fmt --accept-flake-config {{ args }}

dev target="" *args:
    nom develop --accept-flake-config {{ args }} .#{{ target }} -c $SHELL

repl-host host=`hostname`:
    nix repl .#nixosConfigurations.{{ host }}

update *input:
    nix flake update {{ input }} \
      --flake {{ flake }} \
      --commit-lock-file \
      --commit-lockfile-summary "flake: update {{ if input == "" { "all" } else { input } }}"

update-nvim: (update "nvim")

cache-packages:
    nix flake show --json \
    | jq -r '.packages."x86_64-linux" | keys[]' \
    | xargs -I{} sh -c 'nix build .#{} --accept-flake-config --flake {{ flake }} --no-link --print-out-paths | cachix push bartbie'

cache-packages-all-systems:
    nix flake show --json \
    | jq -r '.packages."x86_64-linux" | keys[]' \
    | xargs -I{} sh -c 'nix build .#{} --accept-flake-config --no-link --print-out-paths --all-systems | cachix push bartbie'

run cmd:
    XDG_DATA_DIRS="$(nix build .#{{ cmd }} --print-out-paths --no-link)/share:$XDG_DATA_DIRS" nix run .#{{ cmd }}

clean-results:
    rm {{ flake }}/result*

deploy host *args:
    deploy .#{{ host }} {{args}} --skip-checks

provision config-name ip *args:
    nix run github:nix-community/nixos-anywhere \
    -- \
    --flake {{ flake }}#{{ config-name }} \
    --target-host root@{{ ip }} \
    --option extra-experimental-features pipe-operators \
    {{ args }}

provision-with-hw config-name ip *args:
    @just provision {{ config-name }} {{ ip }} --generate-hardware-config nixos-generate-config {{ flake }}/modules/A-hosts/{{ config-name }}/hardware-configuration.nix {{ args }}
