# Hyde's Shell Environment Initialization Script

# Basic PATH prepending (user local bin)
PATH="$HOME/.local/bin:$PATH"

# XDG User Directories (fallback to xdg-user-dir command if available)
if command -v xdg-user-dir >/dev/null 2>&1; then
  XDG_DESKTOP_DIR="${XDG_DESKTOP_DIR:-$(xdg-user-dir DESKTOP)}"
  XDG_DOWNLOAD_DIR="${XDG_DOWNLOAD_DIR:-$(xdg-user-dir DOWNLOAD)}"
  XDG_TEMPLATES_DIR="${XDG_TEMPLATES_DIR:-$(xdg-user-dir TEMPLATES)}"
  XDG_PUBLICSHARE_DIR="${XDG_PUBLICSHARE_DIR:-$(xdg-user-dir PUBLICSHARE)}"
  XDG_DOCUMENTS_DIR="${XDG_DOCUMENTS_DIR:-$(xdg-user-dir DOCUMENTS)}"
  XDG_MUSIC_DIR="${XDG_MUSIC_DIR:-$(xdg-user-dir MUSIC)}"
  XDG_PICTURES_DIR="${XDG_PICTURES_DIR:-$(xdg-user-dir PICTURES)}"
  XDG_VIDEOS_DIR="${XDG_VIDEOS_DIR:-$(xdg-user-dir VIDEOS)}"
fi

# Less history file location
LESSHISTFILE="${LESSHISTFILE:-/tmp/less-hist}"

# Application config files
PARALLEL_HOME="$XDG_CONFIG_HOME/parallel"
SCREENRC="$XDG_CONFIG_HOME/screen/screenrc"


# Toolkit Backend Variables - https://wiki.hyprland.org/Configuring/Environment-variables/#toolkit-backend-variables
# GDK_BACKEND="${GDK_BACKEND:-wayland,x11,*}"       # GTK: Use wayland if available. If not: try x11, then any other GDK backend.
# SDL_VIDEODRIVER="${SDL_VIDEODRIVER:-wayland}" # Run SDL2 applications on Wayland. Remove or set to x11 if games that provide older versions of SDL cause compatibility issues
# CLUTTER_BACKEND="${CLUTTER_BACKEND:-wayland}" # Clutter package already has wayland enabled, this variable will force Clutter applications to try and use the Wayland backend

# # Qt Variables  - https://wiki.hyprland.org/Configuring/Environment-variables/#qt-variables

QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-wayland;xcb}" # Qt: Use wayland if available, fall back to x11 if not.
QT_AUTO_SCREEN_SCALE_FACTOR="${QT_AUTO_SCREEN_SCALE_FACTOR:-1}"                 # Enables automatic scaling, based on the monitor’s pixel density
QT_WAYLAND_DISABLE_WINDOWDECORATION="${QT_WAYLAND_DISABLE_WINDOWDECORATION:-1}" # Disables window decorations on Qt applications
QT_QPA_PLATFORMTHEME="${QT_QPA_PLATFORMTHEME:-qt6ct}"                           # Tells Qt based applications to pick your theme from qt5ct, use with Kvantum.

# # HyDE Environment Variables -

MOZ_ENABLE_WAYLAND="${MOZ_ENABLE_WAYLAND:-1}"                        # Enable Wayland for Firefox
GDK_SCALE="${GDK_SCALE:-1}"                                          # Set GDK scale to 1, for Xwayland on HiDPI displays
ELECTRON_OZONE_PLATFORM_HINT="${ELECTRON_OZONE_PLATFORM_HINT:-auto}" # Set Electron Ozone Platform Hint to auto, for Electron apps on Wayland

export PATH \
  XDG_DESKTOP_DIR XDG_DOWNLOAD_DIR XDG_TEMPLATES_DIR XDG_PUBLICSHARE_DIR \
  XDG_DOCUMENTS_DIR XDG_MUSIC_DIR XDG_PICTURES_DIR XDG_VIDEOS_DIR \
  LESSHISTFILE PARALLEL_HOME SCREENRC \
  ELECTRON_OZONE_PLATFORM_HINT GDK_SCALE MOZ_ENABLE_WAYLAND QT_QPA_PLATFORMTHEME \
  QT_WAYLAND_DISABLE_WINDOWDECORATION QT_QPA_PLATFORM QT_AUTO_SCREEN_SCALE_FACTOR
