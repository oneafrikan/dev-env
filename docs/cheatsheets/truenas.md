# TrueNAS cheatsheet (SCALE lineage, plus legacy CORE)

Back-pocket reference for running a TrueNAS storage appliance without losing
data. Opinionated, terse, copy-pasteable. Placeholders: `<pool>`, `<dataset>`,
`<disk>`, and RFC 5737 addresses (`192.0.2.x`).

**Written against** (2026-09-21, from truenas.com docs and the OpenZFS man pages):

| Release | Status |
|---|---|
| **TrueNAS 25.10 "Goldeye"** (SCALE lineage, Debian/Linux) | Current stable, recommended for general use. Latest point release **25.10.7** (2026-09-02). Kernel 6.12 LTS, OpenZFS 2.3.x. |
| 25.04 "Fangtooth" | Previous stable; last release 25.04.2.6 (2025-10-30). |
| **TrueNAS 26** | **Beta** (26-BETA.3, 2026-08-20). OpenZFS 2.4.3, kernel 6.18; the REST API is removed (WebSocket API only). Annual cadence. Do not use for real data. |
| **TrueNAS CORE** (FreeBSD) | **Legacy, end of the line**: 13.0-U6.8 (2025-07-14), 13.3-U1.2 (2025-04-29). "No longer under active development." Jails, plugins and VMs are marked obsolete (iocage has unfixable vulnerabilities). Migration to SCALE is one-way. |

| Mark | Meaning |
|---|---|
| `⚠` | Destructive or hard to undo. The safe variant (list / dry-run / UI) comes first. |
| `[docs]` | From docs I fetched: TrueNAS documentation and OpenZFS man pages. **None of this was run on a TrueNAS box**; the author's reference machine is Arch (no ZFS). |
| `[unverified]` | Believed correct, could not confirm from a doc. Check first. |
| `[SCALE]` / `[CORE]` | Only true on that flavour. Unmarked = both. |

Every code block starts with a tag comment. UI paths change between releases; if a menu is missing, use the UI search.

### Which am I on?

```bash
# [docs: uname is universal; version-file layout unverified]
uname -s                     # Linux = SCALE lineage (25.x, 24.x...), FreeBSD = CORE
cat /etc/version             # release string, e.g. 25.10.x (SCALE) or TrueNAS-13.0-U6.x (CORE) [unverified: exact format]
```

UI: the version is shown on the dashboard and under System > Update. Names: 22.12 to 24.04 were "SCALE" (Bluefin, Cobia, Dragonfish), 24.10 Electric Eel, 25.04 Fangtooth, 25.10 Goldeye `[unverified: older names]`.

### It is an appliance: what NOT to do

- **Do not** `apt install`, `pip install`, or `pkg install` on the host `[SCALE][CORE]`. Updates create a new boot environment and carry forward *core configuration only*: other host changes do not carry forward `[docs]`. Package changes can also break the middleware. Run extra software as an **App** (SCALE) instead.
- **Do not** create or reshape pools with `zpool`/`zfs` on the CLI: the middleware (which owns the config database) will not know. Use the UI; if you must use the CLI, export and re-import the pool in the UI afterwards `[docs: TrueNAS community guidance]`.
- **Do not** touch the **boot pool** (`boot-pool`): no datasets, no manual `zpool upgrade` `[unverified: community reports of breakage]`. Manage it in System > Boot (attach a mirror, scrub, boot environments).
- **Do not** work as root casually. Fresh installs use `truenas_admin`; root is deprecated and can be disabled. Enable sudo for the admin user only while needed `[docs]`.
- **Do not** import a pool on two systems at once, or use `-f` on import unless you are certain the other system is off.
- **Do not** upgrade a pool's feature flags until you are committed to the release: it is irreversible and blocks rollback `[docs]`.

---

## 1. First 15 minutes on a fresh install

