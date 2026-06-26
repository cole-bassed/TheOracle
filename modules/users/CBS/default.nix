{
  users.users."CBS" = {
    description = "Cole-bassed Solutions";
    openssh.authorizedKeys.keys = ["ssh-ed25519 AAAA...REPLACE-ME cole-bassed@theoracle"];
  };
  home-manager.users."CBS" = {
    programs = {
      git = {
        userName = "cole-bassed";
        userEmail = "75517056+cole-bassed@users.noreply.github.com";
      };
      ssh = {
        enable = true;
        matchBlocks."github.com".identityFile = "~/.ssh/id_ed25519";
      };
    };
  };
}
