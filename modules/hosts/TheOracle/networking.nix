#?  modules/networking.nix
#?  sshd remains present and configured defensively, but is not the
#?  intended access path - see modules/firewall.nix and tailscale.nix.
#?  This is the "in case I ever need raw sshd over tailscale0" layer.
{config, ...}: {
  networking = {
    domain = "";

    #~@ No SSH on the default/public interface set. Tailscale's interface
    #~@ is added explicitly below with its own allowed list.
    firewall = {
      enable = true;
      allowedTCPPorts = [80 443];
      allowedUDPPorts = [];

      #~@ interfaces.<name> rules apply ONLY on that interface - this is
      #~@ what makes port 22 unreachable from the public NIC even if the
      #~@ OCI security list is ever accidentally widened back open.
      interfaces."tailscale0" = {
        allowedTCPPorts = [22];
        allowedUDPPorts = [];
      };

      #> trustedInterfaces would skip the firewall entirely for tailscale0 -
      #> deliberately NOT used here. Explicit allow-list above is narrower
      #> and keeps tailscale0 itself subject to firewall accounting.
      logRefusedConnections = true;

      #~@ tailscale needs to manipulate routing/firewall state at the
      #~@ kernel level - this is the standard allowance, scoped to the
      #~@ tailscale binary itself rather than broad sudo.
      checkReversePath = "loose";
    };

    nftables.enable = true;
  };

  services = {
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
      ports = [22];
    };

    tailscale = {
      enable = true;
      useRoutingFeatures = "client"; #? or "both"
      extraUpFlags = ["--ssh" "--accept-dns=false"];
      authKeyFile = config.sops.secrets."tailscale/authKey".path;
    };
  };
}
