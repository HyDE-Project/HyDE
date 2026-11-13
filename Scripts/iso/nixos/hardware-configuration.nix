# Placeholder for evaluation in the source tree. The ISO installer replaces
# this file with hardware data generated from the target machine before install.
{ lib, ... }:
{
  fileSystems."/" = {
    device = lib.mkDefault "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = lib.mkDefault "/dev/disk/by-label/EFI";
    fsType = "vfat";
  };
}
