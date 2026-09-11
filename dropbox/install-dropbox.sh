#!/usr/bin/env bash
#
# install-dropbox.sh — set up Dropbox's official apt repository and install the
# current package on Ubuntu 24.04 (noble). Replaces the stale 2019 universe build
# and gives you apt-managed updates going forward.
#
# Run with:  sudo bash ~/.dev-env/dropbox/install-dropbox.sh
#
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run with sudo:  sudo bash $0" >&2
  exit 1
fi

KEY_FP="1C61A2656FB57B7E4DE0F4C1FC918B335044912E"   # Dropbox Automatic Signing Key
KEYRING="/usr/share/keyrings/dropbox.gpg"
LIST="/etc/apt/sources.list.d/dropbox.list"
SUITE="noble"

echo ">> [1/4] Fetching and verifying the Dropbox signing key"
tmpkey="$(mktemp)"
trap 'rm -f "$tmpkey"' EXIT
curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x${KEY_FP}" -o "$tmpkey"
got="$(gpg --show-keys --with-colons "$tmpkey" | awk -F: '/^fpr:/{print $10; exit}')"
if [ "$got" != "$KEY_FP" ]; then
  echo "!! Key fingerprint mismatch: got '$got', expected '$KEY_FP'. Aborting." >&2
  exit 1
fi
gpg --dearmor -o "$KEYRING" < "$tmpkey"
chmod 0644 "$KEYRING"
echo "   key installed -> $KEYRING"

echo ">> [2/4] Writing apt source -> $LIST"
echo "deb [arch=amd64 signed-by=${KEYRING}] http://linux.dropbox.com/ubuntu ${SUITE} main" > "$LIST"

echo ">> [3/4] apt update"
apt-get update

echo ">> [4/4] Installing the dropbox package"
# Modern packaging: the 'dropbox' package supersedes 'nautilus-dropbox'
# (Provides/Replaces/Breaks it), so installing it removes any old
# nautilus-dropbox build automatically.
apt-get install -y dropbox

echo
echo "Done. Installed:"
dpkg -l dropbox | tail -1
echo
echo "Next (run these as yourself, NOT root) to refresh the outdated daemon and link your account:"
echo "    dropbox stop 2>/dev/null; rm -rf ~/.dropbox-dist; dropbox start -i"
