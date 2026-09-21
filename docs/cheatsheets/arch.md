# Arch Linux cheatsheet (rolling, with an Omarchy section)

Back-pocket reference for running an Arch machine (workstation or server)
without breaking it. Opinionated, terse, copy-pasteable.

**Written against** (2026-09-21): Arch is rolling, so there is no "version".
Tooling was checked on one Omarchy 4.0.4 machine: pacman 7.1.0, systemd 261,
kernel 7.2.x, yay 13.0.1, snapper 0.13.1, btrfs-progs 7.1, Hyprland 0.56.2,
OpenSSH 10.5. Yours will differ; start with `pacman --version`.

| Mark | Meaning |
|---|---|
| `⚠` | Destructive or hard to undo. The safe variant (list / dry-run) comes first. |
| `sudo` | Shown explicitly; a bare command needs no privilege. |
| `[verified: arch-local]` | Ran it read-only, or confirmed the flags with `--help` / `man` on a real Arch machine. Nothing was run with `sudo`. |
| `[docs]` | From official docs or man pages; **not run**. The Arch Wiki blocked automated fetching, so wiki-derived claims are cross-checked against local man pages only. |
| `[unverified]` | Believed correct, could not confirm. Check before relying on it. |

Every code block starts with a tag comment.

---

## 1. First 15 minutes on a fresh install

```bash
# [docs] read https://archlinux.org/news/ first, then a full upgrade (never -Sy alone)
sudo pacman -Syu
# [verified: arch-local] flags confirmed via --help; sudo-capable user via the wheel group
sudo useradd -m -G wheel -s /bin/bash <user> && sudo passwd <user>
sudo visudo -f /etc/sudoers.d/10-wheel      # add: %wheel ALL=(ALL:ALL) ALL   (visudo syntax-checks)
```

```bash
# [verified: arch-local] SSH server (unit is sshd, not ssh), time, hostname
sudo pacman -S --needed openssh && sudo systemctl enable --now sshd
ssh-keygen -t ed25519 -C "<comment>"; ssh-copy-id <user>@<host>   # on the client; then section 5 hardening
timedatectl show -p NTP -p NTPSynchronized      # read-only check
sudo timedatectl set-ntp true
sudo hostnamectl set-hostname <name>
```

```bash
# [docs] essentials; base-devel is required for AUR builds
sudo pacman -S --needed base-devel git pacman-contrib ufw
```

Then: firewall (section 5), snapshots (6), an off-machine backup (12).

## 2. Packages

`pacman` handles the repos (core, extra, multilib); `yay` wraps it and adds the
AUR (user-submitted PKGBUILDs, **unreviewed**).

```bash
# [verified: arch-local] query flags confirmed with pacman --help / man pacman
pacman -Ss <regex>              # search repos          pacman -Si <pkg>   repo info
pacman -Qs <regex>              # search installed      pacman -Qi <pkg>   installed info
pacman -Qeq                     # explicitly installed  pacman -Qmq        foreign (AUR / local builds)
pacman -Ql <pkg>                # files of a package    pacman -Qo <file>  owner of a file
pacman -Qk <pkg>                # verify files exist (-kk: properties too)
sudo pacman -Fy && pacman -F <file>   # owner among *uninstalled* packages (needs files db)
pactree <pkg>; checkupdates     # dep tree; pending updates (no root, no partial-sync risk)
```

```bash
# [verified: arch-local] flags confirmed; not executed
sudo pacman -S --needed <pkg>       # install
sudo pacman -Syu                    # THE update command: refresh + full upgrade
sudo pacman -Rns <pkg>              # ⚠ remove + unneeded deps + config
sudo pacman -D --asdeps <pkg>       # mark as dependency (autoremove-eligible);  --asexplicit reverses
```

**Partial-upgrade rule:** never `pacman -Sy <pkg>` or `pacman -Sy` alone: it
refreshes the databases without upgrading, so the next install can pull
libraries newer than the rest of the system. Always `-Syu`. The one tolerated
exception is refreshing `archlinux-keyring` (below).

