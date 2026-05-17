{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
}:

let
  # Import the unified shell script
  hallwaydevmScript = pkgs.writeShellApplication {
    name = "hallwaydevm";
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
    text = builtins.readFile ./hallwaydevm.sh;
  };
in
{
  defaultPackage = hallwaydevmScript;

  mkHydeVM =
    {
      memory ? "4G",
      cpus ? 2,
      extraArgs ? "",
    }:
    pkgs.writeShellApplication {
      name = "run-hallwaydevm";
      runtimeInputs = [ hallwaydevmScript ];
      text = ''
        VM_MEMORY="${memory}" VM_CPUS="${toString cpus}" VM_EXTRA_ARGS="${extraArgs}" hallwaydevm "$@"
      '';
    };
}
