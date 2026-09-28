# macOS cheatsheet (developer workstation)

Back-pocket reference for running a Mac as a developer machine effectively and
safely. Opinionated, terse, copy-pasteable.

**Written against** (2026-09-21, from Apple and Homebrew pages):

| Release | Status |
|---|---|
| **macOS 27 "Golden Gate"** | Current. Released 2026-09-14. **Apple silicon only** (first release with no Intel support). |
| macOS 26 "Tahoe" | Previous; the last release that ran on Intel Macs. Still receives security updates (26.7 shipped alongside 27). |
| macOS 15 "Sequoia" | Older; Homebrew's stated minimum for full support. |
| Rosetta 2 | Available through macOS 27. From macOS 28 only a subset for older Intel games remains. |
| Homebrew | Apple silicon is the supported platform; Intel is Tier 3. Prefix `/opt/homebrew` (ARM) or `/usr/local` (Intel). |

Apple's man-page mirror may lag the OS: when a flag misbehaves, trust `man <cmd>` on your machine.

| Mark | Meaning |
|---|---|
| `⚠` | Destructive or hard to undo. The safe variant (list / dry-run) comes first. |
| `sudo` | Shown explicitly; a bare command needs no privilege. |
| `[docs]` | From Apple man pages (via the community mirror keith.github.io/xcode-man-pages), Apple support/developer pages, or docs.brew.sh, which I read. **None of these commands were run on a Mac**; the author's reference machine is Arch. |
| `(syntax checked on Arch)` | Flags confirmed via `--help`/`man` on an Arch machine, for cross-platform tools (ssh, gpg). Not run on a Mac. |
| `[unverified]` | Believed correct, could not confirm from a doc. Check first. |

Every code block starts with a tag comment.

---

## 1. First 15 minutes on a fresh install

```bash
# [docs] softwareupdate(8): list, then install recommended updates and restart if needed
softwareupdate --list
sudo softwareupdate --install --recommended --restart
xcode-select --install                     # Command Line Tools (git, clang, make); opens a dialog
fdesetup status                            # FileVault: want "FileVault is On."  (enable in Settings > Privacy & Security)
csrutil status                             # SIP: want "enabled"
```

```bash
# [docs: scutil/systemsetup man pages; socketfilterfw from community sources, Apple ships no man page] firewall on + stealth; hostname; Remote Login only if needed
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
sudo scutil --set ComputerName "<name>"; sudo scutil --set LocalHostName <name>; sudo scutil --set HostName <name>
sudo systemsetup -setremotelogin on        # needs Full Disk Access for the terminal; or Settings > General > Sharing > Remote Login
```

```bash
# [docs] SSH key + keychain-backed agent (Apple's ssh-add flag)
ssh-keygen -t ed25519 -C "<comment>"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519       # stores the passphrase in the login keychain
# ~/.ssh/config:  Host *  /  AddKeysToAgent yes  /  UseKeychain yes    [unverified: UseKeychain is an Apple ssh_config option]
```

```bash
# [docs] Homebrew (installer one-liner: see https://brew.sh); then put brew on PATH.
eval "$(/opt/homebrew/bin/brew shellenv)"            # add to ~/.zprofile (Apple silicon prefix)
# [unverified: third-party sources] Touch ID for sudo that survives OS updates
sudo cp /etc/pam.d/sudo_local.template /etc/pam.d/sudo_local   # then uncomment the pam_tid.so line
```

Also: Time Machine to an external APFS disk (Settings > General > Time Machine), automatic updates on, time set automatically (`sudo systemsetup -getusingnetworktime`).

## 2. Packages

**Homebrew** installs to `/opt/homebrew` (Apple silicon) or `/usr/local` (Intel), needs no sudo (and refuses it). *Formulae* = CLI tools/libraries. *Casks* = GUI apps. Rolling release: it does **not** support installing arbitrary older versions.

