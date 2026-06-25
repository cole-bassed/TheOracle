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
  };

  outputs = {self, ...} @ inputs: let
    inherit (inputs.nixpkgs) lib;
    inherit (lib) nixosSystem;

    paths = {
      store = {
        src = ./.;
        modules = ./modules;
      };
      flake = {
        TheOracle = "/etc/nixos";
      };
    };
  in {
    nixosConfigurations = {
      TheOracle = nixosSystem {
        system = "aarch64-linux";
        specialArgs = {inherit self paths;};
        modules = with inputs; [
          {nixpkgs.overlays = [rust-overlay.overlays.default];}
          sops-nix.nixosModules.sops
          vscode-server.nixosModules.default
          paths.modules.core
        ];
      };
    };
  };
}
