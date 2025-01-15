{
  description = "Strichliste: Die Digitale Strichliste";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
  };

  outputs =
    { self, nixpkgs }@inputs:
    {
      nixosModules.strichliste = import ./module.nix self;

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
    };
}
