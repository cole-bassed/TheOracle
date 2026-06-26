{name, ...}: {
  users.users.${name}.description = "Craig Cole";
  home-manager.users.${name} = {
    programs.git = {
      userName = "Craole";
      userEmail = "32288735+Craole@users.noreply.github.com";
    };
  };
}