```bash
# [docs] docs.brew.sh/Manpage
brew update && brew upgrade               # refresh formulae, then upgrade (add -n / --dry-run to preview)
brew upgrade --greedy                     # also casks that auto-update themselves (skipped by default)
brew install <formula>; brew install --cask <app>
brew uninstall <formula>; brew uninstall --cask --zap <app>      # ⚠ --zap also deletes the app's data
brew info <name>; brew desc <name>; brew list --versions; brew list --cask
brew leaves                               # top-level formulae you installed (not deps)
brew outdated; brew deps --tree <f>; brew uses --installed <f>   # who depends on it
brew doctor                               # read its warnings before "fixing" anything
brew tap <user/repo>; brew untap <user/repo>
```

```bash
# [docs] remove unused + clean (both have a dry run: use it first)
brew autoremove --dry-run                 # unused dependency formulae; drop --dry-run to remove
brew cleanup -n                           # stale downloads/old versions; drop -n to delete (-s scrubs the cache)
# [docs] pin, and the "downgrade" story
brew pin <formula>; brew unpin <formula>  # hold at the installed version
brew list --versions <formula>            # brew cleanup removes old kegs: no rollback afterwards
# For real rollback: a versioned formula (brew install <name>@<N>) if one exists, or restore from Time Machine.
```

```bash
# [docs] services (wraps launchd): user agents by default; sudo => system daemon
brew services list; brew services start|stop|restart <formula>; brew services run <formula>   # run = no auto-start
```

**Brewfile** (declarative machine state, `[docs]`):

```ruby
# [docs] ~/Brewfile
tap "<user/repo>"
brew "git"
cask "<app>"
mas "<App Name>", id: 123456      # Mac App Store, needs the mas CLI
vscode "<publisher.extension>"
```

```bash
# [docs] brew bundle
brew bundle dump --file ~/Brewfile --force     # snapshot what is installed (overwrites the file)
brew bundle install --file ~/Brewfile          # install/upgrade to match; --no-upgrade to keep versions
brew bundle check --file ~/Brewfile
brew bundle cleanup --file ~/Brewfile          # LISTS what is not in the Brewfile; add --force to uninstall ⚠
```

- **Which package owns a file?** Homebrew: `readlink $(which <cmd>)` points into `Cellar/<formula>/<ver>/`. System installer packages: `pkgutil --file-info /path/to/file`, then `pkgutil --pkg-info <id>` / `--files <id>` `[docs]`.
- **Apple silicon vs Intel**: a native shell prints `arm64` from `arch`. Run an Intel-only tool with `arch -x86_64 <cmd>` `[docs]` (needs Rosetta: `softwareupdate --install-rosetta --agree-to-license`). Intel Homebrew under Rosetta lives in `/usr/local`: two brews on one machine is a classic mess.
- **brew vs mise vs uv**: brew for tools and apps; `mise` (`mise use node@lts`, `mise ls`) for per-project language runtimes; `uv` for Python venvs/tools `[unverified: not fetched; see mise.jdx.dev, docs.astral.sh/uv]`. Don't `pip install` into brew's Python (PEP 668).

## 3. Services & startup (launchd)

`launchd` is PID 1 and the only supervisor: no systemd, no cron by default. Job definitions are plists.

| Where | Runs as | When |
|---|---|---|
| `~/Library/LaunchAgents` | you | on your login (GUI session) |
| `/Library/LaunchAgents` | each user | on login, admin-installed |
| `/Library/LaunchDaemons` | root | at boot |
| `/System/Library/...` | | Apple's; **do not touch** |

