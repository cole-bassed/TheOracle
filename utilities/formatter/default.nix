{
  projectRoot,
  libraries,
  packages,
  ...
}: let
  inherit (libraries.treefmt) evalModule;
  inherit (libraries.systems) forEachSystem;

  # Pass down the decoupled pkgs mapping right at the computation site
  evalFor = forEachSystem packages (
    pkgs:
      evalModule pkgs {
        # projectRootFile = "flake.nix";
        inherit projectRoot;

        programs = {
          alejandra.enable = true;
          rustfmt.enable = true;
          shfmt.enable = true;
        };

        settings.global.excludes = ["secrets/*" "*.yaml" "*.md"];
      }
  );

  formatter =
    forEachSystem
    (pkgs: (evalFor pkgs).config.build.wrapper);

  checks =
    forEachSystem
    (pkgs: {formatting = (evalFor pkgs).config.build.check projectRoot;});
  # packages =
  #   mapAttrs
  #   (system: eval: {default = eval.config.build.wrapper;})
  #   evalFor;
in {inherit formatter checks;}
