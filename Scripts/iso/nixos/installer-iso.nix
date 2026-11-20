{ config, lib, pkgs, repoRoot, isoSettings, ... }:
{
  assertions = [
    {
      assertion = isoSettings.targetDisk != "";
      message = "Build this image with Scripts/iso/nixos/build-iso.sh to select a target disk.";
    }
  ];

  system.stateVersion = "25.05";
  networking.hostName = "hyde-installer";
  networking.networkmanager.enable = true;
  networking.useDHCP = lib.mkDefault true;
  time.timeZone = "UTC";
  services.getty.autologinUser = lib.mkForce "root";

  environment.systemPackages = with pkgs; [
    curl
    gptfdisk
    dosfstools
    e2fsprogs
    git
    python3
    parted
    util-linux
  ];
  environment.etc."hyde-iso-settings.json".text = builtins.toJSON isoSettings;
  environment.etc."hyde-installer-source".source = repoRoot;

  systemd.services.hyde-nixos-install = {
    description = "Install the preconfigured HyDE NixOS system to the selected disk";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    unitConfig.ConditionPathExists = "/etc/hyde-iso-settings.json";
    serviceConfig = {
      Type = "oneshot";
      TimeoutStartSec = "5min";
      StandardInput = "tty";
      StandardOutput = "tty";
      StandardError = "journal";
      TTYPath = "/dev/tty1";
      TTYReset = true;
      TTYVHangup = true;
      TTYVTDisallocate = true;
      ExecStart = "${pkgs.bash}/bin/bash ${./nixos-install.sh}";
    };
    unitConfig.Conflicts = "getty@tty1.service";
    path = [ config.system.path ];
  };
}
