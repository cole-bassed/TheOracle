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
    inherit (libraries.systems) forEachSystem;
    inherit (libraries.attrsets) mapAttrs;

    overlays = with inputs; [
      rust-overlay.overlays.default
    ];

    packages = let
      base = mkPackages {inherit nixpkgs overlays;};
      treefmt = import paths.store.formatter {
        inherit forEachSystem mapAttrs;
        inherit (libraries.treefmt) evalModule;
        projectRoot = paths.store.src;
        packages = base;
      };
      final = treefmt.packages;
    in {inherit base treefmt final;};

    modules = with inputs; {
      nixos = [
        sops-nix.nixosModules.sops
        vscode-server.nixosModules.default
        home-manager.nixosModules.home-manager
        (paths.store.modules + "/core")
      ];
      darwin = [];
      home-manager = [];
    };
  in {
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
                  pkgs = packages.final.${system};
                };
              }
            ]
            ++ (modules.${class} or []);
        };
    };
    inherit (packages.treefmt) formatter checks;
  };
}