```bash
# [verified: arch-local] orphans (autoremove equivalent): list first, empty output = none
pacman -Qdtq
# cache: paccache is in pacman-contrib; default keeps 3 versions
paccache -d                      # dry run
```

```bash
# [docs] not run. Remove orphans only after reading the list. ⚠
sudo pacman -Rns $(pacman -Qdtq)
sudo paccache -rk2               # ⚠ prune to the 2 newest versions per package
sudo systemctl enable --now paccache.timer     # the unit ships with pacman-contrib
# ⚠ never `pacman -Scc` as routine: it deletes the only offline downgrade path
```

```bash
# [docs] downgrade one package from the local cache (this is why you keep 2 versions)
ls /var/cache/pacman/pkg/ | grep '^<pkg>-'
sudo pacman -U /var/cache/pacman/pkg/<pkg>-<oldver>-x86_64.pkg.tar.zst
# then set IgnorePkg = <pkg> in /etc/pacman.conf so the next -Syu doesn't undo it; remove it later.
# Downgrade a package together with the libraries it needs; for the whole system use a snapshot (section 6).
```

**Hold / ignore** `[verified: arch-local: man pacman.conf]`: `IgnorePkg = a b`, `IgnoreGroup = g`,
`HoldPkg = pacman glibc`; one-shot `sudo pacman -Syu --ignore <pkg>`. Holding
drifts toward a partial upgrade; give it an expiry.

**Third-party: AUR via yay**

```bash
# [verified: arch-local] flags confirmed via yay --help / man yay
yay -Ss <term>       # repos + AUR         yay -G <pkg>      fetch PKGBUILD only (read it)
yay -S <pkg>         # build + install     yay -Sua          upgrade AUR packages only
yay -Syu --devel     # also rebuild -git/-svn packages        yay -Pw   Arch news newer than your last upgrade
yay -Yc              # remove unneeded deps
```

Read the PKGBUILD before building: are `source=` URLs the project's own host,
is there an `install=` script or `curl | sh`, and `sha256sums=('SKIP')` on
non-VCS sources? Use `--diffmenu` / `--editmenu` (`man yay`) so updates show
a diff. AUR = arbitrary code as you at build time and as root at install.

```bash
# [docs] mirrors: reflector (man.archlinux.org/man/reflector.1); not installed on the reference machine
sudo pacman -S reflector
sudo reflector --country <CC> --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
# or configure /etc/xdg/reflector/reflector.conf and: sudo systemctl enable --now reflector.timer
# [verified: arch-local] keyring: only on "signature is unknown / corrupted"; pacman-key flags confirmed
sudo pacman -Sy archlinux-keyring && sudo pacman -Su
sudo pacman-key --init && sudo pacman-key --populate       # rebuild if broken; also check the clock
```

**Dev tool managers**: the OS owns system tools (pacman); `mise`/`uv` own project runtimes.

| Tool | Use |
|---|---|
| `mise` `[verified: arch-local]` | `mise use node@lts`, `mise install`, `mise ls`, `mise outdated`, `mise prune`, `mise doctor`. Activate: `eval "$(mise activate bash)"`. |
| `uv` `[docs]` | `uv venv`, `uv pip install`, `uv tool install`, `uv python install`. Package `uv` exists in `extra` `[verified: arch-local: pacman -Ss]`. |
| `pip`/`npm -g` into the system | **Don't.** System Python is externally managed (PEP 668). Use a venv, `uv`, or `mise`. |

```bash
# [verified: arch-local] .pacnew: new upstream default sits beside your edited config
pacdiff -o                       # list only, no changes
pacdiff -s                       # merge interactively via sudo ($DIFFPROG, default vim -d)
```

Ignoring `.pacnew` leaves stale mirrorlists, `sshd_config`, etc. `.pacsave` is your old file after a removal.

## 3. Services & startup (systemd)

