# flake.nix
{
  description = "TheOracle: NixOS on OCI Ampere A1 (free tier) - personal server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    treefmt-nix,
    home-manager,
    ...
  } @ inputs: let
    paths = {
      store = {
        src = ./.;
        modules = ./modules;
        libraries = ./libraries;
        formatter = ./utilities/formatter;
      };
      hosts = {
        TheOracle = "/etc/nixos";
      };
    };

    libraries = import paths.store.libraries {
      nixpkgs = nixpkgs.lib;
      treefmt = treefmt-nix.lib;
      home-manager = home-manager.lib;
    };
    inherit (libraries.systems) mkPackages nixosSystem;

    overlays = with inputs; [
      rust-overlay.overlays.default
    ];

    packages = mkPackages {
      inherit nixpkgs overlays;
    };

    modules = with inputs; {
      nixos = [
        sops-nix.nixosModules.sops
        vscode-server.nixosModules.default
        home-manager.nixosModules.home-manager
        paths.store.modules.core
      ];
      darwin = [];
      home-manager = [];
    };

    fmt = import paths.store.formatter {
      projectRoot = paths.store.src;
      inherit libraries packages;
    };
  in
    {
      nixosConfigurations = {
        TheOracle = let
          system = "aarch64-linux";
          class = "nixos";
        in
          nixosSystem {
            specialArgs = {inherit self paths inputs;};
            modules =
              [
                {
                  nixpkgs = {
                    config.allowUnfree = true;
                    pkgs = packages.${system};
                  };
                }
              ]
              ++ (modules.${class} or []);
          };
      };
    }
    // fmt;
}
