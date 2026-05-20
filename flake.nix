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
        swww

        # System integration
        brightnessctl
        playerctl
        pamixer
        libnotify

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
        nixfmt-rfc-style  # Nix formatter

        # Python
        python3
        ruff         # Python linter/formatter

        # General
        git
        direnv
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
              "hypr".source = "${configDir}/.config/hypr";
              "waybar".source = "${configDir}/.config/waybar";
              "rofi".source = "${configDir}/.config/rofi";
              "dunst".source = "${configDir}/.config/dunst";
              "doorwayde".source = "${configDir}/.config/doorwayde";
              "kitty".source = "${configDir}/.config/kitty";
              "wlogout".source = "${configDir}/.config/wlogout";

              "hypr/monitors.conf".text = ''
                # DOORwayDE Monitor Configuration
                monitor=${cfg.monitor}
                ${lib.concatStringsSep "\n" (map (m: "monitor=${m}") cfg.extraMonitors)}
              '';

              "hypr/userprefs.conf".text = ''
                input {
                    kb_layout = ${cfg.keyboard}
                    follow_mouse = 1
                    touchpad { natural_scroll = yes }
                }
                misc {
                    enable_swallow = true
                    swallow_regex = (kitty|Alacritty|foot)
                }
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

            home.sessionPath = [ "$HOME/.local/bin" ];
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
              echo "  shellcheck Scripts/*.sh  - Lint"
              echo "  nix develop             - Enter this shell"
              echo ""
            '';
          };
        });

      # Expose the dependency list for HALLway to import
      lib.doorwaydeDeps = doorwaydeDeps;
    };
}
