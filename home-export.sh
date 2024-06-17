set -e

#which config

if [ "$*" -ge 1 ]
then
    config=".#$1"
else
    config="."
fi

# current dir
where=${2:-$(pwd)}

# cd to your config dir
pushd /etc/nixos

# run home-manager
home-manager build --flake "$config"

# copy
cp -L ./result/home-files "$where"

# hide rest
unlink result

popd

echo "copied to $where/home-files"
