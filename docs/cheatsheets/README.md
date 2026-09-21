# Platform cheatsheets

Operator "back pocket" references for running a machine effectively and safely:
one file per platform, same 15 sections in the same order so they can be
compared side by side. They are opinionated, terse, and copy-pasteable, written
for a human or an AI agent who has to do something to a box *now*. One person's
notes shared for reuse, not a supported manual.

| File | Platform | Use it when |
|---|---|---|
| [arch.md](arch.md) | Arch Linux (rolling), with short Hyprland and Omarchy sections | Running or repairing an Arch workstation or server: pacman/AUR, `.pacnew`, keyring, btrfs + snapper rollback |
| [ubuntu.md](ubuntu.md) | Ubuntu 26.04 LTS (and 24.04) | Servers and desktops on apt/snap: netplan, ufw, unattended-upgrades, `do-release-upgrade`, Pro/Livepatch |
| [macos.md](macos.md) | macOS 27 (Apple silicon) | A Mac as a developer machine: Homebrew, launchd, Time Machine, Gatekeeper/SIP, BSD-vs-GNU script traps |
| [truenas.md](truenas.md) | TrueNAS 25.10 (SCALE lineage) and legacy CORE | A ZFS storage appliance: pools, disks, shares, snapshots/replication, upgrades, boot-environment rollback |

## How to read the tags

Each code block starts with a tag saying where its commands came from:

- `[verified: arch-local]`: flags confirmed via `--help`/`man`, or run read-only on a real Arch machine. State-changing commands were never run and carry `[docs]` instead.
- `[docs]`: taken from official documentation or man pages that were read, **not run**. Everything for Ubuntu, macOS, and TrueNAS is at best this.
- `[unverified]`: believed correct, not confirmed. Check before relying on it.
- `⚠`: destructive or hard to undo; the safe variant (list, dry-run, UI) is shown first.

Versions targeted: Arch (rolling, checked on an Omarchy 4.0.4 machine), Ubuntu
26.04 LTS, macOS 27 "Golden Gate", TrueNAS 25.10.7 (26 is beta; CORE 13.x is
end-of-life). All dated 2026-09-21; re-check the version tables before trusting
them later.

## Rosetta table

Everyday tasks across the four platforms. Details, caveats, and safer variants
live in the per-platform sheets. "N/A" means the platform expects you to use
its UI or API instead. TrueNAS commands are for the SCALE lineage unless noted;
`ufw`, `wl-copy` etc. may need installing.