```bash
# [docs] launchctl(1): modern syntax. Domains: system, user/<uid>, gui/<uid>. Service target = <domain>/<label>
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.example.job.plist    # load + start
launchctl bootout gui/$(id -u)/com.example.job                                    # stop + unload
launchctl kickstart -k gui/$(id -u)/com.example.job                               # (re)start now, -k kills a running one
launchctl print gui/$(id -u)/com.example.job                                      # state, last exit, env (format not stable)
launchctl print-disabled gui/$(id -u)                                             # persistently disabled jobs
launchctl enable gui/$(id -u)/com.example.job; launchctl disable gui/$(id -u)/com.example.job
launchctl blame gui/$(id -u)/com.example.job                                      # why did it launch
sudo launchctl bootstrap system /Library/LaunchDaemons/com.example.daemon.plist   # daemons need sudo
launchctl list | grep example                                                     # legacy view: PID, last exit status, label
```

`launchctl load/unload` are legacy (still work, deprecated). Minimal agent, run every 10 minutes:

```xml
<!-- [docs: shape only; key names from launchd.plist(5), not fetched] ~/Library/LaunchAgents/com.example.job.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.example.job</string>
  <key>ProgramArguments</key><array><string>/opt/homebrew/bin/<tool></string><string>--flag</string></array>
  <key>StartInterval</key><integer>600</integer>
  <key>StandardOutPath</key><string>/tmp/com.example.job.log</string>
  <key>StandardErrorPath</key><string>/tmp/com.example.job.log</string>
</dict></plist>
```

Daemon plists must be owned by `root:wheel` and not group/world-writable or launchd refuses them `[unverified]`. `brew services` writes these plists for you (section 2). **Boot troubleshooting**: safe mode (Apple silicon: hold power, choose disk, hold Shift, "Continue in Safe Mode"), or Recovery for disk repair (section 12) `[unverified: key sequences change]`.

## 4. Logs & diagnostics

```bash
# [docs] log(1): unified logging replaces /var/log/system.log
log show --last 1h --predicate 'process == "<name>"' --style compact          # add --info / --debug for chattier levels
log show --last 30m --predicate 'eventMessage CONTAINS[c] "error"'
log stream --predicate 'subsystem == "com.apple.<x>"' --level debug           # live
log collect --last 1h --output ~/Desktop/logs.logarchive                       # bundle for a bug report (needs root)
```

`Console.app` is the GUI. Crash reports: `~/Library/Logs/DiagnosticReports/` (yours) and `/Library/Logs/DiagnosticReports/` `[unverified]`. Kernel panics land in the latter.

```bash
# [docs] resources + "who owns port 8080"
lsof -i TCP:8080 -sTCP:LISTEN -n -P           # add sudo to see other users' processes; then kill <pid>
lsof -i -sTCP:LISTEN -n -P                    # every listener
sudo powermetrics --samplers cpu_power -i 1000 -n 3     # CPU/GPU/ANE power estimates (root; values are estimates)
top -o cpu; vm_stat; iostat -w 1; nettop      # nettop = per-process network [unverified: nettop not fetched]
# [unverified] disk hogs
du -xh -d 1 ~ 2>/dev/null | sort -h | tail -15     # BSD du uses -d for depth
```

Activity Monitor for a GUI view. `sudo sysdiagnose` produces a large diagnostics bundle for Apple `[unverified]`.

## 5. Networking & firewall

```bash
# [docs] networksetup(8), scutil(8), dscacheutil(1)
networksetup -listallnetworkservices; networksetup -listallhardwareports        # service names ("Wi-Fi") and device (en0)
networksetup -getinfo "Wi-Fi"                                                   # IP, router, mask
networksetup -getdnsservers "Wi-Fi"; sudo networksetup -setdnsservers "Wi-Fi" 192.0.2.53 192.0.2.54    # "Empty" clears
networksetup -getairportnetwork en0                                             # current Wi-Fi SSID
sudo networksetup -setairportpower en0 off; sudo networksetup -setairportpower en0 on
scutil --dns | head -30; scutil --proxy; scutil -r example.com                  # resolver config, proxy, reachability
dscacheutil -q host -a name example.com                                          # what the resolver returns
# [unverified] flush DNS cache (Apple support recommends this pair; dscacheutil -flushcache alone is "for extreme cases")
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
ifconfig; netstat -rn; route -n get default; ping -c3 example.com               # BSD tools; the ip command does not exist
```

