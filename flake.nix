{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hugo-site.url = "./hensg.dev";
  };

  outputs =
    { flake-utils
    , nixpkgs
    , disko
    , hugo-site
    , ...
    } @ inputs:
    {
      nixosConfigurations.website = nixpkgs.lib.nixosSystem
        {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs hugo-site;
            system = "x86_64-linux";
          };
          modules = [
            disko.nixosModules.disko
            ./nixos/website/configuration.nix
          ];
        };
    }
    // flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          rsync
          hugo
          just
        ];
      };
    });
}
