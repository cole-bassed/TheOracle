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

    sops.secrets."users/${name}/password".neededForUsers = true;
    users.users.${name} = {
      isNormalUser = true;
      extraGroups = ["wheel" "networkmanager"];
      hashedPasswordFile = config.sops.secrets."users/${name}/password".path;
    };
  });
in {
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
