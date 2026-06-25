{paths, ...}: {
  projectRoot = paths.store.src;

  programs = {
    alejandra.enable = true;
    rustfmt.enable = true;
    shfmt.enable = true;
  };

  settings.global.excludes = ["secrets/*" "*.yaml" "*.md"];
}
