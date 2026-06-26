let
  name = "Craole";
  email = "32288735+${name}@users.noreply.github.com";
in {
  users.users.${name} = {
    description = "Craig Cole";
    openssh.authorizedKeys.keys = ["ssh-ed25519 AAAA...REPLACE-ME"];
  };
  home-manager.users.${name} = {
    programs = {
      git.settings.user = {inherit name email;};
      ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings."github.com".IdentityFile = "~/.ssh/id_ed25519";
      };
    };
  };
}