| # | Do | Where `[docs]` |
|---|---|---|
| 1 | Set/confirm the admin password; create a named admin; disable root and default-admin passwords (never all admin passwords at once) | Credentials > Users |
| 2 | Static IP or DHCP reservation, DNS, gateway. **Use Test Changes**: it reverts in 60 s if you lose access | Network |
| 3 | Time zone and NTP; hostname | System > General; Network > Global Configuration |
| 4 | Create the pool (mirror/RAIDZ2 layout you can live with; RAIDZ can be extended a disk at a time in 25.10). Leave the boot device alone; add a second boot device as a mirror | Storage > Create Pool; System > Boot |
| 5 | Datasets per purpose (one per share/app/user) with the right preset; never share the pool root | Datasets |
| 6 | Alert email so failures reach you | System > Alert Settings / Email |
| 7 | Data protection: periodic snapshots, scrub schedule (weekly by default), replication or cloud sync, an SMART/health plan (section 6) | Data Protection |
| 8 | **Export the system config** and store it off the box | System > Advanced > Manage Configuration (older releases: System > General) |
| 9 | UPS if you have one | System > Services > UPS |
| 10 | Update Profile (Conservative vs Early adopter) and confirm the current release is the recommended one | System > Update |

## 2. Packages

An appliance has **no host package management for you**. Substitutes:

| You want | Do |
|---|---|
| Extra software `[SCALE]` | Apps > Discover Apps, or Apps > Discover > "Install via YAML" (Docker Compose) `[docs]` |
| Extra software `[CORE]` | Jails/plugins are obsolete (section 13). Move the workload to SCALE, another host, or a VM elsewhere |
| Update the OS | System > Update (section 8) |
| List/rollback OS versions | System > Boot (boot environments) |
| Dev toolchains (mise, uv, brew, compilers) | Not on the NAS. Run them on your workstation and use SSH/SMB/NFS/API |

## 3. Services & startup

Manage services in **System > Services** (start/stop, and the *Start Automatically* toggle) `[docs]`. Shares, apps, and tasks also have their own screens.

```bash
# [docs: CLI namespaces from the TrueNAS CLI reference; exact verbs unverified]
cli                                  # TrueNAS CLI (interactive). Namespaces include: service, storage, system, task, app, network, sharing
cli -c 'service query'               # [unverified: -c one-shot form]
# [unverified] the same via the API client
midclt call service.query
```

- `[SCALE]` the host is Debian/systemd: `systemctl status <unit>` and `journalctl -u <unit>` are fine for **looking** (use `sudo` as `truenas_admin`); do not `enable/disable/edit` host units by hand: the middleware owns them.
- `[CORE]` FreeBSD rc.d: `service <name> status` `[unverified]`; same rule: use the UI.
- **Scheduled work**: Data Protection (snapshot, replication, cloud sync, scrub, rsync tasks) and System > Advanced > Cron Jobs / Init-Shutdown Scripts. In 25.10 the built-in SMART test scheduler was removed and existing tests were converted to **cron tasks**: verify they still exist (section 6) `[docs]`.
- **Boot troubleshooting**: pick an older boot environment from the boot menu, or use the local console's setup menu (also reachable over SSH as an admin user; the CLI reference says option 6 opens the CLI) `[docs]`. A working previous boot environment is your first recovery step.

## 4. Logs & diagnostics

- UI: the **alert bell**, **Jobs** (task manager icon), Dashboard/Reporting for CPU/RAM/disk/network, System > Audit `[unverified: audit menu name]`.
- `[SCALE]` `/var/log/middlewared.log` (API and config changes) and `/var/log/messages` `[docs: community/docs mention both]`; `journalctl -b -p err` `[unverified on the appliance]`. `[CORE]` `/var/log/messages`, `dmesg`.
- Logs live on the **system dataset**; if it sits on the boot pool it eats boot space `[unverified]`. Choose its pool in System > Advanced > Storage.

