{
  description = "Home Assistant Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      perSystem = { config, self', inputs', pkgs, system, ... }: {
        # Pre-commit hooks configuration
        checks = {
          pre-commit-check = inputs.git-hooks-nix.lib.${system}.run {
            src = ./.;
            hooks = {
              yamllint = {
                enable = true;
              };
            };
          };
        };

        # Development shell
        devShells.default = pkgs.mkShell {
          inherit (config.checks.pre-commit-check) shellHook;
          buildInputs = with pkgs; [
            yamllint
          ];
        };
      };
    };
}
