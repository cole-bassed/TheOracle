let
  name = "CC";
  email = "134658831+craole-cc@users.noreply.github.com";
in {
  users.users."${name}" = {
    description = "Craig 'Craole' Cole";
    openssh.authorizedKeys.keys = ["ssh-ed25519 AAAA...REPLACE-ME cc@theoracle"];
  };
  home-manager.users.${name} = {
    programs = {
      git = {
        settings.user = {
          name = "craole-cc";
          inherit email;
        };
      };
      ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings."github.com".IdentityFile = "~/.ssh/id_ed25519";
      };
    };
  };
}
