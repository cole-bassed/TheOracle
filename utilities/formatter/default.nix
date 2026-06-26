{
  forEachSystem,
  mapAttrs,
  evalModule,
  projectRoot,
  packages,
}: let
  evaluated = import ./config.nix {inherit forEachSystem evalModule packages;};
  formatter = mapAttrs (_: eval: eval.config.build.wrapper) evaluated;
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
