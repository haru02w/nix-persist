{
  description = "NixOS and Home-Manager presets for opt-in persistent setups";
  outputs = { self, nixpkgs, impermanence, ... }:
    with nixpkgs.lib; {
      nixosModules.nix-persist = {
        imports = [ impermanence.nixosModules.impermanence ./modules/nixos ];
      };
      homeModules.nix-persist = { imports = [ ./modules/home-manager ]; };

      checks.x86_64-linux.example = (nixosSystem {
        system = "x86_64-linux";
        modules = [
          self.nixosModules.nix-persist
          {
            environment.nix-persist = { path = "/persist"; };
            boot.loader.systemd-boot.enable = true;
            fileSystems."/".device = "none";
          }
        ];
      }).config.system.build.toplevel;
    };
  inputs = {
    impermanence.url = "github:nix-community/impermanence";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/home-manager";
    };
  };
}
