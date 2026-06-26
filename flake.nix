{
  description = "TheOracle: NixOS on OCI Ampere A1 (free tier) - personal server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
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
        secrets = ./secrets;
        defaultSopsFile = ./secrets/secrets.yaml;
      };
      local = {
        age.keyFile = "/var/lib/sops-nix/key.txt";
        hosts.TheOracle = "/etc/nixos";
      };
    };

    libraries = import paths.store.libraries (with inputs; {
      nixos = nixpkgs.lib;
      treefmt = treefmt-nix.lib;
      home-manager = home-manager.lib;
      darwin = nix-darwin.lib;
    });
    inherit (libraries.systems) mkPackages forEachSystem;
    inherit (libraries.attrsets) mapAttrs;

    packages = let
      base = mkPackages {
        inherit (inputs) nixpkgs;
        config = {allowUnfree = true;};
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
        disko.nixosModules.disko
        sops-nix.nixosModules.sops
        vscode-server.nixosModules.default
        home-manager.nixosModules.home-manager
      ];
      darwin = [];
      home-manager = [];
    };

    extraArgs = {
      inherit self inputs;
      lix = libraries;
    };
  in
    import paths.store.hosts {
      inherit paths libraries packages modules extraArgs;
      hosts = {
        TheOracle = {
          class = "nixos";
          system = "aarch64-linux";
          profile = "server";
        };
      };
    }
    // {inherit (packages.treefmt) formatter checks;};
}