**Firewall**: two layers.

```bash
# [docs] 1) Application Firewall (inbound, per-app) via socketfilterfw; state is also in Settings > Network > Firewall
/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
# [docs] 2) pf (packet filter, port-based): inspect; rules load from /etc/pf.conf + anchors (macOS uses anchors)
sudo pfctl -si; sudo pfctl -sr              # status, loaded rules
sudo pfctl -nf /etc/pf.conf                 # -n = parse only. Do this before -f (load) or -e (enable)
```

There is no `ufw` here; "open port X" means: nothing to do for the app firewall's default (it prompts per app), or a pf anchor. **Tailscale**: install the app and follow Tailscale's macOS docs `[unverified]`. Wi-Fi/VPN: Settings; `networksetup` for scripted changes.

**SSH client** `~/.ssh/config`: `Host <alias>` / `HostName 192.0.2.10` / `User <user>` / `IdentityFile ~/.ssh/id_ed25519` / `AddKeysToAgent yes` / `UseKeychain yes` `[unverified: Apple option]`.
**SSH server** (Remote Login): key-only, no root, `AllowUsers <user>`; macOS reads drop-ins from `/etc/ssh/sshd_config.d/` `[unverified: confirm the Include line in /etc/ssh/sshd_config]`. Validate with `sudo sshd -t`; keep a second session open. Toggle: Settings > General > Sharing, or `sudo systemsetup -setremotelogin off`.

## 6. Storage & filesystems

```bash
# [docs] diskutil(8)
diskutil list; diskutil info /                     # disks, partitions, volume details
diskutil apfs list                                 # containers, volumes, space; APFS volumes SHARE one container
diskutil apfs listSnapshots /                      # snapshots (Time Machine local snapshots show up here)
diskutil unmount /Volumes/<name>; diskutil eject /dev/disk<N>; diskutil mount /dev/disk<N>s<M>
diskutil verifyVolume /                            # read-only check; repairVolume needs the volume unmountable
# ⚠ eraseDisk / eraseVolume / apfs deleteVolume destroy data: triple-check the identifier from `diskutil list`
```

- **Space**: `df -h /` under-reports what you can free (APFS shared container, "purgeable" space, local snapshots). Trust Settings > General > Storage, `diskutil apfs list`, and `tmutil listlocalsnapshots /` `[docs]`.
- **Mounts**: no user-edited fstab in practice; volumes mount under `/Volumes`. `mount` lists them. Network shares: Finder or `mount_smbfs` `[unverified]`.
- **Snapshots**: APFS snapshots via Time Machine (section 12): `tmutil localsnapshot`, `tmutil listlocalsnapshots /` `[docs]`.
- **SMART/health**: `diskutil info disk0 | grep -i smart` on internal disks; Apple silicon SSD health is limited: use `system_profiler SPNVMeDataType` `[unverified]`.
- **Encryption**: turn FileVault on (Apple silicon storage is hardware-encrypted regardless; FileVault ties access to your login password `[unverified]`). `fdesetup status`; ⚠ `sudo fdesetup enable` prints a recovery key, store it offline `[docs]`. **TRIM** is automatic on APFS. **Swap** is dynamic (`sysctl vm.swapusage` `[unverified]`), not configurable.
- **Spotlight**: `mdfind -name <file>`, `mdfind -onlyin <dir> "<query>"`; `mdutil -s /` shows indexing status; `sudo mdutil -E /` erases and rebuilds the index ⚠ (CPU/disk heavy for a while) `[docs]`.

## 7. Users, permissions, sudo, secrets

```bash
# [docs] keychain via security(1): the right home for tokens on macOS
security add-generic-password -a "$USER" -s <service> -w <secret> -U     # store/update (visible in shell history: prefer -w with no value to be prompted)
security find-generic-password -a "$USER" -s <service> -w                # read it back
security delete-generic-password -a "$USER" -s <service>                 # ⚠
security list-keychains; security find-identity -v -p codesigning
```

