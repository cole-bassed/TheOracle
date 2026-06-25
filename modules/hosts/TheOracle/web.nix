_: {
  services = {
    nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedGzipSettings = true;

      #~@ replace with the real domain once DNS is pointed at the
      #~@ instance's public IP; left as a catch-all placeholder so
      #~@ nginx has something valid to serve immediately after deploy.
      virtualHosts = {
        "_" = {
          default = true;
          locations."/" = {
            return = "200 'TheOracle is up.'";
            extraConfig = "add_header Content-Type text/plain;";
          };
        };
        "craole.cc" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            root = "/var/www/portfolio";
          };
        };
      };
    };
  };

  security = {
    acme = {
      acceptTerms = true;
      defaults.email = "[EMAIL_ADDRESS]";
    };
  };
}
