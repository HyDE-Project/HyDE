# HyDE Settings

HyDE Settings is a central entry point for system tools and HyDE appearance.
Select a category on the left and an entry on the right. Entries open existing
applications or HyDE selectors; this window does not implement drivers, replace
those tools, or edit their configuration files.

## Launch and keyboard manual

After deploying this branch through the normal HyDE installer, open **HyDE
Settings** from your application launcher or **Settings** from Waybar's HyDE menu.

```sh
hyde-shell settings
hyde-shell settings --help
hyde-shell settings --system-info
```

The last command prints a JSON array of `[group, label, value]` rows without GTK
or a display connection. Unknown options and positional arguments return status
2 with usage instructions. Help and a successful overview return 0. Missing GTK
or a graphical session returns 1 with a readable diagnostic.

To preview the checkout without deploying it:

```sh
sh Configs/.local/lib/hyde/settings.sh
```

This uses your installed HyDE tools and current Waybar colours. It does not deploy
the new launcher or window rule. Run the preview from a terminal, not from an
unscoped Waybar command that might be terminated during a theme switch.

| Input | Behaviour |
| --- | --- |
| Ctrl+F | Focus the global search above the category list |
| Type in search | Search titles, descriptions, categories and English/German aliases |
| Escape in a nonempty search | Clear the query and return to the selected category |
| Tab / Shift+Tab | Move keyboard focus between controls |
| Arrow keys in category list | Select a category |
| Enter / Space on a button | Open its tool |

All query words must match, irrespective of case; Unicode compatibility forms
are normalized. Search never runs commands. Results show their category. There
are no nested settings pages. Category scroll positions are retained for the
lifetime of the window. Opening another tool leaves search and scroll intact.
Repeated activation presents the existing window using the session D-Bus. The
last selected category also survives a full quit and relaunch, stored as
`HYDE_SETTINGS_LAST_CATEGORY` in `$XDG_STATE_HOME/hyde/staterc` -- the same
file HyDE's own shell scripts use for persistent runtime state (`HYDE_THEME`
and friends), not `$XDG_STATE_HOME/hyde/config`, which `hyde-shell config`
fully regenerates from `config.toml` on every change and would otherwise
silently drop it; an unrecognised or missing value falls back to the first
category.

## Available areas and tools

| Area | Tool or existing HyDE action |
| --- | --- |
| Audio | Pavucontrol: output, input, volume and streams |
| Displays | nwg-displays: resolution, scaling and arrangement |
| Network | nm-connection-editor: wired, Wi-Fi and VPN connection profiles |
| Accounts | Built-in, read-only overview of your own account; "Change password" opens a terminal running `passwd`; renaming the computer runs `hostnamectl set-hostname` |
| Devices | Blueman; system-config-printer; Document Scanner (`simple-scan`); GNOME Disks; xfce4-power-manager (battery status and power/suspend behaviour) |
| Appearance | HyDE themes and wallpapers; nwg-look (GTK theme, icons, cursor and font); qt5ct; qt6ct; Kvantum; font-manager to browse/install/remove fonts; Waybar layout, style and weather location selectors; SDDM login screen (`sddm-kcm`, with a live theme preview) |
| Desktop | HyDE animations, layouts, workflows, shaders, lock screen and keybind hints |
| Updates | Check for and install pending pacman/AUR updates |
| Apps | Octopi package manager; default app / file-type associations (`kcmshell6 filetypes`, from `kde-cli-tools`) |
| Gaming | AntiMicroX controller mapping |
| Accessibility | KMag screen magnifier; Squeekboard on-screen keyboard |
| Privacy & Security | UFW firewall rules via plasma-firewall's KCM (`kcmshell6 firewall`); Flatseal Flatpak permissions |
| System Information | A read-only overview with a copy button |

