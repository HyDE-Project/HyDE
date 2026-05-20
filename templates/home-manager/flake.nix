{
  description = "DOORwayDE Home Manager Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    doorwayde = {
      url = "github:MarkusBitterman/DOORwayDE";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, doorwayde, ... }: {
    homeConfigurations."your-username" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        doorwayde.homeManagerModules.default
        {
          home.username = "your-username";
          home.homeDirectory = "/home/your-username";
          home.stateVersion = "24.05";

          doorwayde = {
            enable = true;
            monitor = "HDMI-A-1,1920x1080@100,0x0,1";
            keyboard = "us";
          };

          programs.home-manager.enable = true;
        }
      ];
    };
  };
}
