{
  description = "DOORwayDE - Hyprland Desktop Environment for HALLway OS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);

      # DOORwayDE runtime dependencies
      doorwaydeDeps = pkgs: with pkgs; [
        # Core Hyprland ecosystem
        hyprland
        hyprlock
        hypridle
        hyprpaper

        # UI components
        rofi

        # Utilities
        grim
        slurp
        satty
        cliphist
        awww

        # System integration
        brightnessctl
        playerctl
        pamixer
        libnotify
        # gnome-keyring: provided by HALLway system-level via
        #   services.gnome.gnome-keyring.enable = true
        # + PAM auto-unlock via security.pam.services.greetd.enableGnomeKeyring
        polkit_gnome    # Polkit auth agent (declarative in Pass 6)

        # Applets (system tray daemons started by startup.lua)
        wl-clipboard          # wl-paste for cliphist text/image clipboard watch
        udiskie               # removable media tray applet
        networkmanagerapplet  # nm-applet --indicator
        blueman               # blueman-applet bluetooth tray

        # Terminal
        kitty

        # Optional
        hyprsunset

        # Initiative II — QuickShell shell + matugen color theming
        quickshell      # QML/Qt6 desktop shell toolkit
        matugen         # Material You color generation from wallpaper
        inotify-tools   # inotifywait for doorwayde-matugen-watcher
        material-symbols  # Google Material Symbols variable font (used by MaterialSymbol.qml)
      ];

      # Development dependencies
      devDeps = pkgs: with pkgs; [
        # Shell
        shellcheck
        shfmt

        # Nix
        nil          # Nix LSP
        nixfmt            # Nix formatter

        # Python
        python3
        ruff         # Python linter/formatter

        # General
        git
        direnv

        # MCP server runtimes (Claude Code)
        nodejs   # provides npx for @modelcontextprotocol/server-github
        uv       # provides uvx for mcp-server-git
      ];

      # Home Manager module definition
      doorwaydeModule = { config, lib, pkgs, ... }:
        let
          cfg = config.doorwayde;
          configDir = "${self}/Configs";

          # Shared template for DOORwayDE long-running services. All graphical-
          # session-dependent services use Type=exec, ExitType=cgroup, the
          # app-graphical.slice, and the graphical-session.target lifecycle.
          # Callers supply description + execStart (and optionally execStartPre,
          # documentation). See TODO.md Phase 9 Pass 2 design decisions.
          mkDoorwaydeService = {
            description, execStart,
            execStartPre ? null, documentation ? null,
          }: {
            Unit = {
              Description = description;
              After = [ "graphical-session.target" ];
              PartOf = [ "graphical-session.target" ];
            } // lib.optionalAttrs (documentation != null) {
              Documentation = documentation;
            };
            Service = {
              Type = "exec";
              ExitType = "cgroup";
              Slice = "app-graphical.slice";
              Restart = "always";
              RestartSec = 1;
              ExecStart = execStart;
            } // lib.optionalAttrs (execStartPre != null) {
              ExecStartPre = execStartPre;
            };
            Install = {
              WantedBy = [ "graphical-session.target" ];
            };
          };

          # Oneshot variant for session-bootstrap actions: portal restart,
          # config initialization, etc. RemainAfterExit=true so graphical-
          # session.target sees them as "active" not "exited" after completion.
          # Watches ~/.cache/doorwayde/wall.set for symlink replacement (ln -fs
          # uses rename(2) → inotify fires moved_to). Runs matugen to generate
          # Material You color files, then signals Hyprland to reload so
          # dynamic.lua picks up the new hyprland-colors.lua via dofile().
          matugenWatcherScript = pkgs.writeShellScript "matugen-watcher" ''
            set -euo pipefail
            WALL="''${XDG_CACHE_HOME:-$HOME/.cache}/doorwayde/wall.set"
            WATCH_DIR="$(dirname "$WALL")"

            run_matugen() {
              local wp
              wp="$(readlink -f "$WALL")" || return
              [[ -f "$wp" ]] || return
              ${pkgs.matugen}/bin/matugen image --source-color-index 0 "$wp"
              # Reload Hyprland so dynamic.lua re-dofiles hyprland-colors.lua.
              # Fails silently outside a live session (e.g. on first nixos-rebuild).
              ${pkgs.hyprland}/bin/hyprctl reload 2>/dev/null || true
            }

            # Run once at service start for the already-set wallpaper.
            run_matugen || true

            # ln -fs fires moved_to on the parent dir; watch for wall.set.
            ${pkgs.inotify-tools}/bin/inotifywait \
              -m -q -e moved_to,create --format '%f' "$WATCH_DIR" |
            while IFS= read -r fname; do
              [[ "$fname" == "wall.set" ]] || continue
              run_matugen || true
            done
          '';

          # Returns a home.activation entry that copies (not symlinks) a file,
          # making it writable at runtime. Merge the result into home.activation.
          # Example: home.activation = mkMutableHomeFile { path = ".config/foo/bar"; source = ./bar; };
          mkMutableHomeFile = { path, source, mode ? "0644" }: let
            name = "mkMutable-" + builtins.replaceStrings ["/" "."] ["-" "_"] path;
          in {
            "${name}" = lib.hm.dag.entryAfter ["writeBoundary"] ''
              install -Dm${mode} "${source}" "$HOME/${path}"
            '';
          };

          mkDoorwaydeOneshot = {
            description, execStart, after ? [], documentation ? null,
          }: {
            Unit = {
              Description = description;
              After = [ "graphical-session.target" ] ++ after;
              PartOf = [ "graphical-session.target" ];
            } // lib.optionalAttrs (documentation != null) {
              Documentation = documentation;
            };
            Service = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = execStart;
            };
            Install = {
              WantedBy = [ "graphical-session.target" ];
            };
          };
        in {
          options.doorwayde = {
            enable = lib.mkEnableOption "DOORwayDE Hyprland configuration";

            monitor = lib.mkOption {
              type = lib.types.str;
              default = ",preferred,auto,1";
              example = "HDMI-A-1,1920x1080@100,0x0,1";
              description = "Primary monitor configuration";
            };

            extraMonitors = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [];
              example = [ "DP-1,2560x1440@144,1920x0,1" ];
              description = "Additional monitor configurations";
            };

            keyboard = lib.mkOption {
              type = lib.types.str;
              default = "us";
              description = "Keyboard layout";
            };

            installPackages = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Install DOORwayDE dependencies";
            };

            shell = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = ''
                  Enable the DOORwayDE QuickShell UI shell.
                  Leave false until Phase 12 cutover (top bar parity with waybar).
                  When true, starts doorwayde-quickshell.service after graphical-session.target.
                '';
              };
            };
          };

          config = lib.mkIf cfg.enable {
            wayland.windowManager.hyprland.configType = "lua";

            home.packages = lib.mkIf cfg.installPackages (doorwaydeDeps pkgs);

            xdg.configFile = {
              # Individual file links instead of a directory symlink, so the
              # generated monitors.lua and userprefs.lua (below) can be placed
              # alongside them — a directory symlink to the Nix store is immutable.
              "hypr/hyprland.lua".source    = "${configDir}/.config/hypr/hyprland.lua";
              "hypr/keybindings.lua".source = "${configDir}/.config/hypr/keybindings.lua";
              "hypr/windowrules.lua".source = "${configDir}/.config/hypr/windowrules.lua";
              "hypr/workflows.lua".source   = "${configDir}/.config/hypr/workflows.lua";
              "hypr/animations.lua".source  = "${configDir}/.config/hypr/animations.lua";
              "hypr/shaders.lua".source     = "${configDir}/.config/hypr/shaders.lua";
              "hypr/hypridle.conf".source   = "${configDir}/.config/hypr/hypridle.conf";
              "hypr/hyprlock.conf".source   = "${configDir}/.config/hypr/hyprlock.conf";
              "hypr/hyprsunset.conf".source = "${configDir}/.config/hypr/hyprsunset.conf";
              "hypr/nvidia.conf".source     = "${configDir}/.config/hypr/nvidia.conf";
              "hypr/animations".source      = "${configDir}/.config/hypr/animations";
              "hypr/shaders".source         = "${configDir}/.config/hypr/shaders";
              "hypr/themes".source          = "${configDir}/.config/hypr/themes";
              "hypr/workflows".source       = "${configDir}/.config/hypr/workflows";
              "hypr/hyprlock".source        = "${configDir}/.config/hypr/hyprlock";
              "rofi".source = "${configDir}/.config/rofi";
              "doorwayde".source = "${configDir}/.config/doorwayde";
              "kitty".source = "${configDir}/.config/kitty";

              # Initiative II: QuickShell shell and matugen color theming.
              # quickshell/doorwayde is whole-dir (QML is source-controlled config).
              # matugen templates are Nix-managed; outputs go to ~/.local/share/matugen/
              # (writable, not Nix-managed) via doorwayde-matugen-watcher.service.
              "quickshell/doorwayde".source   = "${configDir}/.config/quickshell/doorwayde";
              "matugen/config.toml".source    = "${configDir}/.config/matugen/config.toml";
              "matugen/templates".source      = "${configDir}/.config/matugen/templates";

              "hypr/monitors.lua".text = let
                parseMon = m: let p = lib.splitString "," m;
                in ''hl.monitor({ output="${lib.elemAt p 0}", mode="${lib.elemAt p 1}", position="${lib.elemAt p 2}", scale="${lib.elemAt p 3}" })'';
              in ''
                -- DOORwayDE Monitor Configuration (generated by NixOS via Home Manager)
                ${parseMon cfg.monitor}
                ${lib.concatStringsSep "\n" (map parseMon cfg.extraMonitors)}
              '';

              "hypr/userprefs.lua".text = ''
                -- DOORwayDE User Preferences (generated by NixOS via Home Manager)
                hl.config({
                    input = {
                        kb_layout = "${cfg.keyboard}",
                        follow_mouse = 1,
                        touchpad = { natural_scroll = true },
                    },
                    misc = {
                        enable_swallow = true,
                        swallow_regex = "(kitty|Alacritty|foot)",
                    },
                })
              '';

            };

            home.file = {
              ".local/lib/doorwayde".source = "${configDir}/.local/lib/doorwayde";
              ".local/share/doorwayde".source = "${configDir}/.local/share/doorwayde";
              ".local/share/hypr".source = "${configDir}/.local/share/hypr";
              ".local/bin/doorwayde-shell" = {
                source = "${configDir}/.local/bin/doorwayde-shell";
                executable = true;
              };
              ".local/bin/doorwaydectl" = {
                source = "${configDir}/.local/bin/doorwaydectl";
                executable = true;
              };
              ".local/bin/doorwayde-ipc" = {
                source = "${configDir}/.local/bin/doorwayde-ipc";
                executable = true;
              };
            };

            home.sessionPath = [ "$HOME/.local/bin" "$HOME/.local/lib/doorwayde" ];

            # Static toolkit/Wayland env vars — session-wide (all processes, not
            # just Hyprland children). Centralises what was duplicated across env.lua
            # and the UWSM env-hyprland.d script. XCURSOR_* are omitted here;
            # home.pointerCursor below sets them automatically.
            home.sessionVariables = {
              QT_QPA_PLATFORM                     = "wayland;xcb";
              QT_AUTO_SCREEN_SCALE_FACTOR         = "1";
              QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
              QT_QPA_PLATFORMTHEME                = "qt6ct";
              MOZ_ENABLE_WAYLAND                  = "1";
              GDK_SCALE                           = "1";
              ELECTRON_OZONE_PLATFORM_HINT        = "auto";
            };

            # DOORwayDE ships one theme: Wallbash (dynamic colors from wallpaper).
            # The static aspects — GTK theme name, icon theme, cursor, UI font — are
            # declared here. Wallbash generates the actual Wallbash-Gtk theme content
            # at runtime into ~/.local/share/themes/Wallbash-Gtk/ (writable path).
            # Use lib.mkDefault so these can be overridden in the user's flake.
            gtk = {
              enable = true;
              theme.name     = lib.mkDefault "Wallbash-Gtk";
              iconTheme = { name = lib.mkDefault "Tela-dracula"; package = lib.mkDefault pkgs.tela-icon-theme; };
              # cursorTheme is managed by home.pointerCursor.gtk.enable below.
              font = { name = lib.mkDefault "Cantarell"; size = lib.mkDefault 10; };
              # HM 26.05 changed the gtk4.theme default from config.gtk.theme to null.
              # Explicitly keep the legacy inherit so GTK4 apps use Wallbash-Gtk too.
              gtk4.theme = config.gtk.theme;
            };

            # Cursor: sets XCURSOR_THEME + XCURSOR_SIZE session-wide, writes
            # ~/.local/share/icons/default/index.theme, and syncs gtk.cursorTheme.
            # Replaces the manual Xresources + icon-symlink writes in theme.switch.sh.
            home.pointerCursor = {
              name    = lib.mkDefault "oreo_spark_pink_cursors";
              size    = lib.mkDefault 24;
              package = lib.mkDefault pkgs.oreo-cursors-plus;
              gtk.enable = true;
            };

            # Static GNOME interface settings not already covered by gtk.enable.
            # color-scheme is declared as prefer-dark (single Wallbash theme default).
            # Dynamic dark/light from wallpaper lightness can be revisited in Pass 12.
            dconf.settings = {
              "org/gnome/desktop/interface" = {
                color-scheme = lib.mkDefault "prefer-dark";
              };
            };

            # All DOORwayDE long-running services and session-bootstrap oneshots.
            # Replaced the HyDE-era runtime-imperative pattern (launch-unit.sh +
            # variables.lua's app() helper birthing units at session start, both
            # deleted in Pass 7). See TODO.md Phase 9 for the migration history.
            systemd.user.services = {
              doorwayde-text-clipboard = mkDoorwaydeService {
                description = "DOORwayDE clipboard text watcher (cliphist)";
                execStart = "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store";
              };

              doorwayde-image-clipboard = mkDoorwaydeService {
                description = "DOORwayDE clipboard image watcher (cliphist)";
                execStart = "${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store";
              };

              doorwayde-network-manager-applet = mkDoorwaydeService {
                description = "DOORwayDE NetworkManager tray applet";
                execStart = "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator";
              };

              doorwayde-removable-media-applet = mkDoorwaydeService {
                description = "DOORwayDE removable-media tray applet (udiskie)";
                execStart = "${pkgs.udiskie}/bin/udiskie --no-automount --smart-tray";
              };

              doorwayde-bluetooth-applet = mkDoorwaydeService {
                description = "DOORwayDE Bluetooth tray applet (blueman)";
                execStart = "${pkgs.blueman}/bin/blueman-applet";
              };

              # doorwayde-notifications (dunst) removed in Phase 15 — QuickShell's
              # NotificationServer (Notifications.qml) registers on org.freedesktop.Notifications.

              # battery-notify reclassified to app-graphical.slice in Pass 4: it
              # uses notify-send → quickshell, which is graphical-session-only.
              doorwayde-battery-notify = mkDoorwaydeService {
                description = "DOORwayDE low-battery notification watcher";
                execStart = "%h/.local/lib/doorwayde/batterynotify.sh";
              };

              # wallpaper.sh bootstraps via `eval $(doorwayde-shell init)` — needs
              # PATH to include ~/.local/bin (propagated via systemctl --user
              # import-environment from startup.lua's SYSTEMD_SHARE_PICKER).
              doorwayde-wallpaper = mkDoorwaydeService {
                description = "DOORwayDE wallpaper daemon";
                execStart = "%h/.local/lib/doorwayde/wallpaper.sh --start --global";
              };

              doorwayde-idle = mkDoorwaydeService {
                description = "DOORwayDE idle daemon (hypridle)";
                documentation = "https://wiki.hypr.land/Hypr-Ecosystem/hypridle/";
                execStart = "${pkgs.hypridle}/bin/hypridle";
              };

              doorwayde-blue-light-filter = mkDoorwaydeService {
                description = "DOORwayDE blue-light filter (hyprsunset)";
                documentation = "https://wiki.hypr.land/Hypr-Ecosystem/hyprsunset/";
                execStart = "${pkgs.hyprsunset}/bin/hyprsunset";
              };

              doorwayde-polkit-auth = mkDoorwaydeService {
                description = "DOORwayDE polkit authentication agent (polkit-gnome)";
                execStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
              };

              doorwayde-config-bootstrap = mkDoorwaydeOneshot {
                description = "DOORwayDE config initialization (oneshot at session start)";
                execStart = "%h/.local/lib/doorwayde/doorwayde-config --no-startup";
              };

              # Watches ~/.cache/doorwayde/wall.set for changes and runs matugen
              # to regenerate Material You color files for Hyprland + QuickShell.
              # Starts alongside all other graphical-session services; the initial
              # run on service start handles the wallpaper set before first change.
              doorwayde-matugen-watcher = {
                Unit = {
                  Description = "DOORwayDE matugen wallpaper color watcher";
                  After = [ "graphical-session.target" ];
                  PartOf = [ "graphical-session.target" ];
                };
                Service = {
                  Type = "exec";
                  ExecStart = "${matugenWatcherScript}";
                  Restart = "on-failure";
                  RestartSec = 5;
                };
                Install = {
                  WantedBy = [ "graphical-session.target" ];
                };
              };

              # QuickShell UI shell — gated by doorwayde.shell.enable.
              # QML_IMPORT_PATH exposes qt5compat (Qt5Compat.GraphicalEffects) which
              # quickshell 0.3.0 does not bundle in its own store path.
              # ExecStartPost creates by-id/ipc.sock → the live instance socket.
              # Workaround: qs ipc resolves the instance ID from lock file content,
              # but QS 0.3.0 uses raw fcntl locks on an empty file, so the ID reads
              # as "" and the client looks for by-id/ipc.sock (missing the subdir).
              doorwayde-quickshell = lib.mkIf cfg.shell.enable (lib.mkMerge [
                (mkDoorwaydeService {
                  description = "DOORwayDE QuickShell (QML-based UI shell)";
                  execStart = "${pkgs.quickshell}/bin/quickshell -c %h/.config/quickshell/doorwayde";
                })
                (let
                  qsIpcSymlink = pkgs.writeShellScript "qs-ipc-symlink" ''
                    QS=/run/user/$(id -u)/quickshell
                    for _ in $(seq 30); do
                      sock=$(ls -t "$QS"/by-id/*/ipc.sock 2>/dev/null | head -1)
                      if [ -n "$sock" ]; then
                        ln -sfn "$sock" "$QS/by-id/ipc.sock"
                        exit 0
                      fi
                      sleep 0.5
                    done
                  '';
                in {
                  Service.Environment = [
                    "QML_IMPORT_PATH=${pkgs.qt6.qt5compat}/lib/qt-6/qml"
                  ];
                  Service.ExecStartPost = "${qsIpcSymlink}";
                })
              ]);
            };
          };
        };

    in {
      # Home Manager module (the main export)
      # Usage in HALLway flake:
      #   inputs.doorwayde.url = "github:MarkusBitterman/DOORwayDE";
      #   ...
      #   imports = [ inputs.doorwayde.homeManagerModules.default ];
      #   doorwayde.enable = true;
      homeManagerModules = {
        default = doorwaydeModule;
        doorwayde = doorwaydeModule;
      };

      # Development shell with all Hyprland packages
      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.mkShell {
            name = "doorwayde-dev";
            buildInputs = (doorwaydeDeps pkgs) ++ (devDeps pkgs);
            shellHook = ''
              echo "DOORwayDE Development Shell"
              echo "All Hyprland packages available."
              echo ""
              echo "  shellcheck Scripts/*.sh    - Lint shell scripts"
              echo "  nixfmt flake.nix           - Format Nix"
              echo ""
              echo "Testing Hyprland:"
              echo "  hyprctl reload             - Live-reload config (inside any Hyprland session)"
              echo "  start-hyprland             - Start nested Hyprland (WAYLAND SESSION ONLY)"
              echo "    NOTE: Requires a running Wayland compositor (e.g. XFCE Wayland session)."
              echo "    Keyboard is dead in nested mode (libseat cannot open /dev/input)."
              echo "    Use for visual checks only; native login required for keybinding tests."
              echo ""
              echo "Flake-based deploy workflow (DOORwayDE → HALLway):"
              echo "  DOORwayDE is a flake input — changes must be committed AND pushed"
              echo "  before HALLway can see them. Local uncommitted changes are invisible."
              echo "  1. git commit && git push              (in this repo)"
              echo "  2. nix flake update doorwayde          (in HALLway repo)"
              echo "  3. sudo nixos-rebuild switch --flake ~/Developments/HALLway/#2600AD"
              echo ""
              echo "Debugging startup failures:"
              echo "  cat /run/user/\$(id -u)/hypr/*/hyprland.log | grep -v 'DEBUG from aquamarine'"
              echo "    Lua config errors appear here; exec_once failures do NOT."
              echo "  journalctl --user -b -n 200 | grep -iE '(quickshell|doorwayde|hypr)'"
              echo "    Daemon crashes from exec_once land here."
              echo "  doorwayde-shell app -u test.scope -t scope -- echo ok"
              echo "    Sanity check: verifies app2unit.sh is findable in PATH."
              echo ""
              # Mimic what env.lua injects before exec_once so doorwayde-shell app works
              # directly from this dev shell or an XFCE Wayland terminal.
              export PATH="$HOME/.local/lib/doorwayde:$PATH"
              export XDG_SESSION_DESKTOP=Hyprland
              export XDG_CURRENT_DESKTOP=Hyprland
              echo "  (PATH includes ~/.local/lib/doorwayde — doorwayde-shell app works here)"
              echo ""
            '';
          };
        });

      # Expose the dependency list for HALLway to import
      lib.doorwaydeDeps = doorwaydeDeps;
    };
}