- **Users**: admin vs standard; create daily-driver as admin only if you need it. `dscl . -list /Users` `[unverified]`; `id`, `groups`. **umask** default `022` (`umask`). ACLs: `ls -le`, `chmod +a` (macOS ACL syntax, not POSIX `setfacl`) `[unverified]`.
- **sudo**: `sudo -v` refreshes the timestamp. Touch ID for sudo: section 1. Edit sudoers only with `sudo visudo` (drop-ins in `/etc/sudoers.d/`).
- **SSH agent**: `ssh-add -l`, `ssh-add --apple-use-keychain <key>` `[docs]`; `-D` removes all identities. Legacy `-K`/`-A` flags are deprecated in favour of `--apple-use-keychain` / `--apple-load-keychain`.
- **gpg**: `brew install gnupg`; `gpg --list-secret-keys --keyid-format long` (syntax checked on Arch).
- **Never** put secrets in dotfiles or shell history; use the keychain, `1Password`/`op`-style CLIs, `age`, or `sops`.

## 8. Updates & upgrade strategy

1. Back up first: Time Machine finished recently (`tmutil latestbackup`, `tmutil status` `[docs]`).
2. `softwareupdate --list`, then `sudo softwareupdate --install --recommended --restart` or `--all` `[docs]`. Apple silicon needs authorization for some updates: `--user` / `--stdinpass` `[docs]`. Full macOS installer: `softwareupdate --list-full-installers`, `--fetch-full-installer --full-installer-version <ver>` `[docs]`.
3. Major upgrades (26 to 27): wait a point release (27.1) on machines you depend on; check your tools (Homebrew, Docker/VM software, VPN, endpoint agents) list support. **Intel Macs cannot install 27.**
4. After: `xcode-select --install` may be needed again (CLT go stale); `brew update && brew doctor`; re-run `softwareupdate --install-rosetta --agree-to-license` if Intel apps refuse to start `[docs]`.
5. Rosetta timeline: available through macOS 27, only legacy games after that: audit Intel-only tools now (`file $(which <tool>)` shows `x86_64` vs `arm64`) `[docs: Apple support]`.
6. **Rollback**: there is none from an installed OS upgrade except restore from Time Machine / erase and reinstall. Apple silicon downgrades of the OS need a Mac connected to another Mac (Apple Configurator) `[unverified]`.
7. Reboot need: Settings prompts; `softwareupdate` reports "restart required" per update. MDM-managed fleets: legacy software-update management reportedly stops working in 27 in favour of declarative management `[unverified: secondary source]`.

Homebrew cadence: `brew update && brew upgrade` weekly. Pin what you can't afford to break (`brew pin`).

## 9. Cleanup / reclaim space

Measure first, then reclaim in this order:

```bash
# [docs] safe first
brew cleanup -n; brew autoremove --dry-run           # then without -n / --dry-run
tmutil listlocalsnapshots /                          # local snapshots hold space until thinned
diskutil apfs list | head -40
```

1. `brew cleanup -s`, `brew autoremove` (after the dry runs).
2. Local snapshots: `sudo tmutil deletelocalsnapshots <date>` ⚠ (`<date>` is `YYYY-MM-DD-HHMMSS` as printed by `listlocalsnapshots`, or a mount point); they also age out on their own.
3. Xcode/simulators: `xcrun simctl delete unavailable` `[unverified]`; `~/Library/Developer/Xcode/DerivedData` is a cache.
4. Docker Desktop / OrbStack VM disk: `docker system df`, `docker system prune` ⚠.
5. `~/Library/Caches` (per-app caches; quit apps first). `~/Library/Application Support` holds real data: do not sweep it.
6. Settings > General > Storage > Recommendations (Downloads, old iOS backups).

