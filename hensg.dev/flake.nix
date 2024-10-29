{
  description = "Personal website for Sebastian";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    utils.url = "github:numtide/flake-utils";

    hugo-paper = {
      url = "github:adityatelange/hugo-PaperMod";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, utils, ... }:
    utils.lib.eachSystem [
      utils.lib.system.x86_64-darwin
      utils.lib.system.x86_64-linux
      utils.lib.system.aarch64-darwin
      utils.lib.system.aarch64-linux
    ]
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };
        in
        rec {

          packages.website = pkgs.stdenv.mkDerivation {
            name = "website";
            src = self;
            buildInputs = [ pkgs.git pkgs.nodePackages.prettier ];
            buildPhase = '' 
              rm -rf public
              echo "Currently in the following directory:"
              pwd
              ln -s ${inputs.hugo-paper} themes/PaperMod
              echo "themes folder currently contains:"
              ls themes
              echo "Running hugo"
              ${pkgs.hugo}/bin/hugo --baseURL https://hensg.dev --logLevel info
            '';
            installPhase = ''
              cp -r public $out
            '';
          };


          packages.default = packages.website;

          apps = rec {
            hugo = utils.lib.mkApp { drv = pkgs.hugo; };
            default = hugo;
          };

          devShells.default = pkgs.mkShell {
            buildInputs = [ pkgs.git pkgs.nixpkgs-fmt pkgs.hugo ];
          };
        });
}