```bash
# [docs] read-only diagnostics (SCALE: prefix sudo as truenas_admin; CORE: root shell)
zpool status -x                          # only pools with problems ("all pools are healthy" = fine)
zpool status -v <pool>                   # full detail + files with permanent errors (-v)
zpool list -v                            # size, alloc, free, FRAG, CAP, HEALTH per vdev
zpool iostat -v <pool> 5                 # live per-disk I/O every 5 s
zfs list -o space -r <pool>              # where space goes: data, snapshots, children, reservations [unverified: "space" preset]
zfs list -t snapshot -r <pool> -o name,used,refer -s used     # biggest snapshots last
arc_summary                              # ARC size/hit ratio [unverified: ships with ZFS tools]
smartctl -a /dev/<disk>                  # SMART health [docs: smartmontools binaries are still shipped in 25.10]
```

- **Port owner**: `[SCALE]` `sudo ss -tulpn` `[verified: arch-local: ss syntax]`. `[CORE]` `sockstat -4 -l` `[unverified]`.
- **Disk hogs**: usually snapshots, not files. Check `zfs list -o space` before deleting data.
- **ARC** (ZFS read cache) using most of your RAM is normal and by design: judge by hit ratio and by whether apps swap, not by "RAM used".

## 5. Networking & firewall

- All network config lives in **Network** (interfaces, bridges, LAGG, VLANs, static routes, IPv6, global DNS/gateway). After any interface change, click **Test Changes** and then **Save Changes** within the timer (default 60 s) or it auto-reverts `[docs]`. Console setup menu can reset the network if you are locked out `[docs]`.
- **Firewall**: there is no general packet-filter UI to lean on `[unverified for 25.10]`. Reduce exposure with per-service bind addresses, per-share *allowed hosts/networks*, and a firewall upstream (router/VLAN). Never expose the web UI, SSH, SMB, or NFS to the internet; reach it by VPN (a Tailscale app exists in the app catalog `[unverified]`).
- **SSH** (System > Services > SSH `[docs]`): give admin users an SSH public key (Credentials > Users), allow key login, and turn **off** password authentication once keys work. Users need the *SSH access* and *Shell* options to log in.

```bash
# [unverified] standard OS tools; not run on the appliance
ip -br a; ip route                       # [SCALE] addresses and routes (read-only)
ifconfig; netstat -rn                    # [CORE]
ping -c3 192.0.2.1; ping -c3 example.com # separates routing from DNS
```

Client `~/.ssh/config`: `Host nas` / `HostName 192.0.2.10` / `User <admin-user>` / `IdentityFile ~/.ssh/id_ed25519`.

## 6. Storage & filesystems (ZFS)

**Vocabulary**: a *pool* is made of *vdevs* (mirror, RAIDZ1/2/3, plus optional special, log, cache, spare). Redundancy lives in the vdev: lose a vdev, lose the pool. A *dataset* is a filesystem (files, snapshots, ACLs, quotas); a *zvol* is a block device (for iSCSI and VMs). Prefer datasets.

```bash
# [docs] inspect (safe)
zpool status -v <pool>                 # -x health only, -t trim status, -L real paths, -P full paths, -g GUIDs
zpool list; zpool get all <pool> | head -40
zfs list -r <pool>
zfs get -r compression,recordsize,atime,quota,refquota,reservation,sync <pool>/<dataset>
```

**Dataset properties** (prefer the UI: Datasets > Edit; the CLI shown for reading/understanding) `[docs: zfsprops(7)]`:

| Property | Meaning / guidance |
|---|---|
| `compression` | `on` = lz4 by default; cheap and usually a net win. `zstd` for archives |
| `recordsize` | Max block size for files. Big sequential media: larger; databases: small (16K). Only affects new writes. `volblocksize` (zvols) is fixed at creation |
| `atime` | `off` avoids a write on every read; `relatime` is the middle ground |
| `quota` / `refquota` | Cap dataset + descendants / cap the dataset alone (excludes snapshots and children) |
| `reservation` / `refreservation` | Guaranteed space (same split). Use one on a scratch dataset as a "panic buffer" you can release if the pool fills |
| `sync` | `standard` default. ⚠ `disabled` speeds writes and **loses acknowledged data on power loss**; never for databases/VM/iSCSI |
| `copies`, `dedup` | Leave alone (`copies=2` is not backup; dedup needs huge RAM) |

