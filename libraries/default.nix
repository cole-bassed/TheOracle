{nixpkgs, ...} @ libraries: let
  lib = nixpkgs;
  inherit (lib.attrsets) recursiveUpdate;
in
  recursiveUpdate lib (
    {}
    // (import ./systems.nix {inherit lib;})
    // (import ./attrsets.nix {inherit lib;})
    // (recursiveUpdate {inherit nixpkgs;} libraries)
  )
