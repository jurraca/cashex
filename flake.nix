{
  description = "An Elixir library for the Cashu ecash protocol.";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-23.11;
    flake-utils.url = github:numtide/flake-utils;
  };

  outputs = { self, nixpkgs, flake-utils }:
    # build for each default system of flake-utils: ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"]
    flake-utils.lib.eachDefaultSystem (system:
      let
        # Declare pkgs for the specific target system we're building for.
        pkgs = import nixpkgs { inherit system ; };
        # Declare BEAM version we want to use. If not, defaults to the latest on this channel.
        beamPackages = pkgs.beam.packagesWith pkgs.beam.interpreters.erlang;
        # Declare the Elixir version you want to use. If not, defaults to the latest on this channel.
        elixir = beamPackages.elixir_1_15;
        # Import a development shell we'll declare in `shell.nix`.
        devShell = import ./shell.nix { inherit pkgs beamPackages; };

        cashex = let
            lib = pkgs.lib;
            mixNixDeps = import ./deps.nix {inherit lib beamPackages;};
          in beamPackages.mixRelease {
            pname = "cashex";
            # Elixir app source path
            src = ./.;
            version = "0.1.0";

            # FIXME: mixNixDeps was specified in the FIXME above. Uncomment the next line.
            inherit mixNixDeps;

            # Add other inputs to the build if you need to
            buildInputs = [ elixir ];
          };
      in
      {
        devShells.default = devShell;
        packages.default = cashex;
      }
    );
}

