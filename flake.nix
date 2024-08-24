{
  description = "NixOS and Home-Manager presets for opt-in persistent setups";
  outputs = { self, nixpkgs }:
    with nixpkgs.lib;
    let
      # Recursively constructs an attrset of a given folder, recursing on directories, value of attrs is the filetype
      getDir = dir:
        mapAttrs (file: type:
          if type == "directory" then getDir "${dir}/${file}" else type)
        (builtins.readDir dir);
      # Collects all files of a directory as a list of strings of paths
      files = dir:
        collect isString
        (mapAttrsRecursive (path: type: concatStringsSep "/" path)
          (getDir dir));
      # Filters out directories that don't end with .nix, also makes the strings absolute
      validFiles = dir:
        map (file: ./. + "/${file}")
        (filter (file: hasSuffix ".nix" file) (files dir));
    in {
      nixosModules.nix-persist = { imports = validFiles ./modules/nixos; };
      homeModules.nix-persist = {
        imports = validFiles ./modules/home-manager;
      };
      nixosModule = self.nixosModules.nix-persist;
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