```bash
# [verified: arch-local] subcommands confirmed with systemctl --help
systemctl status <unit>;  systemctl --failed;  systemctl cat <unit>;  systemctl list-timers
systemctl list-unit-files --state=enabled        # what starts at boot
sudo systemctl enable --now <unit>               # start now + at boot;  disable --now reverses
sudo systemctl edit <unit>                       # drop-in override (never edit /usr/lib/systemd)
sudo systemctl daemon-reload                     # after changing unit files
sudo systemctl mask <unit>                       # ⚠ cannot start at all; unmask reverses
sudo systemctl reset-failed
```

- **User units** (no sudo): `systemctl --user enable --now <unit>`, files in `~/.config/systemd/user/`. Survive logout: `sudo loginctl enable-linger <user>` `[verified: arch-local]`.
- **Timers** replace cron: `foo.timer` triggers `foo.service`. `OnCalendar=`, `Persistent=true` catches up missed runs. Preview: `systemd-analyze calendar 'Mon *-*-* 03:00'` `[verified: arch-local]`.
- **Boot trouble** `[verified: arch-local]`: `systemd-analyze blame`, `systemd-analyze critical-chain`, `journalctl -b -p err`. Previous boot: `journalctl -b -1` (needs a persistent journal; `journalctl --list-boots`). Bad boot: choose a snapshot or fallback entry; or add `systemd.unit=rescue.target` to the kernel line for one boot `[docs]`.

## 4. Logs & diagnostics

```bash
# [verified: arch-local] flags confirmed via journalctl --help
journalctl -b -p err                 # errors this boot        journalctl -k   kernel (dmesg)
journalctl -u <unit> -f              # follow a unit           journalctl --user-unit <unit>
journalctl --since "1 hour ago"      # also --until            journalctl -g '<regex>'
journalctl --disk-usage
# crashes: core_pattern points at systemd-coredump on this machine
cat /proc/sys/kernel/core_pattern
coredumpctl list --no-pager; coredumpctl info -1; coredumpctl debug -1   # last crash; debug needs gdb
```

```bash
# [docs] not run
sudo journalctl --vacuum-size=500M   # ⚠ deletes old logs (or --vacuum-time=2weeks)
```

```bash
# [verified: arch-local] resources and "who owns port 8080"
btop                                 # cpu / mem / disk / net / processes (if installed)
free -h; lscpu; lsblk -f; df -h; findmnt
ss -tulpn                            # listeners; add sudo to see other users' processes
sudo ss -ltnp 'sport = :8080'        # read the pid, then: kill <pid>
```

```bash
# [docs] what is eating disk (ncdu is nicer if you install it)
sudo du -xh --max-depth=1 / 2>/dev/null | sort -h | tail -15
```

## 5. Networking & firewall

```bash
# [verified: arch-local] read-only
ip -br a; ip route; resolvectl status; resolvectl query <name>
nmcli general status; nmcli device; nmcli connection show
nmcli device wifi list
ping -c3 1.1.1.1 && ping -c3 example.com     # separates routing from DNS
```

```bash
# [docs] state-changing, not run
sudo resolvectl flush-caches                 # clear the resolver cache
nmcli device wifi connect "<SSID>" --ask     # join a Wi-Fi network
nmcli radio wifi on|off                      # ⚠ off drops your connection (lockout risk if you are on Wi-Fi SSH)
```

iwd users: `iwctl` is the client `[docs]` (not installed on the reference machine).

```bash
# [docs] ufw (frontend for nftables; ufw status needs root, so it was not run). Allow SSH BEFORE enabling.
sudo ufw default deny incoming && sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow from 192.0.2.0/24 to any port 8080 proto tcp
sudo ufw enable && sudo ufw status numbered      # delete a rule: sudo ufw delete <n>
```

Raw ruleset: `sudo nft list ruleset` `[docs]`. **Docker publishes ports around
ufw** (its own chains): bind with `-p 127.0.0.1:8080:8080` or use a ufw-docker ruleset.
Tailscale `[docs]`: `sudo pacman -S tailscale && sudo systemctl enable --now tailscaled && sudo tailscale up`; `tailscale status`.

