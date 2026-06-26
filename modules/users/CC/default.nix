{name, ...}: {
  users.users.${name} = {
    description = "Craig 'Craole' Cole";
    openssh.authorizedKeys.keys = ["ssh-ed25519 AAAA...REPLACE-ME cc@theoracle"];
  };
  home-manager.users.${name} = {
    programs = {
      git = {
        userName = "craole-cc";
        userEmail = "134658831+craole-cc@users.noreply.github.com";
      };
      ssh = {
        enable = true;
        matchBlocks."github.com".identityFile = "~/.ssh/id_ed25519";
      };
    };
  };
}
