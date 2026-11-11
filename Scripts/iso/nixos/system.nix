{ lib, pkgs, repoRoot, isoSettings, ... }:
let
  requiredPackages = [
    "ark"
    "blueman"
    "brightnessctl"
    "cava"
    "cliphist"
    "dunst"
    "eza"
    "fastfetch"
    "firefox"
    "fish"
    "fzf"
    "grim"
    "hypridle"
    "hyprlock"
    "hyprpaper"
    "hyprpicker"
    "hyprpolkitagent"
    "hyprsunset"
    "imagemagick"
    "kitty"
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
  hydeRootSession = pkgs.writeTextFile {
    name = "hyde-root-session";
    destination = "/share/wayland-sessions/hyde-root.desktop";
    text = ''
      [Desktop Entry]
      Name=HyDE (root)
      Comment=HyDE session running as root
      Exec=Hyprland --i-am-really-stupid
      Type=Application
    '';
    passthru.providedSessions = [ "hyde-root" ];
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
  networking.hostName = "hyde";
  networking.networkmanager.enable = true;
  time.timeZone = "Europe/Rome";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.zfs.forceImportRoot = false;

  users.mutableUsers = true;
  users.users.root.hashedPasswordFile = "/var/lib/hyde-root-password";
  users.users.root.shell = pkgs.zsh;
  users.defaultUserShell = pkgs.zsh;
  programs.zsh.enable = true;

  environment.systemPackages = builtins.filter (package: package != null) resolvedPackages
    ++ (with pkgs; [
      curl
      git
      jq
      python3
      sudo
      unzip
      wget
      xdg-utils
    ]);
  environment.etc."hyde-config".source = repoRoot + "/Configs";
  environment.etc."sddm.conf.d/10-hyde-root.conf".text = ''
    [Users]
    AllowRootLogin=true
  '';

  system.activationScripts.hyde-skeleton = {
    deps = [ "etc" ];
    text = ''
      if [ ! -e /etc/skel/.config/hypr/hyprland.lua ]; then
        install -d -m 0755 /etc/skel
        cp -a /etc/hyde-config/. /etc/skel/
      fi
    '';
  };

  programs.hyprland.enable = true;
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.displayManager.sessionPackages = [ hydeRootSession ];
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

  systemd.services.hyde-seed-root = {
    description = "Install the shared HyDE defaults for root and new users";
    wantedBy = [ "multi-user.target" ];
    before = [ "hyde-account-choice.service" "display-manager.service" ];
    after = [ "local-fs.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      if [ ! -e /root/.config/hypr/hyprland.lua ]; then
        cp -a /etc/skel/. /root/
      fi
    '';
  };

  systemd.services.hyde-account-choice = {
    description = "Choose a normal desktop account or keep using root";
    wantedBy = [ "multi-user.target" ];
    after = [ "hyde-seed-root.service" ];
    before = [ "display-manager.service" ];
    unitConfig.ConditionPathExists = "!/var/lib/hyde-account-choice.done";
    serviceConfig = {
      Type = "oneshot";
      TimeoutStartSec = "infinity";
      StandardInput = "tty";
      StandardOutput = "tty";
      StandardError = "journal";
      TTYPath = "/dev/tty1";
      TTYReset = true;
      TTYVHangup = true;
      TTYVTDisallocate = true;
      ExecStart = "${pkgs.bash}/bin/bash ${./account-choice.sh}";
    };
  };
}
