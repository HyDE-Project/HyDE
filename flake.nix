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
        waybar
        rofi
        dunst
        wlogout

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
        gnome-keyring   # Secret Service API for VSCodium, Firefox, et al.

        # Applets (system tray daemons started by startup.lua)
        wl-clipboard          # wl-paste for cliphist text/image clipboard watch
        udiskie               # removable media tray applet
        networkmanagerapplet  # nm-applet --indicator
        blueman               # blueman-applet bluetooth tray

        # Terminal
        kitty

        # Optional
        hyprsunset
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
              # ~/.config/waybar/ is mostly runtime-owned by waybar.py (config.jsonc,
              # style.css, theme.css, global.css, user-style.css = theme/session state).
              # The module-include list is static and lifted to Nix-eval-time below.
              # Template sources (layouts/styles/modules) live in ~/.local/share/waybar/.
              "rofi".source = "${configDir}/.config/rofi";
              "dunst".source = "${configDir}/.config/dunst";
              "doorwayde".source = "${configDir}/.config/doorwayde";
              "kitty".source = "${configDir}/.config/kitty";
              "wlogout".source = "${configDir}/.config/wlogout";

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

              # Waybar module-include list: enumerated at Nix-eval time from the
              # template modules dir. Replaces waybar.py's runtime generate_includes()
              # glob. The dynamic position state lives in includes/position.json,
              # which waybar.py still writes; layout files include both.
              "waybar/includes/includes.json".text = let
                modulesDir = "${configDir}/.local/share/waybar/modules";
                isModule = name: type:
                  type == "regular"
                  && (lib.hasSuffix ".json" name || lib.hasSuffix ".jsonc" name);
                moduleFiles = lib.sort (a: b: a < b)
                  (lib.attrNames (lib.filterAttrs isModule (builtins.readDir modulesDir)));
              in builtins.toJSON {
                include = map (m: "${modulesDir}/${m}") moduleFiles;
              };
            };

            home.file = {
              ".local/lib/doorwayde".source = "${configDir}/.local/lib/doorwayde";
              ".local/share/doorwayde".source = "${configDir}/.local/share/doorwayde";
              ".local/share/waybar".source = "${configDir}/.local/share/waybar";
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

            # Declarative replacement for the old waybar.py-driven imperative scope+service
            # double-wrap. waybar.py --watch still runs as ExecStartPre to do the state-file
            # / config.jsonc / position.json prep work; systemd owns the waybar lifecycle.
            # See TODO.md Phase 9 (de-HyDE migration, Pass 2).
            systemd.user.services.doorwayde-waybar = {
              Unit = {
                Description = "DOORwayDE Waybar status bar";
                Documentation = "https://github.com/Alexays/Waybar";
                After = [ "graphical-session.target" ];
                PartOf = [ "graphical-session.target" ];
              };
              Service = {
                Type = "exec";
                ExitType = "cgroup";
                Slice = "app-graphical.slice";
                Restart = "always";
                RestartSec = 1;
                ExecStartPre = "%h/.local/lib/doorwayde/waybar.py --watch";
                ExecStart = "${pkgs.waybar}/bin/waybar";
              };
              Install = {
                WantedBy = [ "graphical-session.target" ];
              };
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
              echo "  journalctl --user -b -n 200 | grep -iE '(waybar|dunst|doorwayde|hypr)'"
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