```
# [docs] ~/.ssh/config (client)
Host *
    ServerAliveInterval 30
    AddKeysToAgent yes
    IdentitiesOnly yes
Host <alias>
    HostName <host-or-192.0.2.10>
    User <user>
    IdentityFile ~/.ssh/id_ed25519
```

```
# [docs] /etc/ssh/sshd_config.d/10-hardening.conf  (first value seen wins; don't edit the packaged file)
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
AllowUsers <user>
```

```bash
# [docs] validate BEFORE restarting, and keep a second session open
sudo sshd -t && sudo systemctl restart sshd
```

## 6. Storage & filesystems

```bash
# [verified: arch-local] inspect (btrfs commands need root for full detail)
lsblk -f; findmnt --verify           # devices/UUIDs; lint /etc/fstab (no output = clean)
df -h /; swapon --show; zramctl
sudo btrfs filesystem usage /        # real allocation; df misleads on btrfs
```

```bash
# [docs] btrfs maintenance, not run (both are heavy on I/O)
sudo btrfs scrub start -B / && sudo btrfs scrub status /      # ⚠ heavy I/O; checksum verify, monthly
sudo btrfs balance start -dusage=10 /    # ⚠ heavy, can take hours; only if unallocated space is nearly gone; not routine
```

- **fstab**: `UUID=` from `lsblk -f`; after editing run `findmnt --verify`, then `sudo mount -a` before rebooting `[docs]`.
- **TRIM**: `fstrim.timer` exists but was **disabled** on the reference machine `[verified: arch-local]`. Weekly TRIM: `sudo systemctl enable --now fstrim.timer` `[docs]`; check `findmnt -no OPTIONS /` for `discard=async` first.
- **SMART**: `smartmontools` (not installed here): `sudo smartctl -H /dev/nvme0n1`, `sudo smartctl -a /dev/sda` `[docs]`.
- **Swap**: zram is the desktop default here (`zramctl`). A btrfs swapfile needs `btrfs filesystem mkswapfile` `[docs]`.
- **Encryption**: LUKS at install. `lsblk -f` shows `crypto_LUKS`. Back up the header offline: `sudo cryptsetup luksHeaderBackup <dev> --header-backup-file <file>` `[docs]`.

```bash
# [verified: arch-local] snapper (this machine: config "root", kept to 5, no timeline, bootable via limine)
sudo snapper list-configs; sudo snapper -c root list
sudo snapper -c root create -c number -d "before <change>"
sudo snapper -c root delete <num>          # ⚠ one snapshot
```

Restore with limine: pick the snapshot entry at boot, then `limine-snapper-restore` (binary present `[verified: arch-local]`; ⚠ restores the root subvolume from a snapshot, read its prompts `[unverified: behaviour]`). A snapshot lives on the **same disk**: it undoes a bad upgrade, not a dead SSD.

## 7. Users, permissions, sudo, secrets

```bash
# [docs] groups take effect after re-login; ACLs need the acl package
id; groups; sudo usermod -aG <group> <user>
umask                                # 0022 default; 0077 = private by default
setfacl -m u:<user>:rwX <dir>; getfacl <dir>
```

- **sudo**: edit only with `visudo -f /etc/sudoers.d/<name>` `[verified: arch-local]` (a syntax error otherwise locks you out). Prefer specific `NOPASSWD` command lists over `NOPASSWD: ALL`.
- **SSH agent**: `ssh-add -l` lists keys (errors if no agent `[verified: arch-local]`). openssh ships a user unit: `systemctl --user enable --now ssh-agent.socket` plus `SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"` `[verified: arch-local: unit file present and its header says so]`.
- **gpg** (2.4.9 here `[verified: arch-local]`): `gpg --list-secret-keys --keyid-format long`; export with `gpg --export-secret-keys --armor <id>` `[docs]`, ⚠ store encrypted and offline.
- Secrets never in dotfiles or history: `pass`, `age`, `sops`, or a password-manager CLI.

## 8. Updates & upgrade strategy

