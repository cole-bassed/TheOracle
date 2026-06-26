{
  users,
  paths,
  libraries,
  modules ? [],
}: let
  inherit (libraries.attrsets) namesOf mapAttrsToList;

  build = name: _cfg: ({config, ...}: {
    sops.secrets."users/${name}/password".neededForUsers = true;
    users.users.${name} = {
      isNormalUser = true;
      extraGroups = ["wheel" "networkmanager"];
      hashedPasswordFile = config.sops.secrets."users/${name}/password".path;
    };
    home-manager.users.${name}._module.args.name = name;
  });
in {
  imports =
    (map (name: paths.users + "/${name}") (namesOf users))
    ++ (mapAttrsToList build users);

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
