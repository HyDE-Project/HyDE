#!/usr/bin/env bash
set -euo pipefail

config_dir=/etc/nixos
account_config="$config_dir/Scripts/iso/nixos/account.nix"
marker=/var/lib/hyde-account-choice.done
default_user="$(python3 -c 'import json; print(json.load(open("/etc/nixos/Scripts/iso/nixos/install-settings.json"))["defaultUser"])')"

printf '\nHyDE is ready. Create a normal user account? [Y/n] '
read -r create_user
if [[ "$create_user" =~ ^[Nn]$ ]]; then
    touch "$marker"
    exit 0
fi

while :; do
    printf 'Username [%s]: ' "$default_user"
    read -r username
    username="${username:-$default_user}"
    if [[ "$username" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] && ! id "$username" >/dev/null 2>&1; then
        break
    fi
    echo 'Invalid or already existing username; use lowercase letters, digits, _ or -.'
done

useradd --create-home --skel=/etc/skel --groups=wheel,networkmanager,video,input \
    --shell=/run/current-system/sw/bin/zsh "$username"
passwd "$username"

cat > "$account_config" <<NIX
{ ... }:
{
  users.users."$username" = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "input" ];
  };
  services.displayManager.autoLogin.user = "$username";
  services.displayManager.defaultSession = "hyprland";
}
NIX

NIX_CONFIG='experimental-features = nix-command flakes' nixos-rebuild switch --flake "$config_dir#hyde"
touch "$marker"
echo 'The HyDE account is ready; the desktop will start now.'
