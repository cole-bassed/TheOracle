{
  description = "TheOracle: NixOS on OCI Ampere A1 (free tier) - personal server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";

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

  outputs = {self, ...} @ inputs: let
    paths = {
      store = {
        src = ./.;
        modules = ./modules;
        libraries = ./libraries;
        formatter = ./utilities/formatter;
        hosts = ./modules/hosts;
        users = ./modules/users;
      };
      hosts = {
        TheOracle = "/etc/nixos";
      };
    };

    libraries = import paths.store.libraries (with inputs; {
      nixos = nixpkgs.lib;
      treefmt = treefmt-nix.lib;
      home-manager = home-manager.lib;
      darwin = nix-darwin.lib;
    });
    inherit (libraries.systems) mkPackages forEachSystem;
    inherit (libraries.attrsets) listToAttrs mapAttrsToList mapAttrs;
    inherit (libraries.strings) mkHostId;
    inherit (libraries.lists) groupBy;

    mkHosts = hosts: let
      builders = {
        nixos = libraries.nixos.nixosSystem;
        darwin = libraries.darwin.darwinSystem;
      };

      build = name: cfg: let
        class = cfg.class or "nixos";
      in {
        inherit name;
        value = (builders.${class} or (throw "Unknown class: ${class}")) {
          specialArgs = {inherit self paths inputs;};
          modules =
            [
              (paths.store.hosts + "/${name}")
              {
                networking = {
                  hostName = name;
                  hostId = cfg.id or (mkHostId name);
                };
                nixpkgs = {
                  config.allowUnfree = true;
                  pkgs = packages.final.${cfg.system};
                };
              }
            ]
            ++ (
              map
              (user: paths.store.users + "/${user}")
              (cfg.users or ["Craole" "Cole-bassed"])
            )
            ++ (modules.${class} or []);
        };
      };

      grouped = groupBy (host: host.class) (mapAttrsToList build hosts);
    in
      mapAttrs (class: hostList: listToAttrs hostList) {
        nixos = grouped.nixos or [];
        darwin = grouped.darwin or [];
      };

    packages = let
      base = mkPackages {
        inherit (inputs) nixpkgs;
        overlays = with inputs; [
          rust-overlay.overlays.default
        ];
      };
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
      ];
      darwin = [];
      home-manager = [];
    };
  in
    {inherit (packages.treefmt) formatter checks;}
    // mkHosts {
      TheOracle = {
        class = "nixos";
        system = "aarch64-linux";
      };
    };
}
