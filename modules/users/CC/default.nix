{name, ...}: {
  users.users.${name}.description = "Craig 'Craole' Cole";
  home-manager.users.${name} = {
    programs.git = {
      userName = "craole-cc";
      userEmail = "134658831+craole-cc@users.noreply.github.com";
    };
  };
}