1. Read https://archlinux.org/news/ (or `yay -Pw`). Manual-intervention notices are rare; skipping one is how systems break.
2. Snapshot: `sudo snapper -c root create -c number -d "pre-upgrade"`.
3. `checkupdates`, then `sudo pacman -Syu`, then AUR (`yay -Sua`).
4. Read every `warning:`; handle `.pacnew` (`pacdiff -o`).
5. **Reboot after kernel, glibc, systemd, or GPU-driver updates.** Stock Arch deletes the running kernel's modules on upgrade, so new USB/Wi-Fi/vfat loads can fail until reboot; `kernel-modules-hook` (installed here `[verified: arch-local]`) keeps them.
6. After: `systemctl --failed`, `journalctl -b -p err`, `pacman -Dk` ("No database errors have been found!" `[verified: arch-local]`).

"Conflicting files": an unowned file is in the way; find it (`pacman -Qo <file>`), move it, retry. `--overwrite '<glob>'` is a last resort ⚠ `[verified: arch-local: man pacman]`. A broken boot after upgrade: live USB, `arch-chroot`, `pacman -Syu` again `[docs]`. Cadence: weekly on workstations; never months behind (giant jumps hit keyring and news traps).

## 9. Cleanup / reclaim space

Measure, then reclaim in this order; stop when you have enough:

```bash
# [verified: arch-local] measure
sudo btrfs filesystem usage /; pacman -Qdtq; paccache -d; journalctl --disk-usage
du -sh ~/.cache ~/.local/share 2>/dev/null
```

1. Orphans: `sudo pacman -Rns $(pacman -Qdtq)` after reading the list.
2. Cache: `sudo paccache -rk2` ⚠ (keeps 2 versions).
3. Journal: `sudo journalctl --vacuum-size=500M` ⚠.
4. `~/.cache/yay/` (AUR build dirs) is a cache; safe to delete.
5. Snapshots: `sudo snapper -c root list`; delete the oldest, never the newest.
6. Coredumps: `/var/lib/systemd/coredump/` `[docs]`.
7. Containers: `docker system df`, then `docker system prune` ⚠ (`-a` / `--volumes` only if you mean it) `[docs]`.

**Do not delete**: `/var/lib/pacman` (package db), `/etc/pacman.d/gnupg` (keyring), `/boot` contents, the newest snapshot, or the whole package cache.

## 10. Performance & hardware

```bash
# [verified: arch-local] read-only
lscpu | head -20; sensors; powerprofilesctl list; sysctl vm.swappiness; systemd-analyze blame | head
```

- Power: `powerprofilesctl set performance|balanced|power-saver` `[docs]`. Laptops: power-profiles-daemon **or** TLP, not both.
- GPU: NVIDIA needs the driver package matching the kernel (`nvidia-open` / `-dkms`) and a reboot; Intel/AMD use in-kernel drivers + Mesa `[docs]`.
- Firmware: `fwupdmgr get-updates && fwupdmgr update` (package `fwupd`) `[docs]`.
- Server: `cpupower frequency-set -g performance` (package `cpupower`, not installed here) `[docs]`. Measure with `btop` before tuning.

## 11. Security hygiene

Minimum: default-deny firewall in, SSH keys only, root login off, time sync on, weekly `-Syu`, disk encryption on laptops, tested backups.

```bash
# [verified: arch-local] audit, read-only
ss -tulpn                              # everything listening; justify each
systemctl list-unit-files --state=enabled; systemctl --failed
pacman -Qkq                            # missing package files (noisy)
pacman -Qmq                            # foreign/AUR packages: nobody else reviews these
# [docs] known-vulnerable installed packages (Arch Security Team data; package is in extra)
sudo pacman -S arch-audit && arch-audit
```

Disable what you don't use (`sudo systemctl disable --now <unit>`). Hardware keys for SSH: `ssh-keygen -t ed25519-sk` `[docs]`.

## 12. Backups & recovery

Snapshots are **not** backups. Back up to another device or machine.

| Back up | Note |
|---|---|
| `/home`, `/etc` | data, dotfiles, `~/.ssh`, `~/.gnupg`; pacman.conf, fstab, sshd drop-ins |
| Package lists | `pacman -Qqen > pkglist.txt` (native), `pacman -Qqem > aurlist.txt` (foreign) `[verified: arch-local: flags]` |
| LUKS header, gpg keys | offline copy |

