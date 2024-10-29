+++
title = 'Nix and Rust'
date = 2024-07-14T08:02:14-03:00
tags = ["rust", "nix"]
categories = ["nix"]
showtoc = true
+++

Configuring a basic Nix development environment for Rust projects with Crane.

<!--more-->


Requirements:
- [Nix](https://nix.dev/manual/nix/2.18/quick-start)
- Flake support: add `experimental-features = nix-command flakes` to `nix.conf`

## Initializing with Crane

Crane provides a simplified template that generates a `flake.nix` file to streamline building Rust crates.

1. Start by creating a project directory:
```shell
mkdir my-rust-project
cd my-rust-project
```

2. Initialize the flake using the Crane template:
```shell
nix flake init -t github:ipetkov/crane#quick-start-simple
```

3. Start development environment
```shell
nix develop
```

## What is inside the `flake.nix` from Crane

### Inputs
Each input represents a package or utility used to configure the project: 
- nixpkgs: Provides access to all packages in NixOS's unstable channel.
- crane: The core library for Rust project configuration.
- flake-utils: Utilities to aid in building across multiple platforms (macOS, Linux, Windows).

```nix
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    crane.url = "github:ipetkov/crane";
    flake-utils.url = "github:numtide/flake-utils";
  };
```

### Outputs

The outputs sections returns the artifacts/packages the flake produces.
It takes a set of arguments that can be used to construct the output.
```nix
  outputs = { self, nixpkgs, crane, flake-utils, ... }:
```

### Let variables

```nix
    # for each system (e.g.: x86_64-linux, x86_64-darwin)
    flake-utils.lib.eachDefaultSystem (system:
      let
        # set pkgs to the system's pkgs
        pkgs = nixpkgs.legacyPackages.${system}; 
        # make crane for pkgs of that system
        craneLib = crane.mkLib pkgs;
        # common args that will be used in artifacts
        commonArgs = {
          # clean up the source dir for build
          src = craneLib.cleanCargoSource ./.;
          strictDeps = true;
          # can add the required build inputs for artifacts
          # adding libiconv for macOS
          buildInputs = [ ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
            pkgs.libiconv
          ];
        };

        # main artifact building block
        my-crate = craneLib.buildPackage (commonArgs // {
          cargoArtifacts = craneLib.buildDepsOnly commonArgs;
        });
      in { ... }
```

1. `flake-utils`:
Provides a helper function, eachDefaultSystem, to ensure the build is cross-platform.

2. `craneLib.buildPackage`:
Used to build the rust project package.

3. `commonArgs // { ... }`:
Merges attribute sets, right set overrides

4. `cargoArtifacts`:
It is an option withing `buildPackage` that specifies what artifacts should be 
built by `Cargo`.

5. `craneLib.buildDepsOnly`: 
Specifies that we want only the dependencies for the package to be built


## craneLib.buildDepsOnly
```nix
    my-crate = craneLib.buildPackage (commonArgs // {
      cargoArtifacts = craneLib.buildDepsOnly commonArgs;
    });
```

Building dependencies separately can make subsequent builds faster if 
dependencies don’t change. This allows for a lighter build process, where 
only the libraries that `my-crate` depends on are compiled, without building 
the final executable or library artifact. 

This approach is especially useful for projects with large dependency 
trees that change less frequently than the application code, particularly 
when dependencies are shared across multiple crates. It also benefits 
environments where dependencies are costly to fetch or compile, 
such as CI/CD pipelines.

## packages and apps

```nix
    packages.default = my-crate;
    apps.default = flake-utils.lib.mkApp {
        drv = my-crate;
    };
```
1. `packages`: this makes the crate accessible as the final output when we run
`nix build .` Building the complete package, including the final binary/library.

2. `mkApp`: make crate available as an executable application, so we can run `nix run .`

