{
  forEachSystem,
  mapAttrs,
  evalModule,
  projectRoot,
  packages,
}: let
  evaluated = import ./config.nix {inherit forEachSystem evalModule packages;};
  # evaluated = forEachSystem {
  #   inherit packages;
  #   fn = pkgs:
  #     evalModule pkgs {
  #       projectRootFile = "flake.nix";
  #       # Global exclusions (generated files, secrets, lock files)
  #       settings.excludes = [
  #         "flake.lock"
  #         "secrets/secrets.yaml"
  #         ".sops.yaml"
  #         "secrets/ssh/**"
  #         "*.min.js"
  #         "*.min.css"
  #         "node_modules/*"
  #         "target/*"
  #         "result*"
  #         ".direnv/*"
  #       ];
  #       programs = {
  #         #~@ Nix
  #         alejandra.enable = true;
  #         statix.enable = true;
  #         deadnix.enable = true;
  #         #~@ Shellscript
  #         shfmt.enable = true;
  #         shellcheck.enable = true;
  #         #~@ Rust
  #         rustfmt.enable = true;
  #         leptosfmt.enable = true;
  #         #~@ Web / Frontend
  #         biome.enable = true;
  #         prettier.enable = true;
  #         #~@ Data
  #         taplo.enable = true; #? TOML
  #         yamlfmt.enable = true; #? YAML
  #         jsonfmt.enable = true; #? JSON
  #         sql-formatter = {
  #           enable = true;
  #           dialect = "sqlite";
  #         };
  #         # Documentation
  #         mdformat = {
  #           enable = true;
  #           plugins = ps:
  #             with ps; [
  #               mdformat-gfm
  #               mdformat-footnote
  #             ];
  #         };
  #         typstyle = {
  #           enable = true;
  #           lineWidth = 100;
  #           wrapText = true;
  #         };
  #         # GitHub Actions (if you add workflows later)
  #         actionlint.enable = true;
  #         # Images (lossless PNG optimization for web assets)
  #         oxipng.enable = true;
  #       };
  #     };
  # };
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
