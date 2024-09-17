{
  description = "Strichliste: Die Digitale Strichliste";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
  };

  outputs = { self, nixpkgs }@inputs : let

    pkgs = import nixpkgs { system = "x86_64-linux"; };

  in {
    nixosModules.strichliste = import ./module.nix self;
  };
}
