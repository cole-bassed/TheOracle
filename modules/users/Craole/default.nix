{
  users.users."Craole" = {
    description = "Craig Cole";
    openssh.authorizedKeys.keys = ["ssh-ed25519 AAAA...REPLACE-ME"];
  };
  home-manager.users."Craole" = {
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
