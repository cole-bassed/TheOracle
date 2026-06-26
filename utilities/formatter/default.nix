{
  forEachSystem,
  mapAttrs,
  evalModule,
  projectRoot,
  packages,
}: let
  evalFor = pkgs:
    evalModule pkgs {
      projectRootFile = "flake.nix";
      programs = {
        alejandra.enable = true;
        statix.enable = true;
      };
    };

  evaluated = forEachSystem {
    inherit packages;
    fn = evalFor;
  };

  formatter =
    mapAttrs
    (_: eval: eval.config.build.wrapper)
    evaluated;
in {
  inherit formatter;
  checks =
    mapAttrs
    (_: eval: {formatting = eval.config.build.check projectRoot;})
    evaluated;

  packages =
    mapAttrs
    (system: pkgs: pkgs // {formatter = formatter.${system};})
    packages;
}
