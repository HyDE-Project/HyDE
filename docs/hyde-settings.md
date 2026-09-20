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
Repeated activation presents the existing window using the session D-Bus.

## Available areas and tools

| Area | Tool or existing HyDE action |
| --- | --- |
| Audio | Pavucontrol: output, input, volume and streams |
| Displays | nwg-displays: resolution, scaling and arrangement |
| Network & Bluetooth | nm-connection-editor for profiles; Blueman for pairing |
| Devices | system-config-printer; Document Scanner (`simple-scan`); AntiMicroX |
| Appearance | HyDE themes and wallpapers; nwg-look; qt5ct; qt6ct; Kvantum |
| Desktop | HyDE animations, layouts, workflows, shaders, lock screen and keybind hints |
| Waybar | Existing layout and style selectors |
| System Information | A read-only overview with a copy button |

Scanner and controller entries open scanning and button-mapping applications.
They do not install scanner drivers or provide universal controller calibration.
The network entry edits connection profiles; it is not a Wi-Fi status dashboard.
Keyboard shortcuts opens the existing hint viewer, not an editor.

Missing optional tools remain visible with an explanation. Nothing is installed
automatically. Install optional tools using your distribution's normal package
manager, then revisit the category. Distribution package and desktop-file names
can differ. No claim is made that these programs exist in every Linux install.

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

The app adds no navigation animation. Window animation/blur remains Hyprland's
responsibility. Theme-defined colours can have poor contrast: visual acceptance
must check the actual foreground, background and wallpaper composition. This app
does not silently substitute a different palette to conceal a theme defect.

## System overview and privacy

The overview reads hostname, DMI manufacturer/model, CPU model/logical count,
physical RAM, display controllers, distribution, kernel, running Hyprland version
and the installer's cached HyDE version. It reports free/total space for `/` and
home, avoiding duplicate device IDs. Btrfs subvolumes may expose different device
IDs despite sharing a storage pool. This is an overview, not a disk/RAID inventory.

Data sources are Linux `/proc`, `/sys`, Python's OS APIs, optional `lspci`,
`hyprctl version -j`, and `$XDG_STATE_HOME/hyde/version`. Only the literal
`HYDE_VERSION` assignment is read from that cache; the shell file is never sourced.
Missing or inaccessible values show **Not available**. Each external probe has a
three-second timeout. GUI collection happens on a worker thread and is cached
for the window lifetime; reopen for a fresh snapshot. There are no continuous
utilization, temperature or vendor-specific GPU probes.

**Copy system information** copies exactly this overview. It includes hostname,
manufacturer/model and software versions, but does not collect serial numbers,
IP/MAC addresses, environment variables or full process lists. Review the copied
text before sharing it. Nothing is sent over the network.

## Failure behaviour and maintenance

GIO resolves desktop IDs and honours local XDG overrides, hidden entries,
`TryExec` and desktop visibility. Exec strings are never parsed by this app.
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
