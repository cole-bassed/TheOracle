{
  imports = [./craole ./cole-bassed];
  users = {
    mutableUsers = false;
  };

  security.sudo = {
    enable = true;
    extraRules = [
      {
        users = ["craole" "cole-bassed"];
        commands = [
          {
            command = "ALL";
            options = ["SETENV" "NOPASSWD"];
          }
        ];
      }
    ];
  };
}
