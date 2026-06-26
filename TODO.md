# TODO

I'm setting up a NixOS flake config for a project called **TheOracle** — an OCI Ampere A1 (aarch64-linux) VPS currently running Ubuntu 24.04. I'm deploying from **QBX** (my local machine) via SSH.

**Current state:** The flake evaluates and the structure is complete. I need to finish the sops bootstrap and then run nixos-anywhere to install NixOS.

**Sops bootstrap — already done:**

- Grabbed the Ubuntu host's private SSH key to `/tmp/ssh_host_ed25519_key`
- Derived the age pubkey: `age14ju8288fj59hh3xw5zqx8tklpyhp23gzc8fhj9m5l46h0vwxtuuqugmxzz`
- This needs to go into `.sops.yaml` at the repo root

**What still needs doing in order:**

[] Fix the disko input URL in `flake.nix` — currently wrong (`nix-os/disko`), should be `nix-community/disko`
[] Set up `--extra-files` directory preserving the SSH host key through nixos-anywhere install
[] Run nixos-anywhere:

```bash
mkdir -p /tmp/extra-files/etc/ssh
cp /tmp/ssh_host_ed25519_key /tmp/extra-files/etc/ssh/
chmod 600 /tmp/extra-files/etc/ssh/ssh_host_ed25519_key

nix run github:nix-community/nixos-anywhere -- \
  --flake .#TheOracle \
  --target-host ubuntu@TheOracle \
  --extra-files /tmp/extra-files \
  --build-on-remote
```

**Key design decisions already made:**

- `paths.store` = nix store/repo paths; `paths.local` = host filesystem paths
- `modules/hosts/default.nix` is the host builder (parallel to `modules/users/default.nix` for users)
- sops `defaultSopsFile` and `age.keyFile` are declared in the common host builder, not per-host
- Users builder handles `mutableUsers`, `isNormalUser`, `extraGroups`, sops password wiring, home-manager setup, sudo rules
- Per-user `default.nix` only has what's unique: description, SSH authorized keys, git identity, home config
- `disko` handles disk layout; `systemd-boot` for EFI (confirmed from `lsblk` — sda15 is EFI)
- `--build-on-remote` because cross-compiling aarch64 from x86_64 is slow
- SSH restricted to `tailscale0` interface only — Tailscale authKey via sops is critical to avoid lockout
- SSH host key preserved through install via `--extra-files` so sops age key stays valid on first boot

**Known remaining issues in the flake:**

- `development.nix` still has some overlap with the common builder (git config with hardcoded user, duplicate env vars) — clean up after deploy
- `secrets/default.nix` was renamed to `modules/hosts/TheOracle/secrets.nix` but verify it's in the imports in `TheOracle/default.nix`
- `libraries.modules.mkDefault` is inherited in the hosts builder — verify `modules` namespace is exported from `libraries/default.nix`

**Disk layout confirmed from lsblk:**

```
sda       100G
├─sda1     99G   /
├─sda15    99M   /boot/efi
└─sda16   923M   /boot
```

**TheOracle SSH info:**

- Hostname resolves via SSH config (not DNS) from QBX
- Ubuntu user: `ubuntu@TheOracle`
- Host ed25519 pubkey: `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC6un8SelpbLSx/28q7kv7Jq1GKGTd8aG8tGJbLaGn6K`
- Derived age pubkey: `age14ju8288fj59hh3xw5zqx8tklpyhp23gzc8fhj9m5l46h0vwxtuuqugmxzz`
