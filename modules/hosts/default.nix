{
  paths,
  libraries,
  packages,
  modules,
  hosts,
  extraArgs,
}: let
  inherit (libraries.attrsets) listToAttrs mapAttrsToList optionalAttrs recursiveUpdate;
  inherit (libraries.strings) mkHostId;
  inherit (libraries.lists) groupBy;

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
    flake = paths.hosts.${name};
  in {
    inherit name class;
    value = (builders.${class} or (throw "Unknown class: ${class}")) {
      specialArgs = {inherit paths flake libraries;} // extraArgs;
      modules =
        [
          (paths'.hosts + "/${name}")
          (
            {pkgs, ...}: {
              networking = {
                hostName = name;
                hostId = cfg.id or (mkHostId name);
              };
              nixpkgs.pkgs = packages.final.${cfg.system};
              environment = {
                systemPackages = with pkgs; [
                  helix
                  nil
                  nixd
                  formatter
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
                git = {
                  enable = true;
                  config.safe.directory = flake;
                };
                nh = {
                  enable = true;
                  clean.enable = true;
                  clean.extraArgs = "--keep-since 4d --keep 3";
                  inherit flake;
                };
              };
            }
          )
        ]
        ++ (
          map
          (user: paths'.users + "/${user}")
          (cfg.users or ["Craole" "Cole-bassed"])
        )
        ++ (modules.${class} or []);
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
