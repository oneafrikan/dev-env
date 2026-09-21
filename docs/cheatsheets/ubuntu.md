# Ubuntu cheatsheet (server and desktop)

Back-pocket reference for running an Ubuntu machine effectively and safely.
Opinionated, terse, copy-pasteable.

**Written against** (2026-09-21, from Ubuntu's release pages and notes):

| Release | Status |
|---|---|
| **26.04 LTS "Resolute Raccoon"** | Current LTS. Released 2026-04-23; 26.04.1 out August 2026; standard support to April 2031. |
| 24.04 LTS "Noble Numbat" | Supported LTS. Upgrade path to 26.04 opens after 26.04.1 (offer rolled out in stages). |
| 22.04 LTS "Jammy Jellyfish" | Supported LTS (older). |
| 26.10 "Stonking Stingray" | In development, not released. There is no current interim release; 25.10 is archived. |

Commands target 26.04 (apt 3.x, systemd 259, OpenSSH 10.2, kernel 7.0) and work
on 24.04 unless flagged. Interim releases get 9 months of support: use LTS for anything that matters.

| Mark | Meaning |
|---|---|
| `⚠` | Destructive or hard to undo. The safe variant (list / dry-run) comes first. |
| `sudo` | Shown explicitly; a bare command needs no privilege. |
| `[docs]` | From official documentation or Ubuntu manpages I read. **None of these commands were run on Ubuntu**; the author's reference machine is Arch. |
| `[verified: arch-local]` | Ran on an Arch machine. Only used here for cross-distro tools (systemd, ssh). |
| `[unverified]` | Believed correct, could not confirm from a doc. Check first. |

Every code block starts with a tag comment.

---

## 1. First 15 minutes on a fresh install

```bash
# [docs] update fully; phased updates can hide packages, so include them for a first full update
sudo apt update && sudo apt full-upgrade -o APT::Get::Always-Include-Phased-Updates=true
ls /run/reboot-required 2>/dev/null && echo "reboot needed"
```

```bash
# [docs: OpenSSH page for the last two lines] [unverified: adduser/usermod are standard Debian tools, not fetched]
sudo adduser <user> && sudo usermod -aG sudo <user>
sudo apt install openssh-server
ssh-copy-id <user>@<host>                     # from the client, then harden (section 5)
```

```bash
# [docs: ufw page] allow SSH BEFORE enabling. [unverified: exact name of the OpenSSH ufw profile; run `sudo ufw app list`]
sudo ufw allow OpenSSH && sudo ufw enable
timedatectl; chronyc tracking                 # 26.04 installs chrony; older installs may still run systemd-timesyncd
sudo hostnamectl set-hostname <name>          # cloud images: see cloud-init in section 13
```

```bash
# [docs] essentials + unattended security updates (on by default on server; verify)
sudo apt install build-essential git curl unattended-upgrades needrestart
sudo pro status                               # attach a free Ubuntu Pro token for ESM + Livepatch, section 8
```

Then: backups (section 12), `snap list` to see what is snap-managed, and decide desktop vs headless (section 13).

## 2. Packages

| Tool | Use it for |
|---|---|
| `apt` | Interactive use (progress bar, friendly). **Not a stable CLI for scripts** (it prints a warning). |
| `apt-get` / `apt-cache` | Scripts and CI (stable output). |
| `dpkg` | Low level: query installed files, install a local `.deb`. No dependency resolution. |
| `aptitude` | Optional (`apt install aptitude`); better solver output when apt is stuck. |

```bash
# [docs] query (manpages.ubuntu.com: apt(8), dpkg(1))
apt search <term>; apt show <pkg>; apt policy <pkg>      # candidate/installed versions, which repo
apt list --installed; apt list --upgradable
apt list -a <pkg>                                        # all available versions
dpkg -S /path/to/file                                    # which package owns this file
dpkg -L <pkg>; dpkg -l | grep <pkg>; dpkg -V <pkg>      # files / status / verify against db
apt why <pkg>                                            # why is it installed (apt 3.x); apt why-not
apt-mark showmanual                                      # what you asked for (vs pulled in as deps)
```

```bash
# [docs] change
sudo apt install <pkg>                       # sudo apt install <pkg>=<version> pins a version
sudo apt remove <pkg>                        # keeps config
sudo apt purge <pkg>                         # ⚠ removes config too
sudo apt update && sudo apt upgrade          # never removes packages
sudo apt full-upgrade                        # may remove/add packages (needed when "kept back")
sudo apt reinstall <pkg>
```

**Autoremove / cleanup**: `sudo apt autoremove --purge` `[docs]` (list first: `apt -s autoremove`, `-s` = simulate),
`sudo apt clean` (empties `/var/cache/apt/archives`), `sudo apt autoclean` (only obsolete `.deb`s).

**Hold and downgrade** `[docs]`:

```bash
# [docs]
sudo apt-mark hold <pkg>; apt-mark showhold; sudo apt-mark unhold <pkg>
apt list -a <pkg>                            # find the old version
sudo apt install <pkg>=<oldversion>          # downgrade; check dependencies it drags with it, then hold
```

**Sources**: 24.04+ uses deb822 files, `/etc/apt/sources.list.d/ubuntu.sources`. `sudo apt modernize-sources` converts old `.list` files (it backs them up) `[docs: Ubuntu community hub]`. `apt-key` is **removed** in 26.04: third-party keys go in `/etc/apt/keyrings/` referenced with `Signed-By:`.

**PPAs and third-party repos** `[docs]`:

```bash
# [docs]
sudo add-apt-repository ppa:<owner>/<name>   # add (-P/--ppa; -n skips update)
add-apt-repository -L                        # list configured
sudo add-apt-repository -r ppa:<owner>/<name>   # remove the source (does not revert installed packages)
sudo apt install ppa-purge && sudo ppa-purge ppa:<owner>/<name>   # ⚠ downgrades packages back to Ubuntu's versions
```

Safety: a PPA can replace core libraries (libc, mesa, python) and runs as root at install. Prefer the archive, a snap, or a container. PPAs often lag new releases and can block upgrades.

**snap vs deb**: snaps are sandboxed and self-updating (default refresh: 4 times a day). Some Ubuntu packages (Firefox is the well-known one) are snap-backed, so `apt install` pulls a snap `[unverified: which packages]`. `[docs: snapcraft]` for the commands below.

```bash
# [docs]
snap list; snap info <name>; sudo snap install <name>; sudo snap remove --purge <name>   # ⚠ --purge deletes data
snap refresh --list; sudo snap refresh --hold=forever <name>; sudo snap refresh --unhold <name>
snap revert <name>                           # back to the previous revision
snap refresh --time                          # when the next auto-refresh runs
sudo snap set system refresh.retain=2        # keep fewer old revisions (2-20)
```

**Dev tool managers**: OS packages for system tooling; `mise` (per-project runtimes) and `uv` (Python) for projects, installed per their own docs `[unverified: install method; see their sites]`. System Python is externally managed (PEP 668): `sudo apt install python3-venv pipx`, `python3 -m venv .venv`, never `sudo pip install`.

## 3. Services & startup

systemd, same as any modern distro. `systemctl status|enable --now|restart|edit|--failed|list-timers`, `journalctl -u <unit>` all apply `[verified: arch-local]` (see arch.md section 3 for the full set).

| Ubuntu-specific | Note |
|---|---|
| SSH unit is `ssh.service` (and `ssh.socket`), not `sshd` | Socket activation is on: see section 5 |
| `apt-daily.timer`, `apt-daily-upgrade.timer` | Drive `apt update` and unattended-upgrades. `systemctl list-timers 'apt-*'` |
| cron still present | `crontab -e`, `/etc/cron.d/`. Prefer timers for new jobs |
| SysV init scripts | 26.04 is the **last** release that supports them: convert to units |

Boot trouble `[unverified: key sequences vary by firmware]`: hold `Shift` (BIOS) or tap `Esc` (UEFI) for GRUB, `e` to edit the kernel line (append `systemd.unit=rescue.target`), or choose *Advanced options > recovery mode*. Previous boot log: `journalctl -b -1` (works only if the journal is persistent; `journalctl --list-boots`).

## 4. Logs & diagnostics

```bash
# [verified: arch-local] journald flags (identical on Ubuntu)
journalctl -b -p err; journalctl -u <unit> -f; journalctl -k; journalctl --disk-usage
sudo journalctl --vacuum-size=500M                       # ⚠ deletes old logs
ss -tulpn                                                # listeners; sudo shows other users' processes
sudo ss -ltnp 'sport = :8080'                            # what is using port 8080
```

| File | Content `[docs]` |
|---|---|
| `/var/log/apt/history.log`, `term.log` | What apt installed/removed and when, with output |
| `/var/log/dpkg.log` | Every package state change |
| `/var/log/unattended-upgrades/` | What auto-updates did |
| `/var/log/auth.log` | sudo/SSH auth (if rsyslog is installed; else `journalctl -u ssh`) `[unverified: rsyslog default on 26.04]` |
| `/var/crash/` | apport crash reports; `ubuntu-bug`, `apport-cli` |

**Why did it crash**: `cat /proc/sys/kernel/core_pattern` tells you the handler (apport, or systemd-coredump if installed: then `coredumpctl list|info|debug`). 26.04 enables crash dumps by default on desktop and server (release notes).
**Resources**: `htop`, `vmstat 1`, `free -h`, `iostat -x 1` and `iotop` (packages `sysstat`, `iotop`), `ip -s link`. **Disk hogs**: `sudo du -xh --max-depth=1 / | sort -h | tail -15`, `ncdu /` `[docs]`, and check `/var/lib/snapd`, `/var/log`, `/var/lib/docker`.

## 5. Networking & firewall

Servers use **netplan** (YAML in `/etc/netplan/`) rendering to systemd-networkd; desktops render to NetworkManager. DNS is `systemd-resolved`.

```yaml
# [docs] /etc/netplan/01-static.yaml  (chmod 600; two-space indent, no tabs)
network:
  version: 2
  ethernets:
    enp5s0:
      addresses: [192.0.2.10/24]
      routes:
        - to: default
          via: 192.0.2.1
      nameservers:
        addresses: [192.0.2.53]
```

```bash
# [docs] netplan tutorial: try rolls back automatically (default 120 s) if you do not confirm
sudo chmod 600 /etc/netplan/*.yaml
sudo netplan try                 # then: sudo netplan apply
netplan get; netplan status
# [verified: arch-local] resolver + routes are the same tools
ip -br a; ip route; resolvectl status; resolvectl query <name>; sudo resolvectl flush-caches
```

Cloud images: cloud-init regenerates netplan on boot unless disabled (section 13).

```bash
# [docs] ufw (Ubuntu server docs). Allow SSH BEFORE enabling; rules persist across reboots
sudo ufw default deny incoming; sudo ufw default allow outgoing
sudo ufw allow OpenSSH                                    # app profile; or: sudo ufw allow 22/tcp
sudo ufw allow from 192.0.2.0/24 to any port 8080 proto tcp
sudo ufw --dry-run allow http                             # preview
sudo ufw enable; sudo ufw status verbose; sudo ufw status numbered
sudo ufw delete <n>; sudo ufw logging on; sudo ufw app list
```

**Docker publishes ports around ufw** (its own chains): bind with `-p 127.0.0.1:8080:8080` or use a ufw-docker ruleset. Wi-Fi: `nmcli device wifi connect "<SSID>" --ask` (desktop). Tailscale: `curl -fsSL https://tailscale.com/install.sh | sh; sudo tailscale up` `[unverified: check tailscale.com/download for the apt repo instructions]`.

**SSH server**: OpenSSH uses the *first* value seen, and `/etc/ssh/sshd_config.d/*.conf` is read first `[docs]`.

```
# [docs] /etc/ssh/sshd_config.d/10-hardening.conf
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
AllowUsers <user>
DebianBanner no
```

```bash
# [docs] validate, then restart; keep a second session open
sudo sshd -t && sudo systemctl restart ssh.service
# Port/ListenAddress in sshd_config are IGNORED while ssh.socket is active (Ubuntu 22.10+). To change the port:
sudo mkdir -p /etc/systemd/system/ssh.socket.d
printf '[Socket]\nListenStream=\nListenStream=2222\n' | sudo tee /etc/systemd/system/ssh.socket.d/listen.conf
sudo systemctl daemon-reload && sudo systemctl restart ssh.socket
# or opt out of socket activation entirely: sudo systemctl disable --now ssh.socket; sudo systemctl enable --now ssh.service
```

Client config (`~/.ssh/config`): `Host <alias>` / `HostName 192.0.2.10` / `User <user>` / `IdentityFile ~/.ssh/id_ed25519` / `ServerAliveInterval 30`.

## 6. Storage & filesystems

```bash
# [verified: arch-local] inspect (util-linux; identical)
lsblk -f; df -h; findmnt; findmnt --verify; swapon --show
# [docs] fstab: use UUID= (from lsblk -f); test before reboot
sudo mount -a
```

- **LVM**: the server installer often creates a root LV that uses only *part* of the VG. Check `sudo vgs; sudo lvs`, grow with `sudo lvextend -r -l +100%FREE /dev/<vg>/<lv>` (`-r` also resizes the filesystem) `[unverified: confirm LV path from lvs]`.
- **Swap**: default is a swapfile (`/swap.img`); `swapon --show`. **TRIM**: `systemctl status fstrim.timer` `[unverified: expected enabled by default]`.
- **SMART**: `sudo apt install smartmontools`; `sudo smartctl -H /dev/nvme0n1`; `sudo smartctl -a /dev/sda` `[docs]`.
- **Snapshots**: no default snapshot tool. Options: LVM snapshots (`lvcreate -s`), btrfs/ZFS if you chose them, `timeshift` on desktop, or VM/cloud snapshots before risky changes `[docs]`.
- **Encryption**: LUKS at install; 26.04 desktop adds **TPM-backed full-disk encryption** (release notes). Back up the LUKS header: `sudo cryptsetup luksHeaderBackup <dev> --header-backup-file <file>` `[docs]`.

## 7. Users, permissions, sudo, secrets

```bash
# [unverified] standard Debian/sudo tools, not fetched
sudo adduser <user>; sudo usermod -aG <group> <user>; sudo deluser --remove-home <user>   # ⚠ last one deletes the home
sudo passwd -l <user>; sudo chage -l <user>; id; groups
sudo -l                                   # what may I run
sudo visudo -c                            # syntax-check sudoers; edit only via: sudo visudo -f /etc/sudoers.d/<name>
setfacl -m u:<user>:rwX <dir>; getfacl <dir>
```

- **sudo-rs**: 26.04's default `sudo` is a Rust reimplementation; the original is renamed `sudo.ws`; `sudo-ldap` is gone (use PAM for LDAP). Re-test any exotic sudoers rules after upgrading (release notes).
- **SSH agent / keys**: `ssh-add -l`, `ssh-keygen -t ed25519`; desktops run gnome-keyring/`ssh-agent` per session. Hardware keys: `ssh-keygen -t ed25519-sk`.
- **gpg**: `gpg --list-secret-keys --keyid-format long` `[verified: arch-local]`. Secrets never in dotfiles or history: `pass`, `age`, `sops`, or a password-manager CLI.

## 8. Updates & upgrade strategy

**Routine**: `sudo apt update && sudo apt upgrade` (or `full-upgrade`), then check `/run/reboot-required` and `sudo needrestart` (restarts stale services; in automation, `$nrconf{restart} = 'a'` in `/etc/needrestart/conf.d/` for automatic, `'l'` to only list) `[docs]`.

```
# [docs] /etc/apt/apt.conf.d/20auto-upgrades  (enable unattended security updates; both "0" disables)
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
```

```
# [docs] /etc/apt/apt.conf.d/50unattended-upgrades (excerpts): reboot behaviour is OFF by default
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";
Unattended-Upgrade::Package-Blacklist { "linux-"; };   // regexes; "$" anchors
```

```bash
# [docs] test and audit unattended-upgrades
sudo unattended-upgrade -v --dry-run
cat /var/log/unattended-upgrades/unattended-upgrades.log
```

**Livepatch / Pro** `[docs]`: `pro status`; `sudo pro attach <token>` (free for personal use); LTS enables ESM and Livepatch on attach; `sudo pro enable livepatch`; `sudo canonical-livepatch status`. Livepatch defers *some* kernel reboots, not all: still reboot when `/run/reboot-required` appears. ESM extends security fixes to 10 years (Legacy add-on to 15).

**Release upgrades** (`do-release-upgrade`, docs: Ubuntu Server "Upgrade your release"):

1. Only **LTS to next LTS**, one step at a time (24.04 to 26.04). 22.04 must go via 24.04.
2. Back up and **snapshot the VM/LV first**: there is no rollback.
3. Update fully, reboot if required, free several GB, use `tmux`/`screen`.
4. `sudo do-release-upgrade -c` shows whether an upgrade is offered (exit code). Then `sudo do-release-upgrade`. Over SSH it may open a fallback sshd on port **1022**; keep the session in tmux.
5. `/etc/update-manager/release-upgrades` `Prompt=lts` (LTS-only offers) / `normal` / `never` `[unverified: file contents; check the file]`.
6. Config-file prompts: `D` shows the diff, `N` keeps yours (default), `Y/I` takes the maintainer's. Reboot, then `sudo apt autoremove --purge`, re-enable third-party repos (check they support the new release), run `sudo apt modernize-sources`.

## 9. Cleanup / reclaim space

Safe order: measure, then reclaim.

```bash
# [docs] measure
sudo du -xh --max-depth=1 / 2>/dev/null | sort -h | tail -15
journalctl --disk-usage; snap list --all | awk '/disabled/'    # old snap revisions
apt -s autoremove                                            # simulate: what would go
```

1. `sudo apt autoremove --purge` (old kernels included; never remove the running one: `uname -r`).
2. `sudo apt clean`.
3. `sudo journalctl --vacuum-size=500M` ⚠ (or `--vacuum-time=2weeks`).
4. Old snap revisions: `sudo snap set system refresh.retain=2`, then remove disabled ones: `sudo snap remove <name> --revision=<n>`.
5. `/var/crash/*` after reading reports; `docker system df` then `docker system prune` ⚠.

**Do not delete**: `/var/lib/dpkg` (package state), `/var/lib/snapd`, `/etc/apt/keyrings`, the running kernel in `/boot`. `/var/lib/apt/lists/*` is a safe cache (`apt update` rebuilds it).

## 10. Performance & hardware

```bash
# [unverified] Ubuntu tooling, not fetched. [verified: arch-local] for lscpu/sensors/systemd-analyze
lscpu; sensors; systemd-analyze blame | head
sudo ubuntu-drivers devices                  # detect GPUs and recommended drivers
sudo ubuntu-drivers install                  # [unverified] install the recommended driver, then reboot
sudo fwupdmgr refresh && sudo fwupdmgr get-updates && sudo fwupdmgr update    # firmware
```

- **Laptop**: `powerprofilesctl`, or TLP (not both); `powertop` for a report. **Server**: measure with `htop`/`iostat` before tuning; `sysctl` changes go in `/etc/sysctl.d/*.conf`.
- Headless from desktop: `sudo systemctl set-default multi-user.target` `[docs]`. Kernel: default is the GA kernel (7.0 on 26.04); HWE kernels via `linux-generic-hwe-*` on LTS point releases.

## 11. Security hygiene

Minimum: ufw default-deny in, SSH keys only, unattended security updates on, Livepatch or regular reboots, AppArmor enforcing, tested backups.

```bash
# [unverified] standard tools, not fetched
sudo ufw status verbose; ss -tulpn; sudo aa-status               # AppArmor profiles
apt list --upgradable; pro security-status                       # pending/ESM coverage
last -n 10; sudo journalctl -u ssh --since today | tail          # recent logins
sudo apt install fail2ban                                        # optional: rate-limits SSH brute force
```

Disable what you don't use: `sudo systemctl disable --now <unit>`; remove packages you don't need (`sudo apt purge`). Turn on ESM (`pro`) for LTS machines that outlive 5 years. Ubuntu security notices: ubuntu.com/security/notices.

## 12. Backups & recovery

Snapshots and RAID are not backups. Back up to another machine/device.

```bash
# [unverified: restic/rsync per their own docs, not fetched] same tools as on any distro (see arch.md section 12); dpkg --get-selections is from the dpkg man page
sudo apt install restic
restic -r <repo> init && restic -r <repo> backup /etc /home --exclude-caches
restic -r <repo> restore latest --target /tmp/restore-test          # restore drill
rsync -aHAX --delete -n /home/ <dest>/                              # -n = dry run; remove to execute
dpkg --get-selections > pkgs.txt; apt-mark showmanual > manual.txt   # package list
```

Back up: `/etc`, `/home`, `/var/lib/<app>` (databases via their dump tool), `~/.ssh`, `~/.gnupg`, LUKS header. **Restore drill**: quarterly, restore one directory to a scratch path and diff.
**Rescue** `[docs]`: boot the live USB (*Try Ubuntu*), mount the root filesystem at `/mnt`, bind `/dev /proc /sys`, `chroot /mnt`, `update-grub` / `grub-install` as needed. Or GRUB *recovery mode > root shell* (remount `-o remount,rw /`).

## 13. Developer-environment notes

- **Shell**: login shell is bash, but **`/bin/sh` is dash**: `#!/bin/sh` scripts must be POSIX (no arrays, no `[[ ]]`). Use `#!/usr/bin/env bash` for bashisms.
- **Coreutils**: 26.04 ships **rust-coreutils** (uutils); `cp`, `mv`, `rm` stay GNU. GNU versions are reachable with a `gnu` prefix (e.g. `gnuls`). Scripts that parse `ls`/`date`/`sort` output or use rare flags may behave differently: test them (release notes). **sudo-rs** likewise (section 7).
- **Clipboard/open**: Wayland (GNOME on 26.04 is Wayland-only): `wl-copy < file`, `wl-paste` (package `wl-clipboard`; `wl-copy --version` `[verified: arch-local]`); X11: `xclip -selection clipboard`; open: `xdg-open <file-or-url>` `[docs]`.
- **Containers**: Ubuntu's `docker.io` package (simple) vs Docker's own apt repo (`docker-ce`, current): don't mix. Group `docker` is root-equivalent. Alternatives: `podman` (`sudo apt install podman`). A snap-installed Docker cannot see files outside `$HOME` `[unverified]`.
- **Virtualization**: `sudo apt install qemu-kvm libvirt-daemon-system virt-manager`; `multipass` and LXD are snaps. `lscpu | grep -i virtualization`.
- **cloud-init (servers/cloud images)**: sets hostname, users, SSH keys, network on first boot and can re-apply. `cloud-init status --wait`; disable with `sudo touch /etc/cloud/cloud-init.disabled` or set `preserve_hostname: true` in `/etc/cloud/cloud.cfg` `[docs]`.
- **Desktop vs server**: server = `netplan` + systemd-networkd, no GUI, `ubuntu-server` metapackage, `unattended-upgrades` on, cloud-init present. Desktop = NetworkManager, GNOME/Wayland, snap-heavy (Firefox is a snap), Software Updater GUI, `ubuntu-drivers`.

## 14. Gotchas / things that bite

| Trap | Fix |
|---|---|
| `apt upgrade` says "kept back" | `sudo apt full-upgrade` (new deps needed) or a phased update: wait, or `-o APT::Get::Always-Include-Phased-Updates=true`. |
| "Could not get lock /var/lib/dpkg/lock-frontend" | unattended-upgrades or another apt is running; wait or `systemctl list-timers 'apt-*'`. Do not delete lock files. |
| `apt-key` command missing on 26.04 | Put keys in `/etc/apt/keyrings/` and reference with `Signed-By:` in a deb822 `.sources` file. |
| PPA blocks `do-release-upgrade` or swaps libc/mesa | `ppa-purge` first (⚠ downgrades), re-add PPAs only if they support the new release. |
| `Port` in `sshd_config` does nothing | ssh.socket owns the listener: drop-in `ssh.socket.d/listen.conf` (section 5). |
| netplan "permissions too open" or bad YAML | `chmod 600`, spaces not tabs, use `netplan try` so a mistake rolls back. |
| Locked out after `ufw enable` | `ufw allow OpenSSH` **before** enabling. |
| Docker ports reachable despite ufw deny | Docker writes its own chains; bind `127.0.0.1` or use a ufw-docker ruleset. |
| Root LV is half the disk on servers | `lvextend -r -l +100%FREE` (section 6). |
| Hostname/network reverts on reboot (cloud) | cloud-init re-applies; disable or configure it (section 13). |
| Release upgrade dies with the SSH session | Use `tmux`; fallback sshd listens on 1022; snapshot first. |
| Script that worked on 24.04 breaks on 26.04 | rust-coreutils / sudo-rs differences; try the `gnu`-prefixed tool; re-test sudoers. |
| `#!/bin/sh` script fails on `[[` or arrays | `/bin/sh` is dash; use bash explicitly. |
| needrestart prompts hang automation | `NEEDRESTART_MODE=a` (auto) or `l` (list) in the environment `[unverified]`; or the conf.d setting in section 8. |
| Non-interactive install still prompts | `sudo DEBIAN_FRONTEND=noninteractive apt-get install -y <pkg>`. |
| `/boot` full, updates fail (separate `/boot`) | `sudo apt autoremove --purge`; keep the running kernel. |
| `pip install` fails: externally-managed-environment | `python3 -m venv`, `pipx`, or `uv`. |
| "apt says up to date" but a colleague sees a newer package | Phased updates roll out gradually; normal. |
| Snap app updates mid-work / changes behaviour | `sudo snap refresh --hold=forever <name>` (or a time window) and `snap revert`. |

## 15. Sources

Consulted 2026-09-21 (all read as web pages; none of the Ubuntu commands were run):

- Release info: https://documentation.ubuntu.com/release-notes/ , https://documentation.ubuntu.com/release-notes/26.04/ , https://documentation.ubuntu.com/release-notes/26.04/summary-for-lts-users/
- Upgrades: https://ubuntu.com/server/docs/how-to/software/upgrade-your-release/ , https://manpages.ubuntu.com/manpages/noble/en/man8/do-release-upgrade.8.html
- Auto updates / needrestart: https://ubuntu.com/server/docs/how-to/software/automatic-updates/
- Firewall / netplan / SSH: https://ubuntu.com/server/docs/how-to/security/firewalls/ , https://netplan.readthedocs.io/en/stable/netplan-tutorial/ , https://ubuntu.com/server/docs/how-to/security/openssh-server/ , https://discourse.ubuntu.com/t/sshd-now-uses-socket-based-activation-ubuntu-22-10-and-later/30189
- apt / dpkg / apt-mark / add-apt-repository manpages: https://manpages.ubuntu.com/manpages/resolute/en/man8/apt.8.html , https://manpages.ubuntu.com/manpages/noble/en/man8/apt-mark.8.html , https://manpages.ubuntu.com/manpages/noble/en/man1/dpkg.1.html , https://manpages.ubuntu.com/manpages/noble/en/man1/add-apt-repository.1.html
- Pro / Livepatch: https://ubuntu.com/pro-client/docs//en/latest/howtoguides/enable_livepatch/
- Snap updates: https://snapcraft.io/docs/how-to-guides/manage-snaps/manage-updates/
- `apt modernize-sources`: https://discourse.ubuntu.com/t/apt-modernize-source-when-to-use/56609
