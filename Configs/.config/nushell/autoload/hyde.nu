#!          ░▒▓
#!        ░▒▒░▓▓
#!      ░▒▒▒░░░▓▓           ___________
#!    ░░▒▒▒░░░░░▓▓        //___________/
#!   ░░▒▒▒░░░░░▓▓     _   _ _    _ _____
#!   ░░▒▒░░░░░▓▓▓▓▓▓ | | | | |  | |  __/
#!    ░▒▒░░░░▓▓   ▓▓ | |_| | |_/ /| |___
#!     ░▒▒░░▓▓   ▓▓   \__  |____/ |____/  █▄░█ █░█
#!       ░▒▓▓   ▓▓  //____/               █░▀█ █▄█

# HyDE's Nushell environment.
#
# This file lives in Nushell's user autoload directory, so it is sourced on
# every startup without the user having to edit config.nu. Nothing here
# overwrites a value the user or the session already set.

# ── XDG base directories ────────────────────────────────────────────────────

$env.XDG_CONFIG_HOME = ($env.XDG_CONFIG_HOME? | default ($nu.home-dir | path join ".config"))
$env.XDG_DATA_HOME = ($env.XDG_DATA_HOME? | default ($nu.home-dir | path join ".local" "share"))
$env.XDG_STATE_HOME = ($env.XDG_STATE_HOME? | default ($nu.home-dir | path join ".local" "state"))
$env.XDG_CACHE_HOME = ($env.XDG_CACHE_HOME? | default ($nu.home-dir | path join ".cache"))
$env.XDG_DATA_DIRS = ($env.XDG_DATA_DIRS? | default $"($env.XDG_DATA_HOME):/usr/local/share:/usr/share")

$env.XDG_DESKTOP_DIR = ($env.XDG_DESKTOP_DIR? | default ($nu.home-dir | path join "Desktop"))
$env.XDG_DOWNLOAD_DIR = ($env.XDG_DOWNLOAD_DIR? | default ($nu.home-dir | path join "Downloads"))
$env.XDG_TEMPLATES_DIR = ($env.XDG_TEMPLATES_DIR? | default ($nu.home-dir | path join "Templates"))
$env.XDG_PUBLICSHARE_DIR = ($env.XDG_PUBLICSHARE_DIR? | default ($nu.home-dir | path join "Public"))
$env.XDG_DOCUMENTS_DIR = ($env.XDG_DOCUMENTS_DIR? | default ($nu.home-dir | path join "Documents"))
$env.XDG_MUSIC_DIR = ($env.XDG_MUSIC_DIR? | default ($nu.home-dir | path join "Music"))
$env.XDG_PICTURES_DIR = ($env.XDG_PICTURES_DIR? | default ($nu.home-dir | path join "Pictures"))
$env.XDG_VIDEOS_DIR = ($env.XDG_VIDEOS_DIR? | default ($nu.home-dir | path join "Videos"))

$env.LESSHISTFILE = ($env.LESSHISTFILE? | default "/tmp/less-hist")
$env.PARALLEL_HOME = ($env.PARALLEL_HOME? | default ($env.XDG_CONFIG_HOME | path join "parallel"))

# ── Hyprland configuration ──────────────────────────────────────────────────

# Hyprland picks its config provider from the extension, so the Lua entry
# point is preferred and the hyprlang one is the fallback.
$env.HYPRLAND_CONFIG = ($env.HYPRLAND_CONFIG? | default (
    [
        ($env.XDG_DATA_HOME | path join "hypr" "hyde.lua")
        "/usr/local/share/hypr/hyde.lua"
        "/usr/share/hypr/hyde.lua"
        ($env.XDG_DATA_HOME | path join "hypr" "hyprland.conf")
    ]
    | where {|candidate| $candidate | path exists }
    | get -o 0
    | default ($env.XDG_DATA_HOME | path join "hypr" "hyprland.conf")
))

# ── PATH ────────────────────────────────────────────────────────────────────

$env.PATH = ($env.PATH | prepend ($nu.home-dir | path join ".local" "bin") | uniq)

# ── Prompt ──────────────────────────────────────────────────────────────────

if (which starship | is-not-empty) {
    $env.STARSHIP_CACHE = ($env.STARSHIP_CACHE? | default ($env.XDG_CACHE_HOME | path join "starship"))
    $env.STARSHIP_CONFIG = ($env.STARSHIP_CONFIG? | default ($env.XDG_CONFIG_HOME | path join "starship" "starship.toml"))

    # Nushell cannot source a generated script at runtime, so the init is
    # written into the vendor autoload directory and picked up next startup.
    let starship_init = ($nu.data-dir | path join "vendor" "autoload" "starship.nu")
    if not ($starship_init | path exists) {
        mkdir ($starship_init | path dirname)
        starship init nu | save --force $starship_init
    }
}

# ── Aliases ─────────────────────────────────────────────────────────────────

alias c = clear

alias l = eza -lh --icons=auto
alias ls = eza -1 --icons=auto
alias ll = eza -lha --icons=auto --sort=name --group-directories-first
alias ld = eza -lhD --icons=auto
alias lt = eza --icons=auto --tree

alias in = hyde-shell pm install
alias un = hyde-shell pm remove
alias up = hyde-shell pm upgrade
alias pl = hyde-shell pm search installed
alias pa = hyde-shell pm search all

alias g = git
alias vc = code
