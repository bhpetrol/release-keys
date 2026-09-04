#!/usr/bin/env bash
# Verifies RELEASE_KEYS.sig against the root keys in root/ and checks every manifest key exists in keys/.
# Used by CI and by anyone who wants to check a checkout by hand:  scripts/verify.sh
set -euo pipefail
cd "$(dirname "$0")/.."
work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT
export GNUPGHOME="$work"; chmod 700 "$work"
gpg --batch --quiet --import root/*.asc
status="$(gpg --batch --status-fd 1 --verify RELEASE_KEYS.sig RELEASE_KEYS 2>/dev/null || true)"
signer="$(printf '%s\n' "$status" | awk '/^\[GNUPG:\] VALIDSIG/{print toupper($NF)}')"
[ -n "$signer" ] || { echo "RELEASE_KEYS.sig is not a valid signature" >&2; exit 1; }
grep -qix "$signer" root/FINGERPRINTS || { echo "manifest signed by $signer, which is not listed in root/FINGERPRINTS" >&2; exit 1; }
rev="$(awk -F': *' '/^revision:/{print $2}' RELEASE_KEYS)"
[[ "$rev" =~ ^[0-9]+$ ]] || { echo "manifest has no numeric revision" >&2; exit 1; }
gpg --batch --quiet --import keys/*.asc
missing=0
while read -r fpr status_ projects holder; do
  [ -n "$fpr" ] || continue
  gpg --batch --list-keys "$fpr" >/dev/null 2>&1 || { echo "manifest lists $fpr ($holder) but keys/ has no such public key" >&2; missing=1; }
done < <(grep -vE '^\s*(#|revision:|updated:|$)' RELEASE_KEYS)
[ "$missing" = 0 ]
echo "OK: manifest revision $rev signed by root key $signer; all listed keys present"
