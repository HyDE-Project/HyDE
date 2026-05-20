{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
}:

let
  # Import the unified shell script
  doorwaydevmScript = pkgs.writeShellApplication {
    name = "doorwaydevm";
    runtimeInputs = with pkgs; [
      qemu
      curl
      python3
      git
      coreutils
      findutils
      gnused
      gawk
    ];
    text = builtins.readFile ./doorwaydevm.sh;
  };
in
{
  defaultPackage = doorwaydevmScript;

  mkHydeVM =
    {
      memory ? "4G",
      cpus ? 2,
      extraArgs ? "",
    }:
    pkgs.writeShellApplication {
      name = "run-doorwaydevm";
      runtimeInputs = [ doorwaydevmScript ];
      text = ''
        VM_MEMORY="${memory}" VM_CPUS="${toString cpus}" VM_EXTRA_ARGS="${extraArgs}" doorwaydevm "$@"
      '';
    };
}
