{
  config,
  pkgs,
  flake,
  ...
}: {
  environment = {
    systemPackages = with pkgs; [
      alejandra
      bacon
      cargo-binstall
      cargo-leptos
      cargo-outdated
      curl
      fd
      gitui
      helix
      htop
      jq
      lsd
      nil
      nixd
      openssl
      pkg-config
      ripgrep
      tree
      trunk
      wasm-bindgen-cli
      watchexec
      wget
      (rust-bin.selectLatestNightlyWith (toolchain:
        toolchain.default.override {
          extensions = [
            "cargo"
            "clippy"
            "miri"
            "rust-analyzer"
            "rust-docs"
            "rust-src"
            "rustfmt"
          ];
          targets = [
            "wasm32-unknown-unknown"
            # "arm-unknown-linux-gnueabihf"
          ];
        }))
    ];
    shellAliases = {
      l = "lsd --git --group-directories-first";
      ll = "l --long --almost-all";
      lt = "l --tree";
      ld = "l --directory-only --total-size";
      ltd = "l --tree --directory-only --total-size";
      ede = "$EDITOR";
      cddots = "cd $DOTS";
      eddots = "$EDITOR $DOTS";
    };
    variables = {
      FLAKE = flake;
      DOTS = flake;
      EDITOR = "hx";
    };
  };

  programs = {
    bash = {
      enable = true;
      blesh.enable = true;
    };
    bat = {
      enable = true;
    };
    direnv = {
      enable = true;
      silent = true;
      enableBashIntegration = config.programs.base.enable;
    };
    git = {
      enable = true;
      package = pkgs.gitFull.override {withLibsecret = true;};
      lfs = {
        enable = true;
        enablePureSSHTransfer = true;
      };
      prompt.enable = true;
      config = {
        init.defaultBranch = "main";
        user = {
          name = "cole-bassed";
          email = "75517056+cole-bassed@users.noreply.github.com";
        };
        pull.rebase = true;
        push.default = "current";
        safe.directory = flake;
      };
    };
    tmux = {
      enable = true;
      shortcut = "a";
      terminal = "screen-256color";
    };
  };

  #~@ flake input `vscode-server` (nix-community/nixos-vscode-server) -
  #~@ wired in via flake.nix nixosModules.default. This is what makes
  #~@ `code --remote` / Remote-SSH actually work on first connect rather
  #~@ than failing on glibc/dynamic-linker mismatches.
  services = {
    vscode-server.enable = true;
  };
}