| Task | Arch | Ubuntu | macOS | TrueNAS |
|---|---|---|---|---|
| Install a package | `sudo pacman -S --needed <pkg>` | `sudo apt install <pkg>` | `brew install <formula>` (GUI: `brew install --cask <app>`) | N/A on the host. Apps > Discover Apps |
| Remove a package | `sudo pacman -Rns <pkg>` | `sudo apt purge <pkg>` (`remove` keeps config) | `brew uninstall <formula>` | N/A. Delete the app in Apps > Installed |
| Search packages | `pacman -Ss <regex>` | `apt search <term>` | `brew desc --search <term>` | Apps > Discover Apps (search box) |
| List installed | `pacman -Qeq` (explicit) | `apt-mark showmanual` | `brew leaves`, `brew list --cask` | Apps > Installed |
| Package owning a file | `pacman -Qo <file>` | `dpkg -S <file>` | `pkgutil --file-info <file>` (brew: `readlink $(which <cmd>)`) | N/A |
| Update everything | `sudo pacman -Syu` (Omarchy: `omarchy update`) | `sudo apt update && sudo apt full-upgrade` | `brew update && brew upgrade`, `sudo softwareupdate --install --recommended` | System > Update (creates a boot environment) |
| Remove unused dependencies | `sudo pacman -Rns $(pacman -Qdtq)` (list first: `pacman -Qdtq`) | `sudo apt autoremove --purge` (preview: `apt -s autoremove`) | `brew autoremove --dry-run`, then without the flag | N/A |
| Clean package cache | `sudo paccache -rk2` (preview: `paccache -d`) | `sudo apt clean` | `brew cleanup -n`, then without `-n` | N/A. Prune old boot environments in System > Boot |
| Hold / pin a version | `IgnorePkg = <pkg>` in `/etc/pacman.conf` | `sudo apt-mark hold <pkg>` | `brew pin <formula>` | Update Profile; N/A per package |
| Service status | `systemctl status <unit>` | `systemctl status <unit>` (SSH is `ssh.service`; on 26.04 `sshd.service` is an alias) | `launchctl print gui/$(id -u)/<label>`, `brew services list` | System > Services |
| Start now and at boot | `sudo systemctl enable --now <unit>` | `sudo systemctl enable --now <unit>` | `launchctl bootstrap gui/$(id -u) <plist>`, `brew services start <f>` | System > Services (Start Automatically) |
| Scheduled jobs | `systemctl list-timers` | `systemctl list-timers`, cron | launchd agent with `StartInterval` in `~/Library/LaunchAgents` | Data Protection tasks, System > Advanced Settings > Cron Jobs |
| Tail logs | `journalctl -u <unit> -f` | `journalctl -u <unit> -f` | `log stream --predicate 'process == "<name>"'` | Alerts, Jobs; over SSH `/var/log/` |
| Listening ports | `ss -tulpn` | `ss -tulpn` | `lsof -i -sTCP:LISTEN -n -P` | `sudo ss -tulpn` (CORE: `sockstat -4 -l`) |
| Process using port 8080 | `sudo ss -ltnp 'sport = :8080'`, then `kill <pid>` | same as Arch | `lsof -i TCP:8080 -sTCP:LISTEN -n -P`, then `kill <pid>` | N/A. Stop the service or app in the UI |
| Open a firewall port | `sudo ufw allow 8080/tcp` (if ufw is your firewall) | `sudo ufw allow 8080/tcp` | App Firewall prompts per app; port rules via `pf` anchors | `[unverified]` No host firewall UI: limit service bind addresses and share allowed hosts |
| Disk usage overview | `df -h`, `sudo btrfs filesystem usage /` | `df -h` | `df -h` (misleads on APFS), `diskutil apfs list` | `zpool list -v`, `zfs list -o space -r <pool>` |
| What is eating disk | `sudo du -xh --max-depth=1 /` (pipe to `sort -h`) | same as Arch | `du -xh -d 1 ~` (pipe to `sort -h`) | Snapshots first: `zfs list -t snapshot -r <pool> -o name,used -s used` |
| List block devices | `lsblk -f` | `lsblk -f` | `diskutil list` | Storage > Disks |
| Mount / unmount | `sudo mount <dev> <dir>`, `sudo umount <dir>` | same as Arch | `diskutil mount <dev>`, `diskutil unmount <vol>` | Storage > Import Pool / Export-Disconnect (no manual mounts) |
| Create a snapshot | `sudo snapper -c root create -d "<msg>"` (btrfs + snapper) | none by default: LVM/VM snapshot first | `tmutil localsnapshot` | `zfs snapshot -r <pool>/<dataset>@<name>` or a Periodic Snapshot Task |
| Roll back an update | Boot the snapper snapshot entry; single package: `sudo pacman -U <cached-pkg>` | Restore the VM/LV snapshot; single package: `sudo apt install <pkg>=<ver>` | Restore from Time Machine (no OS downgrade) | System > Boot > Activate the previous boot environment, reboot |
| Reboot needed after update? | Kernel, glibc, systemd, GPU driver updated: yes | `ls /run/reboot-required`, `sudo needrestart` | System Settings / `softwareupdate` says | The Update flow reboots into the new boot environment |
| Firewall status | `sudo ufw status verbose` | `sudo ufw status verbose` | `socketfilterfw --getglobalstate` (`/usr/libexec/ApplicationFirewall/`) | N/A |
| DNS / resolver check | `resolvectl status` | `resolvectl status` | `scutil --dns` | Network > Global Configuration |
| Hostname | `sudo hostnamectl set-hostname <name>` | `sudo hostnamectl set-hostname <name>` (cloud-init may reset it) | `sudo scutil --set HostName <name>` | Network > Global Configuration |
| Time sync check | `timedatectl` | `timedatectl`, `chronyc tracking` | `sudo systemsetup -getusingnetworktime` | System > General |
| Copy to clipboard | `wl-copy` (Wayland), `xclip -selection clipboard` (X11) | same as Arch | `pbcopy` | N/A (do it on your workstation) |
| Open file / URL | `xdg-open <target>` | `xdg-open <target>` | `open <target>` | N/A |
| Keep a job awake / running | `systemd-inhibit <cmd>` | `systemd-inhibit <cmd>` | `caffeinate -i <cmd>` | N/A |
| Check pool / disk health | `sudo btrfs scrub start -B /` | `sudo smartctl -H <dev>` (smartmontools) | `diskutil verifyVolume /` | `zpool status -x`, `zpool status -v <pool>` |

Notes: only Arch-column commands that appear in `arch.md` carry a
`[verified: arch-local]` tag there; `systemd-inhibit` was confirmed with
`--help` only. Every Ubuntu, macOS, and TrueNAS entry comes from official docs
and was never executed.

## Conventions shared by all four sheets

- Section order (so you can diff platforms): 1 first 15 minutes, 2 packages, 3 services, 4 logs, 5 networking, 6 storage, 7 users/secrets, 8 updates, 9 cleanup, 10 performance, 11 security, 12 backups, 13 dev environment, 14 gotchas, 15 sources.
- Placeholders only: `<pkg>`, `<unit>`, `<pool>`, and RFC 5737 addresses (`192.0.2.x`). No real hostnames or addresses.
- "Snapshots are not backups" and "test the restore" appear in every sheet on purpose.