**Do not delete**: `/System`, `/private/var/db`, anything in `/Library` you don't recognize, `~/Library/Keychains`, `/opt/homebrew/Cellar` by hand (use `brew`).

## 10. Performance & hardware

```bash
# [docs] pmset(1), caffeinate(8)
pmset -g batt; pmset -g assertions; pmset -g log | tail -20     # battery, what blocks sleep, sleep/wake history
pmset -g therm                                                   # thermal state limiting the CPU
sudo pmset -a sleep 0 displaysleep 15                            # ⚠ never sleep on any power source (-a = all); -b battery, -c charger
sudo pmset -a womp 1                                             # wake for network access (servers)
caffeinate -i <long-command>                                     # no idle sleep while it runs; -d keeps display on, -t <secs> timeout, -w <pid>
sysctl -n machdep.cpu.brand_string; system_profiler SPHardwareDataType   # [unverified: not fetched] what am I on
```

Laptop: don't disable App Nap/thermal features; check `pmset -g assertions` when the battery drains. Headless Mac (build server, home lab): `sudo pmset -a sleep 0`, enable auto-login only if you accept the security trade-off, keep FileVault in mind (a rebooted FileVault Mac waits at the unlock screen: `sudo fdesetup authrestart` `[docs]` reboots through it once). Apple silicon has no user-tunable CPU/GPU governor.

## 11. Security hygiene

Minimum: FileVault on, SIP on, firewall on, automatic updates on, Gatekeeper at default, a standard (non-admin) account for daily use if practical, tested backups.

```bash
# [docs] audit, read-only
fdesetup status; csrutil status; spctl --status                # Gatekeeper assessments on?
/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
lsof -i -sTCP:LISTEN -n -P                                     # everything listening; justify each
launchctl print-disabled gui/$(id -u); ls ~/Library/LaunchAgents /Library/LaunchAgents /Library/LaunchDaemons   # what starts at login/boot
```

- **Gatekeeper / quarantine** `[docs]`: downloaded files carry `com.apple.quarantine`. `xattr -l <file>` lists it; `xattr -d com.apple.quarantine <file>` removes it ⚠ only for software you have verified. `spctl --assess -vv <app>` shows why an app is (not) allowed. On macOS 15+ `spctl --add/--remove/--enable/--disable` are deprecated (use configuration profiles); `--global-disable` is deprecated and unsupported since macOS 15 (exit code 4). Since Sequoia the Control-click bypass is replaced by Settings > Privacy & Security > "Open Anyway" `[unverified: widely reported]`.
- **SIP** `[docs]`: `csrutil status` in normal boot; `csrutil disable|enable` only from Recovery. Leave it on. It blocks writes to `/System`, `/usr` (not `/usr/local`), `/bin`, `/sbin`.
- **TCC / privacy**: terminals need Full Disk Access to read `~/Library/Mail`, Safari data, etc.; grant it to your terminal app in Settings > Privacy & Security, not to random binaries.
- **Rosetta/XProtect/MRT**: updated silently via system updates; keep auto-updates on.

## 12. Backups & recovery

Time Machine to an external disk, plus one off-site/cloud copy, plus a restore drill.

```bash
# [docs] tmutil(8)
tmutil destinationinfo; tmutil status; tmutil latestbackup; tmutil listbackups
tmutil startbackup --auto                          # add --block to wait for completion
tmutil addexclusion -p ~/Code/<proj>/node_modules   # -p = fixed-path exclusion (by path, needs root); without -p it is sticky to the item
tmutil isexcluded <path>
tmutil localsnapshot; tmutil listlocalsnapshots /; sudo tmutil deletelocalsnapshots <date>     # ⚠ last one; <date> = YYYY-MM-DD-HHMMSS (or a mount point)
tmutil verifychecksums <backup-path>                # integrity check of a backup
sudo tmutil restore <src-in-backup> <dst>            # or use the Time Machine UI / Migration Assistant
```

