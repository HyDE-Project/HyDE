{
  description = "HALLwayDE - Hyprland Desktop Environment for HALLway OS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);

      # HALLwayDE runtime dependencies
      hallwaydeDeps = pkgs: with pkgs; [
        # Core Hyprland ecosystem
        hyprland
        hyprlock
        hypridle
        hyprpaper

        # UI components
        waybar
        rofi-wayland
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
        shellcheck
        shfmt
        python3
        git
      ];

      # Home Manager module definition
      hallwaydeModule = { config, lib, pkgs, ... }:
        let
          cfg = config.hallwayde;
          configDir = "${self}/Configs";
        in {
          options.hallwayde = {
            enable = lib.mkEnableOption "HALLwayDE Hyprland configuration";

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
              description = "Install HALLwayDE dependencies";
            };
          };

          config = lib.mkIf cfg.enable {
            home.packages = lib.mkIf cfg.installPackages (hallwaydeDeps pkgs);

            xdg.configFile = {
              "hypr".source = "${configDir}/.config/hypr";
              "waybar".source = "${configDir}/.config/waybar";
              "rofi".source = "${configDir}/.config/rofi";
              "dunst".source = "${configDir}/.config/dunst";
              "hallwayde".source = "${configDir}/.config/hallwayde";
              "kitty".source = "${configDir}/.config/kitty";
              "wlogout".source = "${configDir}/.config/wlogout";

              "hypr/monitors.conf".text = ''
                # HALLwayDE Monitor Configuration
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
              ".local/lib/hallwayde".source = "${configDir}/.local/lib/hallwayde";
              ".local/share/hallwayde".source = "${configDir}/.local/share/hallwayde";
              ".local/share/hypr".source = "${configDir}/.local/share/hypr";
              ".local/bin/hallwayde-shell" = {
                source = "${configDir}/.local/bin/hallwayde-shell";
                executable = true;
              };
              ".local/bin/hallwaydectl" = {
                source = "${configDir}/.local/bin/hallwaydectl";
                executable = true;
              };
              ".local/bin/hallwayde-ipc" = {
                source = "${configDir}/.local/bin/hallwayde-ipc";
                executable = true;
              };
            };

            home.sessionPath = [ "$HOME/.local/bin" ];
          };
        };

    in {
      # Home Manager module (the main export)
      # Usage in HALLway flake:
      #   inputs.hallwayde.url = "github:MarkusBitterman/HALLwayDE";
      #   ...
      #   imports = [ inputs.hallwayde.homeManagerModules.default ];
      #   hallwayde.enable = true;
      homeManagerModules = {
        default = hallwaydeModule;
        hallwayde = hallwaydeModule;
      };

      # Development shell with all Hyprland packages
      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.mkShell {
            name = "hallwayde-dev";
            buildInputs = (hallwaydeDeps pkgs) ++ (devDeps pkgs);
            shellHook = ''
              echo "HALLwayDE Development Shell"
              echo "All Hyprland packages available."
              echo ""
              echo "  shellcheck Scripts/*.sh  - Lint"
              echo "  nix develop             - Enter this shell"
              echo ""
            '';
          };
        });

      # Expose the dependency list for HALLway to import
      lib.hallwaydeDeps = hallwaydeDeps;
    };
}
