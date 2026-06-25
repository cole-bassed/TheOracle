{pkgs, ...}: {
  #╔══════════════════════════════════════════╗
  #║ Boot                                     ║
  #╚══════════════════════════════════════════╝

  #> Console: OCI's browser-based serial console is the lockout escape
  #> hatch independent of network/SSH state. Make sure output actually
  #> reaches it.
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = ["console=ttyS0,115200n8"];

    #~@ nixos-infect leaves a GRUB setup targeting the Ubuntu-provisioned
    #~@ disk layout (no separate /boot/efi on most OCI A1 images - BIOS/GRUB,
    #~@ not systemd-boot). Confirm against the actual partition table after
    #~@ infect before first rebuild; adjust device below if different.
    loader.grub = {
      enable = true;
      device = "/dev/sda";
      efiSupport = false;
      extraConfig = ''
        serial --port=0x3f8 --speed=115200
        terminal_input serial console
        terminal_output serial console
      '';
    };
  };

  #╔══════════════════════════════════════════╗
  #║ Filesystems                              ║
  #╚══════════════════════════════════════════╝

  #~@ nixos-infect inherits the Ubuntu cloud-image partition layout.
  #~@ Verify UUIDs with `lsblk -f` after infect and correct if needed -
  #~@ these are placeholders until confirmed against the live system.
  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };

  #╔══════════════════════════════════════════╗
  #║ Swap                                     ║
  #╚══════════════════════════════════════════╝

  #~@ 12GB RAM total on the free-tier shape. Rust/cargo link steps on
  #~@ larger dependency trees can spike well past available RAM under
  #~@ parallel codegen units; swap is the cushion, not a performance fix.
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 8192; #> MB
    }
  ];

  #~@ Swap on a server doing intermittent bursty work (builds) rather
  #~@ than constant memory pressure: keep swappiness low so the kernel
  #~@ prefers RAM and only reaches for swap under real pressure.
  boot.kernel.sysctl."vm.swappiness" = 10;

  #╔══════════════════════════════════════════╗
  #║ Platform                                 ║
  #╚══════════════════════════════════════════╝

  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = "25.11";
}
