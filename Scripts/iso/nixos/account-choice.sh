#!/usr/bin/env bash
set -euo pipefail

config_dir=/etc/nixos
account_config="$config_dir/Scripts/iso/nixos/account.nix"
marker=/var/lib/hyde-account-choice.done
default_user="$(python3 -c 'import json; print(json.load(open("/etc/nixos/Scripts/iso/nixos/install-settings.json"))["defaultUser"])')"

while :; do
    printf 'Username [%s]: ' "$default_user"
    if ! read -r -t 300 username; then
        echo 'Account setup timed out; no root desktop session will be started.'
        exit 1
    fi
    username="${username:-$default_user}"
    if [[ "$username" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]; then
        if ! id "$username" >/dev/null 2>&1 || [[ "$(getent passwd "$username" | cut -d: -f6)" == "/home/$username" ]]; then
            break
        fi
    fi
    echo 'Invalid or already existing username; use lowercase letters, digits, _ or -.'
done

if ! id "$username" >/dev/null 2>&1; then
    useradd --create-home --skel=/etc/skel --groups=wheel,networkmanager,video,input \
        --shell=/run/current-system/sw/bin/zsh "$username"
fi
user_home="$(getent passwd "$username" | cut -d: -f6)"
timeout 300 passwd "$username"
runuser -u "$username" -- env HOME="$user_home" PATH="$user_home/.local/bin:$PATH" \
    hyde-shell pyinit
runuser -u "$username" -- env HOME="$user_home" XDG_STATE_HOME="$user_home/.local/state" \
    python3 /etc/nixos/Configs/.local/lib/hyde/pyutils/lua_env.py create
runuser -u "$username" -- env HOME="$user_home" \
    /etc/nixos/Scripts/restore_thm.sh
runuser -u "$username" -- env HOME="$user_home" XDG_STATE_HOME="$user_home/.local/state" \
    PATH="$user_home/.local/bin:$PATH" "$user_home/.local/lib/hyde/wallpaper/cache.sh" commence -t ""
runuser -u "$username" -- env HOME="$user_home" XDG_STATE_HOME="$user_home/.local/state" \
    PATH="$user_home/.local/lib/hyde:$user_home/.local/bin:$PATH" "$user_home/.local/lib/hyde/theme.switch.sh" -q
runuser -u "$username" -- env HOME="$user_home" PATH="$user_home/.local/bin:$PATH" \
    "$user_home/.local/lib/hyde/waybar.py" --update

cat > "$account_config" <<NIX
{ ... }:
{
  users.users."$username" = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "input" ];
  };
  services.displayManager.autoLogin = {
    enable = true;
    user = "$username";
  };
  services.displayManager.defaultSession = "hyprland";
}
NIX

NIX_CONFIG='experimental-features = nix-command flakes' nixos-rebuild boot --flake "$config_dir#hyde"
touch "$marker"
echo 'The HyDE account is ready; rebooting into the normal-user desktop.'
reboot