Scanner and controller entries open scanning and button-mapping applications.
They do not install scanner drivers or provide universal controller calibration.
The network entry edits connection profiles; it is not a Wi-Fi status dashboard.
Keyboard shortcuts opens the existing hint viewer, not an editor.
The login screen entry edits a system-wide, root-owned setting; unlike every
other entry it may prompt for authentication (Polkit) when a theme is applied.
xfce4-power-manager was chosen for Power & battery over GNOME's Power panel
specifically to avoid pulling in gnome-shell and gnome-session as
dependencies just for two settings pages. Its screen-blank/suspend timers
only take effect while its own `xfce4-power-manager` background process is
running, which HyDE does not start on its own; HyDE's own Workflows stays
the authoritative place for idle/lock/suspend behaviour on Hyprland.
Weather location is a built-in search, not an external tool: typing a city
queries Open-Meteo's free geocoding API (the only network request this app
ever makes on its own) and saves the chosen coordinates into `config.toml`'s
`[weather]` `location` key -- the same key documented for manual editing in
HyDE's own config schema -- so `hyde-shell config`'s watcher picks it up and
exports it the normal way; the human-readable label shown in this hub is a
separate, UI-only value in `$XDG_STATE_HOME/hyde/staterc`. Picking a location
also sends Waybar's weather module its refresh signal (`pkill -RTMIN+10
waybar`, the same one `custom-weather.jsonc`'s own click handler uses), so it
doesn't wait out its 3600s poll interval showing the old location.
Accounts is likewise built in rather than an external tool, deliberately: it
only reads the signed-in user's own passwd/group record (never other
accounts, never a password) and never creates, deletes or elevates a user.
Creating or deleting accounts stays a deliberate, terminal-driven admin task
(`useradd`/`usermod`), not a GUI toggle in this hub.
Renaming the computer runs `hostnamectl set-hostname` and, like the login
screen entry, may prompt for Polkit authentication (systemd's own
`org.freedesktop.hostname1` policy requires it unconditionally); this hub
never touches `/etc/hostname` directly.

Missing optional tools remain visible with an explanation. Nothing is installed
automatically. Install optional tools using your distribution's normal package
manager, then revisit the category. Distribution package and desktop-file names
can differ. No claim is made that these programs exist in every Linux install.
A missing tool's "Requires" line names one Arch package; hovering it shows the
exact `pacman -S` command as a tooltip.

## Runtime and installation

The runtime is distribution Python 3.11 or later, GTK 3 and PyGObject. Arch package
names `gtk3` and `python-gobject` are explicit core dependencies in both installer
lists. The shell entry intentionally uses `/usr/bin/python3` to avoid HyDE's
isolated Python environment, which need not contain distribution introspection
bindings. No pip package, daemon, plugin framework or custom settings backend is
introduced.

The core dotfile manifest deploys the library and one specific desktop file. It
never cleans the user's applications directory. Waybar's existing menu deployment
includes the new action. The existing Hyprland floating-window rule includes
`org.hyde.Settings`; the compositor supplies borders, rounding and window effects.
Fonts and icon themes follow GTK's desktop settings. External programs retain
their own appearance.

## Theme contract and recovery

The source is `$XDG_CONFIG_HOME/waybar/theme.css`, defaulting to
`~/.config/waybar/theme.css`. Relative XDG paths are ignored, following the XDG
base-directory requirement for absolute paths.

Required GTK colour roles are:

- `main-bg`, `main-fg`
- `wb-act-bg`, `wb-act-fg`
- `wb-hvr-bg`, `wb-hvr-fg`

GTK parses the source, including imports and symbolic expressions. Only resolved
colours are installed in the app; Waybar selectors cannot alter the settings
layout. There is no independent wallpaper extraction, fixed app palette or
appearance-mode switch. Wallbash off/auto/light/dark are reflected by whichever
colours HyDE writes to Waybar.

Directory monitors survive atomic file replacement and coalesce events for
150 ms. A two-second fallback also covers imported stylesheets and directories
created after startup. The provider is replaced only when all six roles resolve
and GTK reports no parsing errors. Incomplete writes, missing imports, unreadable
files and malformed CSS keep the previous valid palette. With no valid palette
at startup, GTK appearance is used. A persistent inline notice explains fallback;
the next valid update clears it. Identical resolved palettes do not trigger a
style replacement. No controls are reconstructed during colour reloads.

The app adds no navigation animation beyond a short hover/selection colour
transition on category and entry rows; window animation/blur remains
Hyprland's responsibility. Theme-defined colours can have poor contrast:
visual acceptance must check the actual foreground, background and wallpaper
composition. This app does not silently substitute a different palette to
conceal a theme defect, with one narrow exception: because the window is
translucent, `main-fg`/`wb-hvr-fg`/`wb-act-fg` can drop under WCAG AA (4.5:1)
depending on what sits behind the window, so `palette_provider()` makes a
foreground colour fully opaque (never changes its hue) if it would otherwise
fail against both a black and a white backdrop. If a theme's foreground and
background hues are themselves too close in lightness, this cannot fix it --
that stays a theme-authoring issue, same as any other poor-contrast theme.

## System overview and privacy

The overview reads hostname, DMI manufacturer/model/mainboard, CPU model/logical
count, physical RAM, display controllers and their driver, connected displays
with resolution and refresh rate, disk models (SSD/HDD, no serials), battery
charge and status, distribution, kernel, running Hyprland version and the
installer's cached HyDE version. It reports free/total space for `/` and home,
avoiding duplicate device IDs. Btrfs subvolumes may expose different device IDs
despite sharing a storage pool. This is an overview, not a disk/RAID inventory.
The active network connection is named by type (Wi-Fi/Wired), interface and,
for Wi-Fi, the network name -- never an IP or MAC address.

Data sources are Linux `/proc`, `/sys`, Python's OS APIs, optional `lspci`,
`lsblk`, `nmcli`, `hyprctl version -j`/`monitors -j`, and
`$XDG_STATE_HOME/hyde/version`. Only the literal `HYDE_VERSION` assignment is
read from that cache; the shell file is never sourced. Missing or inaccessible
values show **Not available**. Each external probe has a three-second timeout.
GUI collection happens on a worker thread and is cached for the window
lifetime; reopen for a fresh snapshot. A spinner marks this and the weather
location search as working while their unavoidably variable wait (probes;
a network request) is in progress. There are no continuous utilization or
temperature probes.

**Copy system information** copies exactly this overview. It includes hostname,
manufacturer/model, hardware summary, the active connection's type/interface/
Wi-Fi name and software versions, but does not collect serial numbers, IP/MAC
addresses, environment variables or full process lists. Review the copied text
before sharing it. Nothing is sent over the network.

## Failure behaviour and maintenance

GIO resolves desktop IDs and honours local XDG overrides, `Hidden` and
`TryExec`/missing-binary checks, but deliberately ignores `NoDisplay` and
`OnlyShowIn`/`NotShowIn`: those gate a generic desktop menu against
`$XDG_CURRENT_DESKTOP`, which is the wrong check for a hub that intentionally
launches specific KDE/GNOME/XFCE config tools on Hyprland regardless of which
desktop they were built for. Exec strings are never parsed by this app.
PyGObject versions that raise on missing IDs are supported alongside versions
that return `None`. Applications are resolved again at click time to account for
uninstallation. An inline error reports immediate launch failures. A successful
GIO launch does not prove that an external application stays healthy afterward.

HyDE actions use a fixed argument list through the existing `hyde-shell app`
scope wrapper. This keeps theme/Waybar reloads from killing the originating
settings process when launched through the supplied desktop/menu entry. Failed
HyDE subprocesses produce an inline message. Search text, device strings and
clipboard contents are never executed. Toolkit labels use plain text, not markup.

To add a supported tool, add one `Entry` in `settings.py`, using a desktop ID or
an existing HyDE command and search aliases. Keep categories flat. Update this
table and the catalogue/behaviour checks. Avoid copying tool internals into the
hub. If upstream renames a colour role or command, update this explicit boundary
and its regression checks rather than adding compatibility guesses everywhere.
Before wiring a desktop ID, read its `Exec=` line: some KDE KCM `.desktop`
files (like `kcm_filetypes.desktop`) route through the full `systemsettings`
shell rather than a lighter standalone binary, silently pulling in a much
heavier dependency than the "Requires" hint states -- but the lighter
standalone binary can be a dead end too: `org.kde.keditfiletype.desktop`'s
`Exec=keditfiletype` needs a mimetype argv it never gets from a bare
launch, so it just prints `--help` and exits without opening anything.
`kcmshell6 <module>` (from `kcmutils`, already a hard dependency of
`kde-cli-tools`) is the standalone middle ground for a KDE KCM: no
`systemsettings`, and it takes the module name as its argument instead of
requiring one HyDE has no generic value for. Ship a small HyDE `.desktop`
wrapping it (`hyde-default-apps.desktop` for `kcmshell6 filetypes`, here)
rather than a raw upstream ID when the upstream ID needs an argv HyDE can't
supply. Give that wrapper its own `TryExec` naming the wrapped binary
(`kcmshell6`, not `hyde-shell`): without it, GIO only checks that the outer
`hyde-shell` command resolves, so the entry shows as available -- and its
"Requires" hint disappears -- even when the wrapped tool itself isn't
installed. Add the new file to `Scripts/dots/hyde.toml`'s sync paths too;
shipping it in the repo alone never deploys it to a real install.

Also check whether the tool re-execs its whole GUI as root instead of
authorizing individual actions: `gufw`'s `Exec=gufw` runs `pkexec
gufw-pkexec`, which loses `WAYLAND_DISPLAY`/`XAUTHORITY` and fails to open
any window under Wayland/XWayland (`cannot open display`), even though the
polkit password prompt itself succeeds. A KCM authorizing via KAuth/Polkit
per action (`hyde-firewall.desktop` for `kcmshell6 firewall`, backed by
`plasma-firewall`, here) keeps the GUI itself unprivileged and doesn't hit
this. Prefer that pattern over a `pkexec <full-gui>`-style tool when both
manage the same backend (both drive `ufw` here).

Known limitation: `plasma-firewall` 6.7.5's rule list can render empty even
when `ufw` has active rules -- verified the rules parse correctly through
`ufw`'s own Python library (`UFWBackendIptables.get_rules()`), so the data
is there; moving the mouse over the (empty-looking) table makes the rows
appear. Root cause: `RuleListModel::setProfile()` loads the rules via
`beginResetModel()`/`endResetModel()` asynchronously, after `TableView` has
already laid out against the still-empty model; `QQuickTableView` doesn't
reliably relayout on a bare `modelReset()`, and the hover handler's
`cellAtPosition()` call incidentally forces the relayout that reveals the
rows. Reported upstream as
[plasma-firewall#28](https://invent.kde.org/plasma/plasma-firewall/-/issues/28).
Not the same issue as the KDE-tracked "Add rule" dialog list bug
([bugs.kde.org #461726](https://bugs.kde.org/show_bug.cgi?id=461726)), which
was fixed in Plasma Firewall 5.27 -- that one's long resolved by 6.7.5. Kept
anyway over `gufw` because a Wayland-safe launch that sometimes
under-displays rules beats one that never opens a window at all; adding and
removing rules is unaffected, and `ufw status verbose` in a terminal is
the reliable fallback for viewing them.

## Testing

```sh
sh tests/run.sh settings
sh tests/run.sh
```

The settings case runs standard-library `unittest` logic checks, then GTK
integration tests on an isolated Xvfb display. No external settings programs are
launched by these tests. Temporary XDG directories hold synthetic desktop entries
and CSS. System icons and MIME data remain readable. CI installs GTK, PyGObject,
Xvfb and xauth and requires the graphical checks; local machines without these
print an explicit skip. A sandbox may need permission for Xvfb's local socket.

Tests must assert behaviour for both valid and invalid inputs. Do not replace a
failing expectation just to match the implementation. The matrix and remaining
hardware/compositor acceptance steps are in [the test plan](hyde-settings-tests.md).

GTK integration references: [CSS parsing errors](https://docs.gtk.org/gtk3/signal.CssProvider.parsing-error.html)
and [GIO application launch](https://docs.gtk.org/gio/method.AppInfo.launch.html).