```bash
# [docs] snapshots and clones (zfs-snapshot, zfs-destroy, zfs-rollback man pages)
zfs snapshot -r <pool>/<dataset>@manual-$(date +%Y%m%d)
zfs list -t snapshot -r <pool>/<dataset>
zfs destroy -nv <pool>/<dataset>@<snap>          # -n = DRY RUN, -v = show. Run this first
zfs destroy <pool>/<dataset>@<snap>              # ⚠ irreversible; -r/-R destroy recursively/dependents: extreme care
zfs destroy -nv <pool>/<dataset>@<first>%<last>  # ⚠ range of snapshots (dry run first)
zfs clone <pool>/<dataset>@<snap> <pool>/<clone> # writable copy; keeps its origin snapshot alive
zfs rollback <pool>/<dataset>@<snap>             # ⚠ discards changes since; refuses if newer snapshots exist
zfs rollback -r <pool>/<dataset>@<snap>          # ⚠ ALSO destroys all newer snapshots (-R: and their clones)
ls /mnt/<pool>/<dataset>/.zfs/snapshot/          # browse/copy files out of snapshots; safest "restore"
```

Snapshots keep deleted data alive: **deleting files does not free space until snapshots holding them are destroyed**.

```bash
# [docs] send/receive (zfs-send, zfs-receive man pages). Prefer UI Replication Tasks; this is what they wrap.
zfs send -nv <pool>/<dataset>@<snap>                                    # dry run: size estimate
zfs send -v <pool>/<dataset>@<a> | ssh <user>@192.0.2.20 zfs receive -s -u <backuppool>/<dataset>
zfs send -v -i @<a> <pool>/<dataset>@<b> | ssh <user>@192.0.2.20 zfs receive -s -u <backuppool>/<dataset>    # incremental
zfs send -w ...                                                         # raw: send encrypted data without keys loaded
zfs send <pool>/<dataset>@<snap> | zfs receive -nv <backuppool>/<dataset>   # dry run of the receive side (nothing written)
# receive -F ⚠ rolls the target back and DESTROYS snapshots/datasets missing from the stream. Never on the wrong side.
# interrupted receive: `zfs get receive_resume_token <target>`; resume with `zfs send -t <token>`; drop with `zfs receive -A <target>`
```

**Scrub, resilver, health**

```bash
# [docs] zpool-scrub man page; TrueNAS also schedules scrubs (weekly by default) in Data Protection > Scrub Tasks
zpool scrub <pool>            # start; zpool scrub -p <pool> pause; zpool scrub -s <pool> stop
zpool status <pool>           # shows progress, repaired bytes, errors
```

Scrub reads and verifies every block and repairs from redundancy. A scrub and a resilver can't run at once. Run **Scrub Now** from Storage > (pool) Storage Health. **Boot pool** scrub interval is 7 days by default. A pool at `CAP` over about 80% gets slow and fragmented; over 90% is an emergency `[unverified: rule of thumb]`.

**SMART**: 25.10 removed the SMART scheduling UI; old tests were converted to cron tasks and SMART polling continues in the middleware. Verify tests still run (System > Advanced > Cron Jobs), or run the **Scrutiny** app for monitoring `[docs]`. Manual: `smartctl -H /dev/<disk>`, `smartctl -t short /dev/<disk>`, `smartctl -a /dev/<disk>` `[docs]`. `[CORE]` Data Protection > S.M.A.R.T. Tests still exists.

**Import / export** `[docs: zpool-import man page]`. In the UI: Storage > Import Pool / Export-Disconnect (⚠ "destroy data" option is on that dialog).

```bash
# [docs] read-only ways to look at a pool from the CLI
zpool import                              # LIST importable pools only; changes nothing
zpool import -o readonly=on -R /mnt/alt <pool>   # inspect a pool read-only under an alternate root
zpool import -F -n <pool>                 # dry run: could a damaged pool be recovered?
# ⚠ zpool import -f <pool> forces import of a pool that looks in use elsewhere: only if that system is off.
# Do real imports/exports in the UI so the middleware records them.
```

**Disk replacement procedure** (`[docs]`, SCALE UI; CORE is similar `[unverified]`):

