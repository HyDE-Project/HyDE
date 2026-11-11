{ lib, pkgs, repoRoot, isoSettings, ... }:
{
  assertions = [
    {
      assertion = isoSettings.targetDisk != "" && isoSettings.rootPasswordHash != "";
      message = "Build this image with Scripts/iso/nixos/build-iso.sh to select a target disk and root password.";
    }
  ];

  system.stateVersion = "25.05";
  networking.hostName = "hyde-installer";
  networking.networkmanager.enable = true;
  networking.useDHCP = lib.mkDefault true;
  time.timeZone = "Europe/Rome";
  users.users.root.initialHashedPassword = lib.mkForce isoSettings.rootPasswordHash;
  services.getty.autologinUser = lib.mkForce "root";

  environment.systemPackages = with pkgs; [
    gptfdisk
    dosfstools
    e2fsprogs
    git
    python3
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
      TimeoutStartSec = "infinity";
      ExecStart = "${pkgs.bash}/bin/bash ${./nixos-install.sh}";
    };
  };
}
