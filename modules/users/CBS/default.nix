let
  name = "CBS";
  email = "75517056+cole-bassed@users.noreply.github.com";
in {
  users.users.${name} = {
    description = "Cole-bassed Solutions";
    openssh.authorizedKeys.keys = ["ssh-ed25519 AAAA...REPLACE-ME cole-bassed@theoracle"];
  };
  home-manager.users.${name} = {
    programs = {
      git = {
        settings.user = {
          inherit email;
          name = "cole-bassed";
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
