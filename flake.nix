{
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

        snowfall-lib = {
            url = "github:snowfallorg/lib";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs = inputs:
        inputs.snowfall-lib.mkFlake {
            inherit inputs;
            src = ./.;

            # Configure Snowfall Lib, all of these settings are optional.
            snowfall = {
                # Tell Snowfall Lib to look in the `./nix/` directory for your
                # Nix files.
                root = ./nix;

                # Choose a namespace to use for your flake's packages, library,
                # and overlays.
                namespace = "courier";

            };
        };
}
