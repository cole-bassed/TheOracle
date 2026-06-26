{lib, ...}: let
  strings = lib.strings or {};
  inherit (builtins) hashString;
  inherit (strings) substring;

  # hexOf: Stable, truncated hex string derived from input
  hexOf = {
    length ? 8,
    salt ? "",
  }: name:
    substring 0 length (hashString "sha256" (name + salt));

  # Specialized helper for networking
  mkHostId = hexOf {length = 8;};
in {
  strings =
    strings
    // {inherit hexOf mkHostId hashString;};
}
