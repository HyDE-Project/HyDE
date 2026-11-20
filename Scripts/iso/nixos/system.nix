{ config, lib, pkgs, repoRoot, isoSettings, ... }:
let
  requiredPackages = [
    "ark"
    "awww"
    "blueman"
    "brightnessctl"
    "cava"
    "cliphist"
    "kdePackages.dolphin"
    "dunst"
    "eza"
    "fastfetch"
    "firefox"
    "fish"
    "fzf"
    "gcc"
    "gobject-introspection"
    "grim"
    "hypridle"
    "hyprlock"
    "hyprpaper"
    "hyprpicker"
    "hyprpolkitagent"
    "hyprsunset"
    "imagemagick"
    "kitty"
    "lua"
    "luarocks"
    "networkmanagerapplet"
    "nwg-displays"
    "pamixer"
    "pavucontrol"
    "playerctl"
    "rofi"
    "satty"
    "slurp"
    "starship"
    "swww"
    "udiskie"
    "unzip"
    "uv"
    "waybar"
    "wlogout"
    "wl-clip-persist"
    "wl-clipboard"
    "xdg-desktop-portal-gtk"
    "xdg-desktop-portal-hyprland"
    "xdg-user-dirs"
    "zsh"
  ];
  resolvedPackages = map (name: lib.attrByPath (lib.splitString "." name) null pkgs) requiredPackages;
  missingPackages = lib.filter (package: package == null) resolvedPackages;
  hyprquery = pkgs.stdenv.mkDerivation {
    pname = "hyprquery";
    version = "0.1.0-002af783";
    src = pkgs.fetchFromGitHub {
      owner = "HyDE-Project";
      repo = "hyprquery";
      rev = "002af783eeb8c487a4bf90d75e5a804340557967";
      hash = "sha256-1ZCMCwDaZUM/hNJgG5DAT8S2pNhRfvSRW1z5WT1MGTg=";
    };
    nativeBuildInputs = with pkgs; [ cmake pkg-config ];
    buildInputs = with pkgs; [ cli11 hyprlang libxkbcommon nlohmann_json ];
    cmakeFlags = [ "-DHYPRQUERY_DISTRO_BUILD=ON" ];
  };
in
{
  assertions = [
    {
      assertion = missingPackages == [ ];
      message = "Missing Nixpkgs packages required by HyDE: ${lib.concatStringsSep ", " (lib.filter (name: lib.attrByPath (lib.splitString "." name) null pkgs == null) requiredPackages)}";
    }
  ];

  system.stateVersion = "25.05";
  networking.hostName = "hydeos";
  networking.networkmanager.enable = true;
  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.zfs.forceImportRoot = false;

  users.mutableUsers = true;
  users.users.root.shell = pkgs.zsh;
  users.defaultUserShell = pkgs.zsh;
  programs.zsh.enable = true;

  environment.systemPackages = builtins.filter (package: package != null) resolvedPackages
    ++ [ hyprquery ]
    ++ (with pkgs; [
      curl
      gnumake
      git
      jq
      pkg-config
      python3
      sudo
      unzip
      wget
      xdg-utils
    ]);
  environment.etc."hyde-config".source = repoRoot + "/Configs";
  system.activationScripts.hyde-skeleton = {
    deps = [ "etc" ];
    text = ''
      if [ ! -e /etc/skel/.config/hypr/hyprland.lua ]; then
        install -d -m 0755 /etc/skel
        cp -R /etc/hyde-config/. /etc/skel/
        chmod -R u+rwX /etc/skel
      fi
    '';
  };

  programs.hyprland.enable = true;
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.dbus.enable = true;
  security.polkit.enable = true;
  security.sudo.wheelNeedsPassword = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  services.blueman.enable = true;

  systemd.services.hyde-account-choice = {
    description = "Create the normal desktop account";
    wantedBy = [ "multi-user.target" ];
    before = [ "display-manager.service" ];
    unitConfig = {
      ConditionPathExists = "!/var/lib/hyde-account-choice.done";
      Conflicts = "getty@tty1.service";
    };
    serviceConfig = {
      Type = "oneshot";
      TimeoutStartSec = "2h";
      StandardInput = "tty";
      StandardOutput = "tty";
      StandardError = "journal";
      TTYPath = "/dev/tty1";
      TTYReset = true;
      TTYVHangup = true;
      TTYVTDisallocate = true;
      ExecStart = "${pkgs.bash}/bin/bash ${./account-choice.sh}";
    };
    path = [ config.system.path ];
  };
}
