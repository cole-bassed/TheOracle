{
  nixos,
  darwin,
  ...
} @ libraries: let
  lib = nixos;
  inherit (lib.attrsets) recursiveUpdate;
in
  recursiveUpdate lib (
    {}
    // (import ./systems.nix {inherit lib;})
    // (import ./attrsets.nix {inherit lib;})
    // (import ./strings.nix {inherit lib;})
    // (recursiveUpdate {inherit nixos darwin;} libraries)
  )
