#!/usr/bin/env bash
# Starts the first available Polkit agent, preferring GNOME on this GTK fork.
# GTK-only session: GNOME agent first, generic fallbacks after.
# (No hyprpolkitagent / KDE agents — this fork installs polkit-gnome, see Scripts/pkg_core.lst.)

polkit=(
  # GNOME (Arch, Fedora)
  "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"

  # GNOME (Debian/Ubuntu variants)
  "/usr/libexec/polkit-gnome-authentication-agent-1"
  "/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1"
  "/usr/lib/polkit-gnome-authentication-agent-1"

  # Pantheon (elementary OS, GNOME-based)
  "/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1"

  # Generic fallback (if packaged differently)
  "/usr/bin/polkit-gnome-authentication-agent-1"

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
  echo "No valid Polkit agent found. Please install polkit-gnome."
fi
