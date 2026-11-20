{
  description = "HyDE - HyprDots Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in
    {
      apps = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          hydevm = import ./Scripts/hydevm { inherit pkgs; };
        in
        {
          default = {
            type = "app";
            program = "${hydevm.defaultPackage}/bin/hydevm";
          };
          hydevm = {
            type = "app";
            program = "${hydevm.defaultPackage}/bin/hydevm";
          };
        }
      );

      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          hydevm = import ./Scripts/hydevm { inherit pkgs; };
        in
        {
          default = hydevm.defaultPackage;
          hydevm = hydevm.defaultPackage;
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              qemu
              curl
              python3
              git
              coreutils
              findutils
              gnused
              gawk
            ];
          };
        }
      );
    };
}
