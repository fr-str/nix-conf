{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-edge.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    nvidia-patch = {
      url = "github:keylase/nvidia-patch";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nixpkgs-edge, home-manager, plasma-manager, nvidia-patch, ... }@attrs: {
    nixosConfigurations."nixos" = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      specialArgs = {
        inherit attrs;

        pkgs-edge = import nixpkgs-edge {
          inherit system;
          config.allowUnfree = true;
        };
      };

      modules = [
        ({ ... }: { nix.registry.nixpkgs.flake = nixpkgs; })
        ./hosts/blaszak

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          # home-manager.sharedModules = [ plasma-manager.homeManagerModules.plasma-manager ];
        }
      ];
    };
  };
}
