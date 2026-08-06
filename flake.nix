{
  description = "Migrated NixOS Flake Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, ... }@inputs: {
    nixosConfigurations.kevinix = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        { nixpkgs.overlays = [ inputs.noctalia.overlays.default ]; }
        ({ pkgs, ... }: {
          networking.hostName = "kevinix";
          boot.kernelModules = [ "lenovo-acpi" ];
          systemd.services.disable-mic-led = {
            description = "Turn off Lenovo Mic Mute LED permanently";
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${pkgs.bash}/bin/bash -c 'echo 0 > /sys/class/leds/platform::micmute/brightness'";
            };
          };
        })
        ./hardware-configuration.nix
        ./configuration.nix
        ./modules/desktop/niri.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { nixSystem = "kevinix"; };
          home-manager.users.kevin = {
            imports = [ ./home/common.nix ./home/linux.nix ];
          };
        }
      ];
    };

    nixosConfigurations.kevinixpc = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        { nixpkgs.overlays = [ inputs.noctalia.overlays.default ]; }
        { networking.hostName = "kevinixpc"; }
        ./hardware-configuration-kevinixpc.nix
        ./configuration.nix
        ./modules/desktop/niri.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { nixSystem = "kevinixpc"; };
          home-manager.users.kevin = {
            imports = [ ./home/common.nix ./home/linux.nix ];
          };
        }
      ];
    };

    darwinConfigurations.kevmac = nix-darwin.lib.darwinSystem {
      specialArgs = { inherit inputs; };
      modules = [
        ./modules/darwin/system.nix
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.extraSpecialArgs = { nixSystem = "kevmac"; };
          home-manager.users.kevinsmith = {
            imports = [ ./home/common.nix ./home/darwin.nix ];
          };
        }
      ];
    };

    darwinConfigurations.kevmini = nix-darwin.lib.darwinSystem {
      specialArgs = { inherit inputs; };
      modules = [
        ./modules/darwin/system.nix
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.extraSpecialArgs = { nixSystem = "kevmini"; };
          home-manager.users.kevinsmith = {
            imports = [ ./home/common.nix ./home/darwin.nix ];
          };
        }
      ];
    };
  };
}
