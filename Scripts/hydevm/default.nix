{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
}:

let
  # Import the unified shell script
  hydevmScript = pkgs.writeShellApplication {
    name = "hydevm";
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
    text = builtins.readFile ./hydevm.sh;
  };
in
{
  defaultPackage = hydevmScript;

  mkHydeVM =
    {
      memory ? "4G",
      cpus ? 2,
      extraArgs ? "",
    }:
    pkgs.writeShellApplication {
      name = "run-hydevm";
      runtimeInputs = [ hydevmScript ];
      text = ''
        VM_MEMORY="${memory}" VM_CPUS="${toString cpus}" VM_EXTRA_ARGS="${extraArgs}" hydevm "$@"
      '';
    };
}