1. `zpool status -v <pool>` to identify the failed disk; note its **serial** (Storage > Disks) so you pull the right one. Check that the *other* disks are healthy (`smartctl -H`): a second failure during resilver kills RAIDZ1/2-way mirrors.
2. Storage Dashboard > **View VDEVs** > select the disk > **Offline** (if it fails, run a scrub first and retry).
3. Physically swap it. The new disk must be the **same size or larger** and not part of another pool. Prefer a disk of the same type (avoid SMR for pools).
4. Select the old disk > **Replace** > pick the new one > confirm (TrueNAS wipes it; *Force* only if it holds data you want erased). Resilver starts.
5. Watch `zpool status <pool>` until resilver finishes with 0 errors, then `zpool clear <pool>` only if leftover error counters are stale, then run a scrub.
6. With a hot spare: the spare is already resilvering; detach the failed disk afterwards to avoid a second resilver `[docs]`.

Don't use `zpool replace` on the CLI on TrueNAS unless directed: the UI partitions disks and records device identity the CLI won't `[unverified]`.

## 7. Users, permissions, sudo, secrets

- **Accounts** `[docs]`: `truenas_admin` is the default admin on new installs; root is deprecated and can be disabled. Admin roles: Full, Sharing, Read-only. Sudo is a per-group setting (allowed commands / all commands, with or without password): enable temporarily, then turn it off. SSH login requires the SSH-access and Shell options on the user, plus service settings.
- **API keys** and **2FA** live under Credentials; 26 accepts only 30 or 60 s TOTP intervals `[docs]`.
- **Keys/secrets**: SSH public keys per user; Backup Credentials (Credentials > Backup Credentials) hold cloud and SSH connections for replication/cloud sync. Back up the config with the **password secret seed** exported or those secrets won't decrypt after restore `[docs]`.

### Shares (SMB / NFS / iSCSI)

- **SMB** (Shares > Windows Shares) `[docs]`: create the dataset and share together, choose a **Purpose** preset (Default, Time Machine, Private Dataset, Multi-protocol, External, ...). Never share the pool root. You need a **local user with Samba Authentication** (or Active Directory); **root cannot** access SMB shares. Guest access exists only for legacy shares migrated from before 25.10. Restart the SMB service when prompted.
- **Two permission layers**: the *share ACL* (SMB-level) **and** the *filesystem ACL* (dataset-level). Both must allow the user. Most "permission denied" is one of them.
- **ACL type**: SMB needs **NFSv4** ACLs (the SMB preset sets this); POSIX ACLs are the Generic default. After creating an NFSv4 dataset you must set an ACL. ⚠ **Applying ACLs recursively is destructive**: snapshot first `[docs]`.
- **NFS** (Shares > Unix (NFS)): restrict *Networks/Hosts*; mind `maproot`/`mapall` (root squash). **iSCSI**: needs zvols; sync/space matters (never run the pool near full). Both: keep the service from being exposed beyond the storage network.
- 25.10: recycle bin removed for new shares (use snapshots); AD `AUTORID` idmap backend removed (review ACLs after upgrade) `[docs]`.

```bash
# [unverified] look at ACLs from the shell
getfacl /mnt/<pool>/<dataset>            # POSIX ACL datasets
nfs4xdr_getfacl /mnt/<pool>/<dataset>    # NFSv4 ACL datasets [SCALE]
```

## 8. Updates & upgrade strategy

**Before** `[docs]`:

1. Read the release's version notes (breaking changes). 25.10 examples: AD idmap backend, SMB share presets, NVIDIA driver (Turing+ only), SMART UI removal, Certificate Authority creation removed.
2. **Export the config** (System > Advanced > Manage Configuration) and store it off-box.
3. `zpool status -x` healthy; no scrub or resilver running; snapshots and a real backup exist; UPS is healthy.
4. Do **not** click *Upgrade* on pool feature flags yet.
5. Choose the Update Profile; stay on the recommended stable train (25.10.x). Move one major release at a time `[unverified]`.

**Do it**: System > Update > download and apply; the update creates a **new boot environment** and the system reboots into it.