- **Also back up**: `~/.ssh`, `~/.gnupg`, `~/Brewfile` (`brew bundle dump`), dotfiles (git), password-manager export, project code (git remotes). Tools like `restic`/`rsync` work as on Linux; note macOS `rsync` is an older version (`rsync --version`), so `brew install rsync` for modern flags `[unverified]`.
- **Restore drill**: quarterly, restore one folder from Time Machine to a scratch path and diff.
- **Recovery** `[docs: Apple support, key sequences vary]`: Apple silicon: shut down, then press and hold the power button until startup options appear, choose Options. Recovery gives Disk Utility (First Aid), reinstall macOS, Terminal (`csrutil`, `diskutil`), and restore from Time Machine.

## 13. Developer-environment notes

- **Shell**: default login shell is **zsh**; `/bin/bash` is still the ancient **3.2** (no associative arrays, no `mapfile`/`readarray`, no `${var,,}`) `[unverified: run /bin/bash --version on your OS]`. Homebrew's bash/zsh come first only if `$(brew --prefix)/bin` is early in `PATH`. Scripts: `#!/usr/bin/env bash`. Terminal.app/iTerm start *login* shells: put PATH setup in `~/.zprofile` (brew) and interactive stuff in `~/.zshrc`.
- **BSD vs GNU userland** (scripts that move between macOS and Linux break here) `[unverified: BSD man pages not fetched; behaviours are long-standing]`:

| Task | macOS (BSD) | Linux (GNU) |
|---|---|---|
| In-place edit | `sed -i '' 's/a/b/' f` | `sed -i 's/a/b/' f` |
| File mtime/size | `stat -f '%m %z' f` | `stat -c '%Y %s' f` |
| Date arithmetic | `date -v+1d`, `date -j -f '%F' 2026-01-01 +%s` | `date -d 'tomorrow'`, `date -d 2026-01-01 +%s` |
| Nanoseconds | no `%N` | `date +%s%N` |
| Regex grep | `grep -E`; **no `-P`** | `grep -P` ok |
| Find with format | no `-printf`; use `-exec stat -f` | `find -printf` |
| xargs empty input | no `-r` (BSD skips by default) | `xargs -r` |
| Follow symlink | `readlink -f` works on recent macOS (older: no) | `readlink -f` |

  Portable options: `brew install coreutils gnu-sed gawk grep findutils`, then use `gsed`/`gdate` etc. or put `$(brew --prefix)/opt/<pkg>/libexec/gnubin` first on PATH.
- **Clipboard/open** `[docs: open; pbcopy/pbpaste unverified]`: `pbcopy < file`, `pbpaste`; `open <file-or-url>`, `open -a "<App>" <file>`, `open -R <path>` (reveal in Finder), `open -g` (background).
- **Containers**: Docker Desktop, OrbStack, Colima (`brew install colima docker`), or Apple's own `container` CLI `[unverified]`. All run a Linux VM: watch disk growth and file-sharing performance. **VMs**: UTM, Tart, or Virtualization.framework; Rosetta can speed x86-64 Linux binaries in ARM Linux VMs `[unverified]`.
- **Apple silicon**: build for `arm64` first; `uname -m` / `arch` tells you the current shell's architecture; `file <binary>` tells you a binary's.
- **Case**: default APFS is case-insensitive (git surprises); create a case-sensitive volume for repos if you need Linux parity: `diskutil apfs addVolume disk<N> "Case-sensitive APFS" <name>` `[docs: syntax to verify with diskutil apfs]`.

## 14. Gotchas / things that bite

