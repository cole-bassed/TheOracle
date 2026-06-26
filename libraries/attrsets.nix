{lib, ...}: let
  attrsets = lib.attrsets or {};
  aliases = with attrsets; {
    namesOf = attrNames;
    valuesOf = attrValues;
  };
in {attrsets = attrsets // aliases;}
