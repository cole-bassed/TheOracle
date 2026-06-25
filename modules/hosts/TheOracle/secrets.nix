#?  modules/secrets.nix
#?  sops-nix scaffolding. Inert until:
#?    1. an age key exists at sops.age.keyFile's path on the host
#?    2. secrets/secrets.yaml exists, encrypted against that key
#?    3. entries are added to sops.secrets below
#?
#?  Deliberately left disconnected from any consumer module for now -
#?  nothing currently depends on a secret existing, so this can sit
#?  inert without breaking evaluation.
_: {
  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";

    #~@ populate once the first secret (e.g. an API token for a future
    #~@ service) actually exists:
    #~@
    #~@   sops.secrets."example-token" = {
    #~@     owner = "cole-bassed";
    #~@   };
    secrets = {};
  };
}
