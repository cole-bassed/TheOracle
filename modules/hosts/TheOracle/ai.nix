_: {
  users = {
    groups = {
      hermes = {};
      openclaw = {};
    };
    users = {
      hermes = {
        isSystemUser = true;
        group = "hermes";
        description = "Hermes agent";
      };
      openclaw = {
        isSystemUser = true;
        group = "openclaw";
        description = "OpenClaw agent";
      };
    };
  };
}
