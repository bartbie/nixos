set -e

# cd to your config dir
pushd /etc/nixos

# Edit your config
$EDITOR .

if not git diff HEAD --quiet; then
    echo "No changes detected, exiting."
    popd
    exit 1
fi

# Autoformat your nix files
alejandra . >/dev/null

# Shows your changes
git diff HEAD

echo "NixOS Rebuilding..."

# Rebuild, output simplified errors, log trackebacks
(sudo nixos-rebuild switch) > nixos-switch.log 2>&1 || (rg --color=always -N error nixos-switch.log && exit 1)

# Get current generation metadata
current=$(nixos-rebuild list-generations | rg current)

# Commit all changes with the generation metadata
git commit -am "$current"

# Back to where you were
popd

# Notify all OK!
# notify-send -e "NixOS Rebuilt OK!" --icon=software-update-available
echo "NixOS Rebuilt OK!"
