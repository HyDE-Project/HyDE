#!/usr/bin/env bash
# /* ---- 💫 Modified version of polkitkdeauth.sh from https://github.com/JaKooLit 💫 ---- */  ##
# This script starts the first available Polkit agent from a list of possible locations

# List of potential Polkit agent file paths

polkit=(
  # Hyprland / Wayland (Priority since it's the intended agent for Hyprland)
  "/usr/libexec/hyprpolkitagent"
  "/usr/lib/hyprpolkitagent"
  "/usr/lib/hyprpolkitagent/hyprpolkitagent"

  # GNOME (Arch, Fedora)
  "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"

  # GNOME (Debian/Ubuntu variants)
  "/usr/libexec/polkit-gnome-authentication-agent-1"
  "/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1"
  "/usr/lib/polkit-gnome-authentication-agent-1"

  # KDE (Arch)
  "/usr/lib/polkit-kde-authentication-agent-1"

  # KDE (Debian/Ubuntu)
  "/usr/lib/x86_64-linux-gnu/libexec/polkit-kde-authentication-agent-1"
  "/usr/libexec/polkit-kde-authentication-agent-1"

  # MATE
  "/usr/libexec/polkit-mate-authentication-agent-1"

  # LXQt
  "/usr/bin/lxqt-policykit-agent"

  # XFCE (uses lxqt agent usually, but include fallback)
  "/usr/libexec/xfce-polkit"

  # Cinnamon (usually GNOME, but sometimes separate)
  "/usr/lib/cinnamon-polkit-agent"

  # Deepin
  "/usr/lib/polkit-1-dde/dde-polkit-agent"

  # Pantheon (elementary OS)
  "/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1"

  # Generic fallback (if packaged differently)
  "/usr/bin/polkit-gnome-authentication-agent-1"
)


executed=false

# Loop through the list of paths
for file in "${polkit[@]}"; do
  if [ -e "$file" ] && [ ! -d "$file" ]; then
    echo "Found: $file — executing..."
    exec "$file"
    executed=true
    break
  fi
done

# Fallback message if nothing executed
if [ "$executed" == false ]; then
  echo "No valid Polkit agent found. Please install one."
fi
