{name, ...}: {
  users.users.${name} = {
    description = "Craig Cole";
    openssh.authorizedKeys.keys = ["ssh-ed25519 AAAA...REPLACE-ME"];
  };
  home-manager.users.${name} = {
    programs = {
      git = {
        userName = "Craole";
        userEmail = "32288735+Craole@users.noreply.github.com";
      };
      ssh = {
        enable = true;
        matchBlocks."github.com" = {
          identityFile = "~/.ssh/id_ed25519";
        };
      };
    };
  };
}
