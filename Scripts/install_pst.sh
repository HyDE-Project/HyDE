#!/usr/bin/env bash
#|---/ /+--------------------------------------+---/ /|#
#|--/ /-| Script to apply post install configs |--/ /-|#
#|-/ /--| Prasanth Rangan                      |-/ /--|#
#|/ /---+--------------------------------------+/ /---|#

scrDir=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1091
if ! source "${scrDir}/global_fn.sh"; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

cloneDir="${cloneDir:-$CLONE_DIR}"
flg_DryRun=${flg_DryRun:-0}

# greetd + ReGreet (GTK greeter) — this fork replaces SDDM (Qt/KDE) with the
# GTK/GNOME login stack. ReGreet runs inside the cage kiosk compositor.
if pkg_installed greetd; then
    print_log -c "[DISPLAYMANAGER] " -b "detected :: " "greetd"

    if [ ! -f /etc/greetd/config.toml.backup_the_hyde_project ] || [ "${HYDE_INSTALL_GREETD}" = true ]; then
        print_log -g "[DISPLAYMANAGER] " -b " :: " "configuring greetd + regreet..."

        if [[ ${flg_DryRun} -ne 1 ]]; then
            sudo mkdir -p /etc/greetd

            # Back up any existing greetd configuration once.
            [ -f /etc/greetd/config.toml ] && [ ! -f /etc/greetd/config.toml.backup_the_hyde_project ] &&
                sudo cp /etc/greetd/config.toml /etc/greetd/config.toml.backup_the_hyde_project
            [ -f /etc/greetd/regreet.toml ] && [ ! -f /etc/greetd/regreet.toml.backup_the_hyde_project ] &&
                sudo cp /etc/greetd/regreet.toml /etc/greetd/regreet.toml.backup_the_hyde_project

            # greetd launches ReGreet inside cage (Wayland kiosk compositor).
            sudo tee /etc/greetd/config.toml >/dev/null <<'GREETD_EOF'
[terminal]
vt = 1

[default_session]
command = "cage -s -- regreet"
user = "greeter"
GREETD_EOF

            # Minimal ReGreet config; the greeter reads GTK theme/icons/cursor
            # from the greeter user's environment.
            [ -f /etc/greetd/regreet.toml ] || sudo tee /etc/greetd/regreet.toml >/dev/null <<'REGREET_EOF'
[commands]
reboot = [ "systemctl", "reboot" ]
poweroff = [ "systemctl", "poweroff" ]

[GTK]
application_prefer_dark_theme = true
cursor_theme_name = "Future-cursors"
icon_theme_name = "Papirus-Dark"
theme_name = "adw-gtk3-dark"
REGREET_EOF
        fi

        print_log -g "[DISPLAYMANAGER] " -b " :: " "greetd configured with ReGreet (GTK) greeter..."
    else
        print_log -y "[DISPLAYMANAGER] " -b " :: " "greetd is already configured..."
    fi

else
    print_log -y "[DISPLAYMANAGER] " -b " :: " "greetd is not installed..."
fi

# nautilus (GTK/GNOME file manager)
if pkg_installed nautilus && pkg_installed xdg-utils; then
    print_log -c "[FILEMANAGER] " -b "detected :: " "nautilus"
    xdg-mime default org.gnome.Nautilus.desktop inode/directory
    xdg-mime default org.gnome.Nautilus.desktop x-scheme-handler/trash
    print_log -g "[FILEMANAGER] " -b " :: " "setting $(xdg-mime query default "inode/directory") as default file explorer..."

else
    print_log -y "[FILEMANAGER]" -b " :: " "nautilus is not installed..."
    print_log -y "[FILEMANAGER]" -b " :: " "Setting $(xdg-mime query default "inode/directory") as default file explorer..."
fi

# shell
"${scrDir}/restore_shl.sh"

# flatpak
if pkg_installed flatpak; then
    echo ""
    print_log -g "[FLATPAK]" -b " list :: " "flatpak application"
    awk -F '#' '$1 != "" {print "["++count"]", $1}' "${scrDir}/extra/custom_flat.lst"
    prompt_timer 60 "Install these flatpaks? [Y/n]"
    fpkopt=${PROMPT_INPUT,,}

    if [ "${fpkopt}" = "y" ]; then
        print_log -g "[FLATPAK]" -b " install :: " "flatpaks"
        [ ${flg_DryRun} -eq 1 ] || "${scrDir}/extra/install_fpk.sh"
    else
        print_log -y "[FLATPAK]" -b " skip :: " "flatpak installation"
    fi

else
    print_log -y "[FLATPAK]" -b " :: " "flatpak is not installed, skipping"
fi
