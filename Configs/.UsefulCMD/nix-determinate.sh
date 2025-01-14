#!/bin/sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix |
  sh -s -- install
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install
mkdir -p GitHub
cd GitHub
git clone --depth 1 https://github.com/niumination/hyprnix.git
cd hyprnix
nix flake update
home-manager switch --flake .#hyprzaryu