**After**: check Alerts, Storage (pools healthy), Services, Shares, Apps (all Running), replication/cloud/snapshot tasks, and that SMART/cron tasks exist. Wait a couple of weeks. Only then consider the pool feature upgrade (irreversible, blocks rollback).

**Rollback** `[docs]`: System > Boot > **Activate** the previous boot environment, then reboot. This rolls back the OS, **not** pools you already upgraded. TrueNAS keeps the last two boot environments by default; keep 3 to 4 on production and use **Keep** to protect one. You cannot delete the active one.

**Release moves**: CORE 13 -> SCALE is **one-way**: update CORE to the latest 13.0-U6.x or 13.3 first, follow the CORE-to-SCALE migration guide, expect to rebuild jails/plugins as apps `[docs]`. TrueNAS 26 is beta: do not upgrade production.

## 9. Cleanup / reclaim space

Safe order:

1. `zfs list -o space -r <pool>` and Storage > Snapshots to see where space actually is.
2. Delete old **snapshots** you don't need, dry run first: `zfs destroy -nv <pool>/<dataset>@<snap>` (or in the UI). Deleting the oldest one of a chain frees only blocks unique to it.
3. Unused datasets/zvols/clones you own (UI: Datasets > Delete): ⚠ data is gone.
4. Old boot environments (System > Boot): keep the active one and 2 to 3 previous.
5. Apps you don't use (Apps > Installed > Delete; decide about their data datasets separately).

**Do not delete** `boot-pool` contents, the system dataset (`.system`), the apps dataset (`ix-apps`), or anything under `/mnt/.ix-apps` by hand `[unverified: names]`. Never `rm -rf` inside `/mnt/<pool>` to "free space" on a pool with snapshots.

## 10. Performance & hardware

- **Hardware** `[unverified: community rules of thumb]`: ECC RAM preferred; disks behind an **HBA in IT mode**, not a RAID card; avoid **SMR** drives in pools; more RAM before SLOG/L2ARC; mirrors for IOPS, RAIDZ2 for capacity with safety.
- **Levers**: `compression=lz4/zstd`, `atime=off`, sensible `recordsize`, keep pools under about 80% full, scrub off-peak. ⚠ `sync=disabled` is not a tuning knob.
- **ARC** `[docs]` is RAM-based cache; check `arc_summary`. SCALE ARC defaults have changed across releases: read your release's notes.
- **Auto TRIM**: Storage Health > *Edit Auto TRIM* (SSD pools; may impact performance) `[docs]`.
- **UPS** `[docs: UPS service page not fetchable; details unverified]`: System > Services > UPS. The NAS with the USB/serial link is the *master*; other machines connect as clients. Set the shutdown mode/timer so the NAS powers off cleanly before the battery dies. Test by pulling mains. `upsc <identifier>@localhost` reads status `[unverified]`.
- **GPU** `[docs]`: 25.10 uses open NVIDIA kernel drivers, Turing and newer only. Pascal/Maxwell/Volta are unsupported.

## 11. Security hygiene

Minimum: unique strong admin credentials, root/default-admin passwords disabled, key-only SSH, HTTPS on the UI with a real certificate, only needed services on, storage traffic on a trusted network, updates on the stable train, backups tested.

```bash
# [docs: general] what is listening (SCALE)
sudo ss -tulpn
```

- Services: turn off FTP/Telnet-class services, unused SMB/NFS/iSCSI. SMB: no guest, no root. NFS: allowed networks set.
- Certificates: 25.10 removed CA creation; import a certificate or sign a CSR externally `[docs]`.
- Keep the web UI off the internet. Use a VPN.
- `[SCALE]` update cadence: apply point releases when the docs' Update Profile says your profile should; watch for security advisories.

## 12. Backups & recovery

**Snapshots on the same pool are not a backup.** The 3-2-1 rule applies: a second pool/machine (replication), plus off-site (cloud sync/TrueCloud Backup), plus config export.

