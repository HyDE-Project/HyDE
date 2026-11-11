{
  description = "HyDE - HyprDots Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      isoSettings = builtins.fromJSON (builtins.readFile ./Scripts/iso/nixos/install-settings.json);
      nixosSystem = system: modules: nixpkgs.lib.nixosSystem {
        inherit system modules;
        specialArgs = {
          inherit isoSettings;
          repoRoot = ./.;
        };
      };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in
    {
      nixosConfigurations = {
        hyde = nixosSystem "x86_64-linux" [ ./Scripts/iso/nixos/target.nix ];
        hydeIso = nixosSystem "x86_64-linux" [
          (nixpkgs.outPath + "/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix")
          ./Scripts/iso/nixos/installer-iso.nix
        ];
      };

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
