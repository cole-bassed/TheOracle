{
  users,
  paths,
  libraries,
  modules ? [],
}: let
  inherit (libraries.attrsets) namesOf mapAttrsToList recursiveUpdate;

  paths' = let
    resolved =
      recursiveUpdate {
        store = {
          hosts = ../hosts;
          users = ./.;
        };
      }
      paths;
  in {inherit (resolved.store) hosts users;};

  build = name: _cfg: ({config, ...}: {
    imports = [(paths'.users + "/${name}")];
    _module.args.name = name;

    sops.secrets."users/${name}/password".neededForUsers = true;
    users.users.${name} = {
      isNormalUser = true;
      extraGroups = ["wheel" "networkmanager"];
      hashedPasswordFile = config.sops.secrets."users/${name}/password".path;
    };
    home-manager.users.${name}._module.args.name = name;
  });
in {
  # imports =
  #   (map (name: paths'.users + "/${name}") (namesOf users))
  #   ++ (mapAttrsToList build users);
  imports = mapAttrsToList build users;

  users.mutableUsers = false;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    sharedModules =
      [
        ({osConfig, ...}: {
          home = {inherit (osConfig.system) stateVersion;};
          programs.home-manager.enable = true;
        })
      ]
      ++ modules;
  };

  security.sudo = {
    enable = true;
    extraRules = [
      {
        users = namesOf users;
        commands = [
          {
            command = "ALL";
            options = ["SETENV" "NOPASSWD"];
          }
        ];
      }
    ];
  };
}
