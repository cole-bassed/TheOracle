{name, ...}: {
  users.users.${name}.description = "Cole-bassed Solutions";
  home-manager.users.${name} = {
    programs.git = {
      userName = "cole-bassed";
      userEmail = "75517056+cole-bassed@users.noreply.github.com";
    };
  };
}
