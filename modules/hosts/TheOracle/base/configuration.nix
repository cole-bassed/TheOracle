{pkgs, ...}: {
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = ["console=ttyS0,115200n8"];
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernel.sysctl."vm.swappiness" = 10;
  };

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 8192;
    }
  ];

  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = "25.11";
}