| Tool (Data Protection `[docs]`) | Use |
|---|---|
| Periodic Snapshot Tasks | Frequent, cheap local history (15 min is common) |
| Replication Tasks | ZFS send/receive to another pool/box (local or SSH). ⚠ *Destroy stale snapshots on destination* and `-F`-style options delete data: check direction and target |
| Cloud Sync / TrueCloud Backup | File-level copies to object storage / cloud providers |
| Rsync Tasks | Legacy/other rsync targets |
| Config export | System > Advanced > Manage Configuration (include the password secret seed) |

**Restore drill** (do it before you need it): quarterly, restore one dataset from a replica or a snapshot to a scratch dataset (`zfs clone` or `.zfs/snapshot/`), and verify contents. Test the config-restore path on a spare/VM.

**Recovery**: (1) OS dead: reinstall TrueNAS on a new boot device (the boot pool holds no user data), **Storage > Import Pool**, upload the saved config. (2) Encrypted datasets need their keys/passphrases: store them off-box `[docs]`. (3) Pool refuses to import: `zpool import` (list) and read the status; try `-o readonly=on -R /mnt/alt`, and only then a `-F -n` dry run `[docs]`; ask for help before anything destructive. (4) **UI unreachable**: console setup menu to reset the network; roll back to the previous boot environment from the boot menu.

## 13. Developer-environment notes

- **Shell/CLI** `[docs]`: SSH in as the admin user; the **TrueNAS CLI** starts with `cli` (`ls`, `man <cmd>`, `..`, `/`, `--` for the interactive editor; commands are lowercase), also via the UI Shell and the console menu. API: `midclt call <method> [args]` runs middleware calls locally (`midclt call pool.query` lists pools `[docs]`); remote access is the WebSocket API (REST is removed in 26, migrate now).
- **Apps** `[SCALE][docs]`: Docker-based (Kubernetes is gone). Choose an apps pool first. Catalog apps, or Apps > Discover > *Install via YAML* for your own Compose file (name lowercase alphanumeric; TrueNAS validates YAML syntax only, not your config). Storage: **ixVolumes** (TrueNAS creates a dataset) or **host paths** bind-mounted from your datasets. Host paths need the container's UID/GID to have ACL access. Apps upgrade from Apps > Installed. Use an external registry mirror if needed (25.10).
- **VMs** `[SCALE]`: Virtualization menu; TrueNAS 25.10 adds Secure Boot/TPM and disk import/export `[docs]`.
- **Jails/plugins** `[CORE]`: run on `iocage`; documented as **obsolete** with known, unfixable vulnerabilities after FreeBSD 13.2 EOL. Plan a move off; don't expose them.
- **Userland**: `[SCALE]` GNU/Debian (`sed -i`, `stat -c`, `date -d`). `[CORE]` FreeBSD/BSD (`sed -i ''`, `stat -f`, `date -v`, `sockstat`, `gpart`, `camcontrol devlist`, `geom disk list`): scripts that ran on SCALE break here.
- **Clipboard/open**: N/A on the appliance (no desktop). From your workstation: `ssh nas 'zpool status -x' | pbcopy` (macOS) or `| wl-copy` (Wayland) `[verified: arch-local: wl-copy exists]`.
- Don't develop on the NAS. Keep infra-as-code (Compose files, API scripts, replication task JSON) in git elsewhere.

## 14. Gotchas / things that bite

