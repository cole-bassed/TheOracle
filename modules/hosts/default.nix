{
  paths,
  libraries,
  packages,
  modules,
  hosts,
  extraArgs,
}: let
  inherit (libraries.attrsets) listToAttrs mapAttrsToList optionalAttrs recursiveUpdate;
  inherit (libraries.lists) groupBy;
  inherit (libraries.modules) mkDefault;
  inherit (libraries.strings) mkHostId;

  paths' = let
    resolved =
      recursiveUpdate {
        store = {
          hosts = ./.;
          users = ../users;
        };
      }
      paths;
  in {inherit (resolved.store) hosts users;};

  builders = {
    nixos = libraries.nixos.nixosSystem;
    darwin = libraries.darwin.darwinSystem;
  };

  build = name: cfg: let
    class = cfg.class or "nixos";
    flake = paths.local.hosts.${name};
  in {
    inherit name class;
    value = (builders.${class} or (throw "Unknown class: ${class}")) {
      specialArgs = {inherit paths flake libraries;} // extraArgs;
      modules =
        [
          (paths'.hosts + "/${name}")
          ({pkgs, ...}: {
            networking = {
              hostName = name;
              hostId = cfg.id or (mkHostId name);
            };
            nixpkgs.pkgs = packages.final.${cfg.system};
            sops = {
              inherit (paths) defaultSopsFile;
              age = {inherit (paths.local.age) keyFile;};
              secrets = {};
            };
            time.timeZone = mkDefault "America/Jamaica";
            i18n.defaultLocale = mkDefault "en_US.UTF-8";
            environment = {
              systemPackages = with pkgs; [
                formatter
                helix
                nil
                nixd
                sops
                ssh-to-age
              ];
              shellAliases = {
                cddots = "cd $DOTS";
                eddots = "$EDITOR $DOTS";
              };
              variables = {
                EDITOR = "hx";
                FLAKE = flake;
                DOTS = flake;
              };
            };
            programs = {
              bash = {
                enable = true;
                blesh.enable = true;
              };
              bat.enable = true;
              htop.enable = true;
              direnv = {
                enable = true;
                silent = true;
                enableBashIntegration = true;
              };
              git = {
                enable = true;
                config = {
                  init.defaultBranch = "main";
                  pull.rebase = true;
                  push.default = "current";
                  safe.directory = flake;
                };
              };
              nh = {
                enable = true;
                clean.enable = true;
                clean.extraArgs = "--keep-since 4d --keep 3";
                inherit flake;
              };
            };
          })
          (import paths'.users {
            inherit paths libraries;
            users =
              cfg.users or {
                Craole = {};
                "Cole-bassed" = {};
              };
          })
        ]
        ++ (modules.${class} or []);
    };
  };

  built = groupBy (host: host.class) (mapAttrsToList build hosts);
in
  (optionalAttrs
    (built ? nixos)
    {nixosConfigurations = listToAttrs built.nixos;})
  // (optionalAttrs
    (built ? darwin)
    {darwinConfigurations = listToAttrs built.darwin;})
