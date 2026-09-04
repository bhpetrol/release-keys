#!/usr/bin/env bash
# Root-key holders only: bump the revision, refresh the date and re-sign RELEASE_KEYS.
# Usage: scripts/sign-manifest.sh <root-key-fingerprint>
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="${1:?usage: sign-manifest.sh <root-key-fingerprint>}"
grep -qix "$ROOT" root/FINGERPRINTS || { echo "$ROOT is not listed in root/FINGERPRINTS" >&2; exit 1; }
rev="$(awk -F': *' '/^revision:/{print $2}' RELEASE_KEYS)"
next=$((rev + 1))
sed -i.bak -e "s/^revision: .*/revision: $next/" -e "s/^updated: .*/updated: $(date +%F)/" RELEASE_KEYS && rm -f RELEASE_KEYS.bak
gpg --batch --yes --armor --detach-sign --local-user "$ROOT" -o RELEASE_KEYS.sig RELEASE_KEYS
scripts/verify.sh
echo "revision $rev -> $next; commit RELEASE_KEYS and RELEASE_KEYS.sig together"
