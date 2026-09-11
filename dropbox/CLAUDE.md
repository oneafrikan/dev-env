# CLAUDE.md — dropbox/

## Purpose

Set up Dropbox on Ubuntu via its **official apt repository** (so it stays current via
`apt`), replacing the stale `nautilus-dropbox` build from Ubuntu's universe repo.

## Conventions

- The apt-level steps need `sudo`; the daemon refresh + account linking run as the
  normal user (never root — those write into `~/.dropbox-dist` / `~/Dropbox`).
- Repo: `http://linux.dropbox.com/ubuntu noble main`, keyring at
  `/usr/share/keyrings/dropbox.gpg` using the modern `signed-by` method.
- Signing key fingerprint: `1C61A2656FB57B7E4DE0F4C1FC918B335044912E`.

## Scripts

| Name               | Status      | Description                                              |
|--------------------|-------------|---------------------------------------------------------|
| install-dropbox.sh | implemented | Add Dropbox apt repo + GPG key, install/upgrade package |

## Usage

```bash
sudo bash ~/.dev-env/dropbox/install-dropbox.sh
# then, as yourself, to refresh the daemon and link your account:
dropbox stop 2>/dev/null; rm -rf ~/.dropbox-dist; dropbox start -i
```