| Trap | Fix |
|---|---|
| `apt install`/`pip install` on SCALE, gone after the next update | Don't. Run software as an App; only boot-environment *core config* is carried forward. |
| Pool changed with `zpool` CLI and the UI doesn't know | Export it and re-import via UI; use the UI for pool changes. |
| Pool imported on two systems (or `import -f` while the other is up) | Corruption risk. Never. Power one off first. |
| Pool **degraded** | Don't reboot repeatedly. `zpool status -v`, check the other disks' SMART, replace via UI (section 6). RAIDZ1 with big disks: a second failure loses the pool. |
| Pool **full** (near 100%): can't write, even delete fails | Destroy snapshots (dry run first), free a reservation you kept as a buffer, then keep usage under about 80%. |
| Deleted files but space did not come back | Snapshots still hold them: `zfs list -o space`, destroy snapshots. |
| **Resilver stuck or very slow** | `zpool status -v`: restarted by errors? failing second disk (SMART)? SMR drive? heavy I/O? Don't offline more disks. Wait; don't pull disks mid-resilver. |
| SMB "permission denied" | User lacks Samba Authentication; share ACL vs filesystem ACL mismatch; POSIX ACL on an SMB dataset (needs NFSv4); root or guest attempt; stale Windows credentials; after 25.10 the AD idmap change. |
| Recursive ACL/permission change wrecked access | ⚠ It is destructive; you should have snapshotted. Roll the dataset back or clone from the snapshot. |
| `zpool upgrade` / UI pool upgrade, then rollback fails | Irreversible; wait weeks after a major before upgrading feature flags. |
| Locked encrypted datasets after reboot: shares/apps down | Unlock (UI) and keep keys off-box; don't lose them. |
| Replication `-F`/"destroy stale snapshots" deleted the backup | Check source/destination; test on a scratch dataset first. |
| Network edit locked you out of the UI | Use **Test Changes** (60 s auto-revert); console setup menu resets it. |
| Boot USB dies | Mirror the boot device; keep a fresh config export. |
| SMART tests silently gone in 25.10 | They became cron tasks: check System > Advanced > Cron Jobs, or use Scrutiny. |
| App can't write its host path | Container UID/GID lacks ACL on the dataset; fix ACL, not `chmod 777`. |
| Pulled the wrong disk | Identify by **serial number** (Storage > Disks) before touching hardware. |
| Running CORE jails/plugins | Obsolete with unfixable iocage vulnerabilities: migrate to SCALE apps. |
| Assuming a 26 beta feature is stable | It is a beta: production stays on 25.10.x. |
| `recordsize`/`compression` change "did nothing" | Only applies to newly written data. |

## 15. Sources

Consulted 2026-09-21. None of these commands were run; the reference machine has no ZFS.

- Release status and notes: https://www.truenas.com/docs/softwarestatus/ , https://www.truenas.com/docs/scale/25.10/gettingstarted/versionnotes/ , https://www.truenas.com/docs/scale/26/gettingstarted/versionnotes/ , https://www.truenas.com/docs/core/13.0/coretutorials/jailspluginsvms/ (CORE virtualization obsolete)
- Boot environments and update behaviour: https://www.truenas.com/docs/scale/25.10/scaleuireference/systemsettings/systembootscreensscale/
- Config export: https://www.truenas.com/docs/scale/25.10/scaletutorials/systemsettings/general/managesysconfigscale/
- Disk replacement, pools: https://www.truenas.com/docs/scale/25.10/scaletutorials/storage/disks/replacingdisks/ , https://www.truenas.com/docs/scale/25.10/scaletutorials/storage/managepoolsscale/
- Permissions/ACL, SMB, admin logins, CLI: https://www.truenas.com/docs/scale/25.10/scaletutorials/datasets/permissionsscale/ , https://www.truenas.com/docs/scale/25.10/scaletutorials/shares/smb/ , https://www.truenas.com/docs/scale/25.10/scaletutorials/credentials/adminroles/ , https://www.truenas.com/docs/scale/24.04/scaleclireference/
- Network Test Changes (search excerpt of https://www.truenas.com/docs/scale/scaletutorials/network/interfaces/), Data Protection: https://www.truenas.com/docs/scale/25.10/scaletutorials/dataprotection/ , Custom apps: https://www.truenas.com/docs/scale/25.10/scaleuireference/apps/installcustomappscreens/
- CORE to SCALE: https://www.truenas.com/docs/scale/24.10/gettingstarted/migrate/migratingfromcore/
- OpenZFS man pages (master): https://openzfs.github.io/openzfs-docs/man/master/8/zpool-status.8.html , `zpool-scrub`, `zpool-replace`, `zpool-attach`, `zpool-import`, `zpool-list`, `zfs-destroy`, `zfs-send`, `zfs-receive`, `zfs-rollback`, `zfs-snapshot`, and https://openzfs.github.io/openzfs-docs/man/master/7/zfsprops.7.html
