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

    modules = with inputs; {
      nixos = [
        aiHermes.nixosModules.default
        deployDisks.nixosModules.default
        nixHome.nixosModules.default
        secretsManager.nixosModules.default
        shellDankMaterial.nixosModules.default
        shellDankMaterialPlugins.nixosModules.default
        shellNoctalia.nixosModules.default
        styleManager.nixosModules.default
        vicinae.nixosModules.default
        vscodeServer.nixosModules.default
        wmMango.nixosModules.mango
        wmNiri.nixosModules.niri
      ];
      darwin = [
        nixHome.darwinModules.default
      ];
      home = [
        # TODO: What to do if an input has both nixosModules and homeModules?
        shellCaelestia.homeManagerModules.default
        shellDankMaterial.homeModules.default
        shellDankMaterialPlugins.homeModules.default
        shellNoctalia.homeModules.default
        styleManager.homeModules.default
        vicinae.homeModules.default
        vscodeServer.homeModules.default
        wmMango.hmModules.mango
        wmNiri.hmModules.niri
        browserZen.homeModules.default
      ];
    };

    packages = let
      base = mkPackages {
        nixpkgs = inputs.nixCore;
        config = {allowUnfree = true;};
        overlays = with inputs; [
          langRust.overlays.default
          aiToolkit.overlays.default
          deployColmena.overlays.default
          deployRS.overlays.default
          shellQuick.overlays.default
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
    deployAnywhere = {
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
    vscodeServer = {
      repo = "nixos-vscode-server";
      owner = "nix-community";
      inputs.nixpkgs.follows = "nixCore";
      type = "github";
    };
    browserZen = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixCore";
        home-manager.follows = "nixHome";
      };
    };
  };
}
