{lib}: let
  exports = {
    scoped =
      {
        inherit get per supported mkPackages;
        forEach = per;
      }
      // aliases;
    global = aliases;
  };
  inherit (lib.attrsets) genAttrs;
  inherit (lib.lists) elem uniqueStrings;
  inherit (lib.trivial) isFunction;

  aliases = {
    supportedSystems = supported;
    getSystem = get;
    forEachSystem = per;
    perSystem = per;
    mkSystemPackages = mkPackages;
  };

  supported = let
    systems = ["aarch64-linux" "x86_64-linux" "aarch64-darwin"];
  in
    {extra ? []}: uniqueStrings (systems ++ extra);

  /**
  Determine if a given architecture string matches any of the systems defined
  in the supported core array configuration.

  # Type
  ```nix
  get :: String -> Bool
  ```

  # Arguments
  sys
  : The target system string context to evaluate (e.g., "aarch64-linux").

  # Examples
  > getSystem "aarch64-linux"
  => true

  > getSystem "i686-linux"
  # => false
  */
  get = system: elem system (supported {});

  /**
  Simple system string iterator for building, checking, or compiling infrastructure
  attributes natively across every defined core architecture context.

  # Type
  ```nix
  per :: (String -> AttrSet) -> AttrsOf AttrSet
  ```

  # Arguments
  fn
  : Callback evaluation function accepting the specific current target system string.

  # Examples
  > perSystem (system: { format = "raw"; })
  # => { aarch64-linux = { format = "raw"; }; x86_64-linux = { format = "raw"; }; }
  */
  per = arg: let
    opts =
      if isFunction arg
      then {fn = arg;}
      else arg;
    packages = opts.packages or {};
    extra = opts.extra or [];
  in
    genAttrs
    (supported {inherit extra;})
    (system: opts.fn packages.${system});

  /**
  Instantiate an unfree-enabled package set across all target architectures,
  automatically handling system mapping, unfree predicates, and global overlays.

  # Type
  ```nix
  mkPackages :: {
    nixpkgs  :: FlakeInput,
    inputs   :: FlakeInputs,
    overlays ? :: [Overlay]
  } -> AttrsOf PackageSet
  ```

  # Arguments
  nixpkgs
  : The core nixpkgs flake input source string or reference.

  inputs
  : The full inputs attribute set passed from the flake output header.

  overlays
  : Optional collection of package overrides/extensions to bake into every platform layer.

  # Examples
  > mkPackages { inherit nixpkgs inputs; overlays = [ rust-overlay.overlays.default ]; }
  => { aarch64-linux = <packageSet>; x86_64-linux = <packageSet>; ... }
  */
  mkPackages = {
    nixpkgs,
    overlays ? [],
    config ? {allowUnfree = true;},
    systems ? (supported {}),
  }:
    genAttrs
    systems
    (system: import nixpkgs {inherit system overlays config;});
in
  exports.global // {systems = exports.scoped;}
