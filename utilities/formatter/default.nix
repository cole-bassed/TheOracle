{
  projectRoot,
  lib,
  packages,
  ...
}: let
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.treefmt) evalModule;
  inherit (lib.systems) forEachSystem;

  # Pass down the decoupled pkgs mapping right at the computation site
  evaluated = forEachSystem packages (
    pkgs:
      evalModule pkgs {
        inherit projectRoot;

        programs = {
          alejandra.enable = true;
          rustfmt.enable = true;
          shfmt.enable = true;
        };

        settings.global.excludes = ["secrets/*" "*.yaml" "*.md"];
      }
  );
in {
  packages =
    mapAttrs (system: eval: {
      default = eval.config.build.wrapper;
    })
    evaluated;

  formatter = mapAttrs (system: eval: eval.config.build.wrapper) evaluated;

  checks =
    mapAttrs (system: eval: {
      formatting = eval.config.build.check projectRoot;
    })
    evaluated;
}
