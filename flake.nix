{
  description = "TheOracle: NixOS on OCI Ampere A1 (free tier) - personal server";

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
        age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
        hosts.TheOracle = "/etc/nixos";
      };
    };

    libraries = import paths.store.libraries (with inputs; {
      nixos = nixCore.lib;
      treefmt = treeFormatter.lib;
      home-manager = nixHome.lib;
      darwin = nixDarwin.lib;
    });
    inherit (libraries.systems) mkPackages forEachSystem;
    inherit (libraries.attrsets) mapAttrs;

    packages = let
      base = mkPackages {
        nixpkgs = inputs.nixCore;
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
        deployDisks.nixosModules.dis
        noctalia.homeModules.defaultko
        sops-nix.nixosModules.sops
        vscode-server.nixosModules.default
        home-manager.nixosModules.home-manager
        # noctalia.homeModules.default
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

  inputs = {
    #~@ Core/Nix Infrastructure
    nixCore.url = "nixpkgs/nixos-unstable";
    nixLegacy.url = "nixpkgs/nixos-25.11";
    nixDarwin = {
      repo = "nix-darwin";
      owner = "LnL7";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };
    nixEdge = {
      ref = "nyxpkgs-unstable";
      repo = "nyx";
      owner = "chaotic-cx";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixCore";
        home-manager.follows = "nixHome";
      };
    };
    nixHome = {
      repo = "home-manager";
      owner = "nix-community";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };

    #~@ Display/Window Managers
    wmNiri = {
      repo = "niri-flake";
      owner = "sodiboo";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };
    wmMango = {
      repo = "mango";
      owner = "mangowm";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };

    #~@ Deployment
    deployDisks = {
      repo = "disko";
      owner = "nix-community";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };
    deployRS = {
      repo = "deploy-rs";
      owner = "serokell";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };
    deployColmena = {
      repo = "colmena";
      owner = "zhaofengli";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };
    deployNixosAnywhere = {
      repo = "nixos-anywhere";
      owner = "nix-community";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };

    #~@ Utilities:= formatting, tooling, secrets
    aiToolkit = {
      repo = "llm-agents.nix";
      owner = "numtide";
      type = "github";
    };
    aiHermes = {
      repo = "hermes-agent";
      owner = "NousResearch";
      type = "github";
    };
    langRust = {
      owner = "oxalica";
      repo = "rust-overlay";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };
    treeFormatter = {
      repo = "treefmt-nix";
      owner = "numtide";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };
    secretsManager = {
      repo = "sops-nix";
      owner = "Mic92";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };

    #~@ UI/UX:= shells, launchers, styling
    shellCaelestia = {
      repo = "shell";
      owner = "caelestia-dots";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixCore";
        quickshell.follows = "shellQuick";
      };
    };
    shellDankMaterial = {
      # ref = "stable";
      repo = "DankMaterialShell";
      owner = "AvengeMedia";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };
    shellDankMaterialPlugins = {
      repo = "dms-plugin-registry";
      owner = "AvengeMedia";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };
    shellNoctalia = {
      repo = "noctalia";
      owner = "noctalia-dev";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };
    shellQuick = {
      repo = "quickshell";
      owner = "outfoxxed";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };
    styleManager = {
      repo = "stylix";
      owner = "nix-community";
      type = "github";
      inputs.nixpkgs.follows = "nixCore";
    };

    #~@ Applications
    vicinae = {
      repo = "vicinae";
      owner = "vicinaehq";
      type = "github";
    };
    vscode-server = {
      repo = "nixos-vscode-server";
      owner = "nix-community";
      inputs.nixpkgs.follows = "nixCore";
      type = "github";
    };
    zenBrowser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixCore";
        home-manager.follows = "nixHome";
      };
    };
  };

  # inputs = {
  #   nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  #   nix-darwin.url = "github:LnL7/nix-darwin";

  #   home-manager = {
  #     url = "github:nix-community/home-manager";
  #     inputs.nixpkgs.follows = "nixpkgs";
  #   };

  #   disko = {
  #     url = "github:nix-community/disko";
  #     inputs.nixpkgs.follows = "nixpkgs";
  #   };

  #   deploy-rs = {
  #     url = "github:serokell/deploy-rs";
  #     inputs.nixpkgs.follows = "nixpkgs";
  #   };

  #   rust-overlay = {
  #     url = "github:oxalica/rust-overlay";
  #     inputs.nixpkgs.follows = "nixpkgs";
  #   };

  #   sops-nix = {
  #     url = "github:Mic92/sops-nix";
  #     inputs.nixpkgs.follows = "nixpkgs";
  #   };

  #   vscode-server = {
  #     url = "github:nix-community/nixos-vscode-server";
  #     inputs.nixpkgs.follows = "nixpkgs";
  #   };

  #   treefmt-nix = {
  #     url = "github:numtide/treefmt-nix";
  #     inputs.nixpkgs.follows = "nixpkgs";
  #   };
  # };
}