```bash
# [docs] restic (not installed here): encrypted, deduplicated, many backends
restic -r <repo> init
restic -r <repo> backup ~/ --exclude-caches --exclude ~/.cache
restic -r <repo> snapshots
restic -r <repo> restore latest --target /tmp/restore-test      # the restore drill
rsync -aHAX --delete -n --info=stats1 ~/ <dest>/                # -n = dry run; drop it to execute
```

**Restore drill**: quarterly, restore one directory to a scratch path and diff it. An untested backup is a hope.
**Rescue**: boot the install USB, `cryptsetup open <dev> cryptroot` (if LUKS), mount root (btrfs: `-o subvol=@`), `arch-chroot /mnt`, fix, reboot `[docs]`. Rebuild initramfs: `sudo mkinitcpio -P` `[verified: arch-local: flag]`. With btrfs+limine, the boot-menu snapshot entry is the fastest rollback.

## 13. Developer-environment notes

- **Shell**: bash by default; zsh/fish are packages. GNU userland: `sed -i`, `date -d`, `stat -c`, `readlink -f` work; do not carry BSD/macOS forms (`sed -i ''`, `stat -f`, `date -v`) into scripts that run here.
- **Clipboard/open** `[verified: arch-local: wl-clipboard 2.3.0]`: `wl-copy < file`, `wl-paste`; X11: `xclip -selection clipboard`; open: `xdg-open <file-or-url>` `[docs]`.
- **Containers**: Docker 29.7.2 present here `[verified: arch-local]`: `sudo systemctl enable --now docker`; the `docker` group is root-equivalent. Rootless Podman is the alternative `[docs]`.
- **Virtualization**: `libvirt` + `qemu-full` + `virt-manager`; `lscpu | grep -i virtualization` `[docs]`.

### Wayland / Hyprland basics (short)

```bash
# [verified: arch-local] hyprctl subcommands confirmed via hyprctl --help (Hyprland 0.56.2)
hyprctl version; hyprctl monitors; hyprctl clients; hyprctl activewindow
hyprctl binds; hyprctl configerrors; hyprctl reload; hyprctl rollinglog
```

Hyprland 0.56 reads a **Lua** config (`hyprland.lua`; older releases used `hyprland.conf`). X11-only tools (`xdotool`, `xrandr`) don't see native Wayland windows. Screen sharing needs `xdg-desktop-portal-hyprland` `[docs]`.

### Omarchy (opinionated Arch distro: Hyprland + Limine + btrfs/snapper)

From the packaged files under `/usr/share/omarchy`, read-only `[verified: arch-local]`.

| Thing | Where / how |
|---|---|
| Version, channel | `omarchy version`, `omarchy channel current` (stable / rc / edge / dev) |
| Update everything | `omarchy update` (`-y` unattended): prunes cache to 2 versions, snapshots, refreshes keyring, `pacman -Syu`, runs migrations and post-update hooks, updates AUR + mise, reviews orphans, offers reboot |
| **Direct `pacman -Syu` is blocked** | A pacman hook aborts it with "Woah partner". Deliberate bypass: `sudo env OMARCHY_ALLOW_DIRECT_PACMAN=1 pacman -Syu` |
| Snapshots | `omarchy snapshot create` / `restore` (snapper + `limine-snapper-restore`); root only, kept to 5, no timeline |
| Packages | `omarchy pkg add <pkg>`, `omarchy pkg drop <pkg>`, `omarchy pkg aur add <pkg>`, `omarchy pkg install` (TUI) |
| Reset to defaults | `omarchy refresh config <path-under-~/.config>` (backs yours up as `.bak.<ts>`), `omarchy refresh <hyprland, limine, pacman, shell, or tmux>`, `omarchy reinstall` (⚠ overwrites your config changes). ⚠ `omarchy refresh pacman` overwrites `/etc/pacman.conf` and the mirrorlist with the channel defaults (`.bak` copies kept), then updates all packages |
| Migrations | `omarchy migrate --pending`; state in `~/.local/state/omarchy/migrations` |
| Defaults live | `/usr/share/omarchy/{default,config,themes,bin}`; your overrides in `~/.config/hypr/*.lua` and `~/.config/omarchy/` (hooks: `hooks/<name>.d/`) |
| Bash defaults | `/usr/share/omarchy/default/bash/` (aliases, functions, envs, init: mise, starship, zoxide, fzf), sourced from `~/.bashrc`; override *after* the source line |
| Repos | own mirror + `[omarchy]` in `/etc/pacman.conf` per channel |
| Firewall | ufw default-deny incoming plus ufw-docker rules |
| Discover | `omarchy commands --all`; `omarchy <group> --help`; `omarchy theme list` / `omarchy theme set <name>`, `omarchy font list` / `omarchy font set <name>` |

