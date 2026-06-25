# TheOracle — Deployment Runbook

Read this whole thing once before starting. The order matters — several
steps here exist specifically to avoid repeating yesterday's lockout.

---

## 0. Before touching the console: generate an SSH key (on your laptop)

```sh
ssh-keygen -t ed25519 -C "cole-bassed@theoracle" -f ~/.ssh/theoracle
```

Copy the contents of `~/.ssh/theoracle.pub` — you'll need it in step 2 and
again in `modules/users.nix`.

---

## 1. Create the instance in the OCI console

Use the **same VCN** (`TheOracle-VCN`) and security list you already have —
don't recreate it, just edit the rules (step 3).

- **Create compute instance**
- Name: `TheOracle`
- Shape: `VM.Standard.A1.Flex`
  - **OCPU: 2** — not 4. Oracle cut the Always Free Ampere A1 allowance from
    4 OCPU/24GB down to 2 OCPU/12GB in mid-June 2026. Your account is pure
    Always Free, so 4/24 risks the instance being throttled or reclaimed.
  - **Memory: 12 GB**
- Image: **Canonical Ubuntu 24.04** (this is just the infect launchpad —
  you will not be running Ubuntu when this is done)
- Boot volume: bump from the 50GB default to **100GB** (custom boot volume
  size) — you have 200GB total free block storage, this leaves headroom
- SSH keys: paste the **public** key from step 0
- **Before clicking Create**, expand **Security → enable the option for
  legacy MD/instance metadata if prompted** — not required, skip if absent
- Networking: select existing `TheOracle-VCN`, existing public subnet,
  assign a public IPv4 address: yes

Click **Create**. Wait for `RUNNING`.

### Enable the serial console NOW, while you still have working SSH

This is the step that would have saved you yesterday. Do it immediately
after the instance is running, before you touch any SSH/firewall config:

- Instance page → **Console connection** (left sidebar) → **Create console
  connection**
- Paste the same SSH public key
- Wait for it to become `ACTIVE` (~1-2 min)
- **Test it now**: click **Copy SSH command for Windows/Linux** or use the
  in-browser console launcher, confirm you actually get a login prompt
  *before* proceeding. If this doesn't work now, fix it now — it's much
  harder to debug later with no other access path.

---

## 2. Confirm plain SSH works once, the normal way

```sh
ssh -i ~/.ssh/theoracle ubuntu@<PUBLIC_IP>
```

Don't change anything yet. Just confirm you're in.

---

## 3. Update the OCI Security List (TheOracle-VCN → Default Security List)

In the console, on the security list you already have:

**Remove:**
- Ingress: `0.0.0.0/0`, TCP, port 22
- Ingress: `::/0`, TCP, port 22
- Ingress: `0.0.0.0/0`, TCP, port 41641 (if present — leftover from
  yesterday's port-shuffle advice, not needed for Tailscale which uses UDP)

**Add:**
- Ingress: `100.64.0.0/10`, TCP, port 22, source type CIDR — restricts the
  *cloud firewall* to only ever consider SSH from Tailscale's CGNAT range.
  (The NixOS firewall is the layer that actually enforces this — this is
  belt-and-suspenders.)

**Keep as-is:** the ICMP rules, the UDP 41641 Tailscale rule you already
set, ports 80/443.

---

## 4. Run nixos-infect

Still SSH'd in as `ubuntu`:

```sh
sudo su -
curl https://raw.githubusercontent.com/elitak/nixos-infect/master/nixos-infect | NIX_CHANNEL=nixos-25.11 bash -x
```

This takes several minutes and **reboots the box into NixOS** at the end.
The Ubuntu SSH session will die — that's expected, not a lockout.

Wait ~2 minutes, then:

```sh
ssh -i ~/.ssh/theoracle root@<PUBLIC_IP>
```

You should land on a bare NixOS system. From here on, everything is
declarative — this is the last time you'll touch this box outside of
editing your flake and running `nixos-rebuild`.

---

## 5. Get your actual disk layout before trusting the placeholder config

```sh
lsblk -f
cat /etc/nixos/hardware-configuration.nix
```

Compare against `hosts/theoracle/configuration.nix` in this repo — the
`fileSystems."/"` device path and the GRUB device are written as
placeholders (`/dev/sda1` / `/dev/sda`) based on typical OCI A1 + infect
layouts, but **must be confirmed against the real output above** before
first rebuild. If `nixos-infect` generated a `hardware-configuration.nix`
with different values, prefer those — copy them in rather than trusting
the placeholder.

---

## 6. Get the flake onto the box and fill in the placeholders

Copy this whole `oracle-nixos/` directory to the server (`scp -r` or `git
clone` your own fork of it once you've pushed it somewhere), then edit:

1. `modules/users.nix` — replace `ssh-ed25519 AAAA...REPLACE-ME` with your
   actual public key, and fill in a real git email
2. `hosts/theoracle/configuration.nix` — confirm/correct the filesystem and
   GRUB device paths against step 5's output
3. `modules/identity.nix` — adjust `time.timeZone` if `America/Jamaica`
   isn't right

---

## 7. First rebuild

```sh
cd /path/to/oracle-nixos
sudo nixos-rebuild switch --flake .#theoracle
```

This will enable Tailscale, the nftables firewall, sshd hardening, and
everything else in one shot. **Don't disconnect your current root SSH
session yet.**

---

## 8. Bring up Tailscale and verify BEFORE closing anything

```sh
sudo tailscale up --ssh
tailscale status
```

From your laptop, confirm you can reach the box over Tailscale:

```sh
tailscale ssh cole-bassed@theoracle
```

**Only once this works**, go back and confirm regular SSH on the public IP
now fails (it should — the NixOS firewall only allows port 22 on
`tailscale0`):

```sh
ssh -i ~/.ssh/theoracle root@<PUBLIC_IP>   # should now time out / refuse
```

If Tailscale SSH works, you're done — you now have three independent paths
to this box (Tailscale SSH, Tailscale-routed sshd, serial console), and
zero public exposure on port 22.

---

## 9. VS Code Remote-SSH

On your laptop's `~/.ssh/config`:

```
Host theoracle
  HostName theoracle           # tailscale machine name, via MagicDNS
  User cole-bassed
  IdentityFile ~/.ssh/theoracle
```

Then in VS Code: Remote-SSH → Connect to Host → `theoracle`. The
`vscode-server` NixOS module handles the glibc/dynamic-linker mismatch
that normally breaks this on NixOS, so it should connect cleanly on first
try.

---

## Rough free-tier budget check

| Resource | Used | Free allowance |
|---|---|---|
| A1 OCPU | 2 | 2 (new limit) |
| A1 memory | 12 GB | 12 GB (new limit) |
| Boot volume | 100 GB | 200 GB total block storage |
| Outbound bandwidth | low (personal site + dev work) | 10 TB/month |

You're at the new cap on OCPU/memory but well under on storage and
bandwidth. As long as you don't spin up a second A1 instance alongside
this one, you stay at $0.
