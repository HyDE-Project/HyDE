{
  description = "HALLwayDE Home Manager Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hallwayde = {
      url = "github:MarkusBitterman/HALLwayDE";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, hallwayde, ... }: {
    homeConfigurations."your-username" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        hallwayde.homeManagerModules.default
        {
          home.username = "your-username";
          home.homeDirectory = "/home/your-username";
          home.stateVersion = "24.05";

          hallwayde = {
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
