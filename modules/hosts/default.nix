{
  paths,
  libraries,
  packages,
  modules,
  hosts,
  extraArgs,
}: let
  inherit (libraries.attrsets) listToAttrs mapAttrsToList optionalAttrs recursiveUpdate;
  inherit (libraries.lists) groupBy optionals;
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
    profile = cfg.profile or "server";
    flake = paths.local.hosts.${name};

    modules' = {
      core =
        (modules.core.${class}.base or [])
        ++ (
          optionals
          (profile == "desktop")
          (modules.core.${class}.desktop or [])
        );
      home =
        (modules.home.base or [])
        ++ (
          optionals
          (profile == "desktop")
          (modules.home.desktop or [])
        );
    };
    # nixosModules = coreBase ++ libraries.optionals (profile == "desktop") coreDesktop;
    # homeModules = homeBase ++ libraries.optionals (profile == "desktop") homeDesktop;
  in {
    inherit name class;
    value = (builders.${class} or (throw "Unknown class: ${class}")) {
      specialArgs = {inherit paths flake libraries;} // extraArgs;
      modules =
        modules'.core
        ++ [
          (paths'.hosts + "/${name}")
          ({pkgs, ...}: {
            networking = {
              hostName = name;
              hostId = cfg.id or (mkHostId name);
            };
            nixpkgs.pkgs = packages.final.${cfg.system};
            sops = {
              inherit (paths.store) defaultSopsFile;
              inherit (paths.local) age;
              secrets = {};
            };
            time.timeZone = mkDefault "America/Jamaica";
            i18n.defaultLocale = mkDefault "en_US.UTF-8";
            environment = {
              systemPackages = with pkgs; [
                curl
                fd
                formatter
                helix
                jq
                lsd
                mkpasswd
                nil
                nixd
                sd
                sops
                ssh-to-age
                yq
                age
              ];
              shellAliases = {
                l = "lsd --git --group-directories-first";
                ll = "l --long --almost-all";
                lt = "l --tree";
                ld = "l --directory-only --total-size";
                ltd = "l --tree --directory-only --total-size";
                cddots = "cd $DOTS";
                eddots = "$EDITOR $DOTS";
                prj = "cd ~/Projects";
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
                  safe.directory = [flake "/etc/nixos"];
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
            modules = modules'.home;
            users =
              cfg.users or {Craole = {};};
          })
        ];
    };
  };

  built = groupBy (host: host.class) (mapAttrsToList build hosts);
in
  (
    optionalAttrs
    (built ? nixos)
    {nixosConfigurations = listToAttrs built.nixos;}
  )
  // (
    optionalAttrs
    (built ? darwin)
    {darwinConfigurations = listToAttrs built.darwin;}
  )
