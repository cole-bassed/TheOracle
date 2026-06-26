{nixpkgs, ...} @ libraries: let
  inherit (nixpkgs.attrsets) recursiveUpdate;
  lib = nixpkgs;
  lix =
    (import ./systems.nix {inherit lib;})
    // (import ./attrsets.nix {inherit lib;});
in
  recursiveUpdate
  (recursiveUpdate lib lix)
  (recursiveUpdate libraries {inherit nixpkgs lix;})
