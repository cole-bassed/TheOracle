{
  users.users.cole-bassed = {
    isNormalUser = true;
    description = "Cole-bassed Solutions";
    extraGroups = ["wheel" "networkmanager"];

    #~@ Replace with the actual public key before first deploy -
    #~@ this is the only auth path into sshd once password auth
    #~@ is disabled. Tailscale ssh is the independent fallback.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAA...REPLACE-ME cole-bassed@theoracle"
    ];

    #> hashedPasswordFile can be wired through sops-nix later if a
    #> local console password is ever wanted; left unset deliberately
    #> for now since mutableUsers = false requires explicit handling.
    hashedPassword = null;
  };
}