## 14. Gotchas / things that bite

| Trap | Fix |
|---|---|
| `pacman -Sy <pkg>` (partial upgrade) breaks shared libs | Always `-Syu`; recover with a full `-Syu` or a snapshot. |
| Skipped the news; upgrade needs manual steps | Read archlinux.org/news (or `yay -Pw`) first. |
| "invalid or corrupted package (PGP signature)" | `sudo pacman -Sy archlinux-keyring && sudo pacman -Su`; else `pacman-key --init && --populate`; check the clock. |
| `.pacnew` ignored; stale mirrorlist / sshd_config | `pacdiff -o` after every upgrade. |
| `pacman -Scc` wipes the only downgrade path | `sudo paccache -rk2`. |
| `pacman -Rdd` skips dependency checks | Not as a habit; ⚠ can break the system. |
| `-Rns $(pacman -Qdtq)` removes something you wanted | Read the list; `pacman -D --asexplicit <pkg>` to keep. Empty list just errors harmlessly. |
| AUR package built without reading the PKGBUILD | `yay -G <pkg>`, read it, use `--diffmenu`. |
| `-git` AUR packages never update | `yay -Syu --devel` occasionally. |
| Old kernel modules gone until reboot | Reboot after kernel updates; `kernel-modules-hook`. |
| Boot fails after a kernel update (ESP full, bootloader not regenerated) | `df -h /boot`; `sudo mkinitcpio -P`; Omarchy: `omarchy refresh limine`. |
| `pip install` fails: externally-managed-environment | `uv`, `python -m venv`, or `mise`. |
| Docker ports bypass ufw | Bind to `127.0.0.1` or use a ufw-docker ruleset. |
| btrfs says full while `df` shows space | `sudo btrfs filesystem usage /`; balance only if unallocated is near zero. |
| Snapshot treated as backup | Same disk; back up elsewhere (section 12). |
| SSH config error locks you out | `sudo sshd -t` first; keep a second session open. |
| Omarchy: pacman "Woah partner" abort | `omarchy update`, or the explicit env-var bypass. |

## 15. Sources

Consulted 2026-09-21:

- Local man pages and `--help` on the reference machine: `pacman(8)`, `pacman.conf(5)`, `pacman-key(8)`, `pacdiff`, `paccache`, `yay(8)`, `snapper`, `btrfs`, `systemctl`, `journalctl`, `coredumpctl`, `hyprctl`, `mise`; and `/usr/share/omarchy` (read-only).
- reflector: https://man.archlinux.org/man/reflector.1
- ufw and sshd semantics (Ubuntu docs, same upstream tools): https://ubuntu.com/server/docs/how-to/security/firewalls/ , https://ubuntu.com/server/docs/how-to/security/openssh-server/

Not fetched (the Arch Wiki blocked automated access), read these yourself:
https://archlinux.org/news/ , https://wiki.archlinux.org/title/System_maintenance ,
https://wiki.archlinux.org/title/Pacman , https://wiki.archlinux.org/title/Pacman/Tips_and_tricks ,
https://wiki.archlinux.org/title/Snapper , https://wiki.archlinux.org/title/Btrfs