| Trap | Fix |
|---|---|
| `brew: command not found` on a new Apple silicon Mac | `eval "$(/opt/homebrew/bin/brew shellenv)"` in `~/.zprofile`. |
| Two Homebrews (`/usr/local` + `/opt/homebrew`) after a migration | Run `arch`; use one prefix. Reinstall under `/opt/homebrew`, `brew bundle dump` from the old one. |
| `brew upgrade` doesn't update some cask apps | They self-update; force with `brew upgrade --greedy`. |
| `brew cleanup` then need the old version | Not recoverable; `brew pin` before, or Time Machine. |
| `sed -i 's/a/b/'` errors "invalid command code" | BSD needs `sed -i '' ...`. |
| Script works on Linux, not here (`date -d`, `stat -c`, `grep -P`, `mapfile`) | Section 13 table; or install GNU tools; check bash 3.2. |
| `df` says free but you can't save | APFS purgeable space + local snapshots: `tmutil listlocalsnapshots /`, Storage settings. |
| "Operation not permitted" as root | TCC / SIP, not permissions. Give your terminal Full Disk Access; SIP protects `/System` and `/usr`. |
| App "is damaged" or "can't be opened" | Quarantine/Gatekeeper: `xattr -l`, `spctl --assess -vv`; remove quarantine only if you trust the source. |
| `launchctl load` prints deprecation or fails silently | Use `bootstrap gui/$(id -u) <plist>`; read `launchctl print gui/$(id -u)/<label>`. |
| A LaunchAgent that needs the GUI session doesn't run over SSH | Agents live in `gui/<uid>`; use a LaunchDaemon (`system`) for headless jobs. |
| Mac sleeps mid-job | `caffeinate -i <cmd>`; check `pmset -g assertions`. |
| Intel binary stops working after OS upgrade | `softwareupdate --install-rosetta --agree-to-license`; Rosetta ends after macOS 27. |
| Intel Mac won't offer macOS 27 | Unsupported: stay on 26 (security updates) and plan hardware. |
| Homebrew refuses `sudo brew` | Correct behaviour; fix ownership of the prefix instead (`brew doctor`). |
| `/etc` edits vanish or don't apply | `/etc` is a symlink to `/private/etc`; some files (`/etc/pam.d/sudo`) are overwritten by OS updates: use `sudo_local`. |
| Spotlight/`mds` pegs the CPU indexing `node_modules`/build dirs | Exclude in Settings > Spotlight > Search Privacy, or `sudo mdutil -i off <volume>` for a dev volume. |
| Git case-rename confusion | Default APFS is case-insensitive; `git mv` in two steps or use a case-sensitive volume. |

## 15. Sources

Consulted 2026-09-21 (nothing was run on macOS):

- Release/support: https://www.apple.com/macos/ , https://9to5mac.com/2026/09/14/macos-27-golden-gate-macos-tahoe-26-7-and-macos-sequoia-15-8-fix-200-vulnerabilities/ (26.7 / 15.8 shipped alongside 27; secondary) , https://support.apple.com/en-us/102527 (Rosetta timeline), https://developer.apple.com/documentation/security/disabling-and-enabling-system-integrity-protection
- Homebrew: https://docs.brew.sh/Installation , https://docs.brew.sh/Manpage , https://docs.brew.sh/Brew-Bundle-and-Brewfile , https://docs.brew.sh/FAQ
- Apple man pages via the community mirror https://keith.github.io/xcode-man-pages/ : `launchctl.1`, `softwareupdate.8`, `tmutil.8`, `log.1`, `pmset.1`, `diskutil.8`, `networksetup.8`, `scutil.8`, `xattr.1`, `spctl.8`, `security.1`, `caffeinate.8`, `defaults.1`, `xcode-select.1`, `fdesetup.8`, `pkgutil.1`, `mdfind.1`, `mdutil.1`, `open.1`, `systemsetup.8`, `lsof.8`, `dscacheutil.1`, `arch.1`, `pfctl.8`, `powermetrics.1`, `ssh-add.1`
- `socketfilterfw` usage (community sources; no Apple man page): https://www.kolide.com/features/checks/mac-firewall , https://manp.gs/mac/8/socketfilterfw
- Touch ID sudo via `sudo_local` (community sources): https://dev.to/siddhantkcode/enable-touch-id-authentication-for-sudo-on-macos-sonoma-14x-4d28
