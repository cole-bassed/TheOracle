{config, ...}: let
  userName = "Craole";
  email = "32288735+Craole@users.noreply.github.com";
  home = "/home/${userName}";
in {
  users.users.${userName} = {
    description = "Craig Cole";
    openssh.authorizedKeys.keyFiles = [
      config.sops.secrets."ssh/authorized_keys/${userName}".path
    ];
  };

  sops.secrets = {
    "ssh/authorized_keys/${userName}" = {
      path = "${home}/.ssh/authorized_keys/${userName}.pub";
    };
    "ssh/github/Craole" = {
      path = "${home}/.ssh/github/Craole";
      owner = userName;
      mode = "0600";
    };
    "ssh/github/cole-bassed" = {
      path = "${home}/.ssh/github/cole-bassed";
      owner = userName;
      mode = "0600";
    };
    "ssh/github/craole-cc" = {
      path = "${home}/.ssh/github/craole-cc";
      owner = userName;
      mode = "0600";
    };
  };

  home-manager.users.${userName} = {config, ...}: let
    HOME = config.home.homeDirectory;
    PROJECTS = HOME + "/Projects";
    PRJ_CBS = PROJECTS + "/CBS";
    PRJ_CC = PROJECTS + "/CC";
    PRJ_Craole = PROJECTS + "/Craole";
  in {
    home = {
      sessionVariables = {
        inherit PROJECTS PRJ_Craole PRJ_CBS PRJ_CC;
      };
      shellAliases = {
        prj = "cd ${PROJECTS}";
        prjc = "cd ${PRJ_Craole}";
        prjcbs = "cd ${PRJ_CBS}";
        prjcc = "cd ${PRJ_CC}";
      };
    };

    programs = {
      git = {
        enable = true;
        settings.user = {
          name = userName;
          inherit email;
        };
        includes = [
          {
            condition = "gitdir:${PRJ_Craole}/";
            contents.user = {
              name = userName;
              inherit email;
            };
          }
          {
            condition = "gitdir:${PRJ_CC}/";
            contents.user = {
              name = "craole-cc";
              email = "134658831+craole-cc@users.noreply.github.com";
            };
          }
          {
            condition = "gitdir:${PRJ_CBS}/";
            contents.user = {
              name = "cole-bassed";
              email = "75517056+cole-bassed@users.noreply.github.com";
            };
          }
        ];
      };

      gh = {
        enable = true;
        settings = {
          git_protocol = "ssh";
          editor = "hx";
          aliases = {
            co = "pr checkout";
            pv = "pr view";
          };
        };
      };

      ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings.matchBlocks = {
          "github.com" = {
            identityFile = "${HOME}/.ssh/github/Craole";
          };
          "github.com-cole-bassed" = {
            hostname = "github.com";
            identityFile = "${HOME}/.ssh/github/cole-bassed";
            user = "git";
          };
          "github.com-craole-cc" = {
            hostname = "github.com";
            identityFile = "${HOME}/.ssh/github/craole-cc";
            user = "git";
          };
        };
      };
    };
  };
}
