{
  description = "Home Assistant Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      imports = [
        inputs.git-hooks-nix.flakeModule
        inputs.treefmt-nix.flakeModule
      ];
      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        {
          # Formatting configuration
          treefmt = {
            programs = {
              nixfmt.enable = true; # Nix formatter
              prettier.enable = true; # YAML, Markdown
              ruff-format.enable = true; # Python formatter
            };
          };

          pre-commit = {
            check.enable = false; # Docker network is not avaialble in the nix build environment.

            settings.hooks.home-assistant-config = {
              enable = true;
              name = "Home Assistant Config Check";
              entry = "./scripts/validate-config";
              files = "\\.(yaml|yml)$";
              pass_filenames = false;
              extraPackages = [ pkgs.podman ];
            };
          };

          # Development shell
          devShells.default = pkgs.mkShell {
            inherit (config.pre-commit) shellHook;
            packages = config.pre-commit.settings.enabledPackages ++ [
              pkgs.home-assistant-cli
            ];
          };
        };
    };
}
