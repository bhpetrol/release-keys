# bhpetrol/release-keys

Public keys of the people allowed to sign production release tags for BHPetrol projects, plus a **root-signed
manifest** saying which keys are currently trusted. Deploy scripts (e.g. `scripts/deploy.sh` in `bhpetrol/contest`)
clone this repository at deploy time and accept a release tag only if:

1. `RELEASE_KEYS.sig` is a valid signature over `RELEASE_KEYS` by a **root key** whose fingerprint is pinned in the
   deploy script (`root/FINGERPRINTS` lists them; the public keys are in `root/`);
2. the manifest `revision` is not older than the last one that deploy host verified (anti-rollback);
3. the tag is signed by a key that the manifest lists as `active` for that project.

Nothing on a deploy host needs to change when release managers join or leave — only this repository and its root
signature do. Adding a key without the root key, or replaying an old manifest, is refused.

## Layout

| Path | Purpose |
|------|---------|
| `RELEASE_KEYS` | Manifest: `revision`, `updated`, then one line per key: `fingerprint status projects holder` |
| `RELEASE_KEYS.sig` | Detached ASCII signature over `RELEASE_KEYS` by a root key |
| `keys/<name>.asc` | Public key of each release manager |
| `root/<name>.asc`, `root/FINGERPRINTS` | Root key public halves and their fingerprints (informational; deploy scripts pin the fingerprints) |
| `scripts/verify.sh` | Verifies signature, revision and key presence (run in CI on every push/PR) |
| `scripts/sign-manifest.sh` | Root holders: bump revision, refresh date, re-sign |

## Adding a release manager

1. Manager: `gpg --armor --export <fingerprint> > keys/<name>.asc`, add a line to `RELEASE_KEYS` with
   `status=active` and the projects they may release, open a PR.
2. Root-key holder: review, then `scripts/sign-manifest.sh <root-fingerprint>` on the PR branch (bumps `revision`,
   re-signs), push, merge. CI must be green (`scripts/verify.sh`).

## Revoking a key

Set its `status` to `revoked` (keep the line and the `.asc` so history stays verifiable), re-sign with
`scripts/sign-manifest.sh`, merge. Deploy hosts refuse tags signed by that key from their next deploy onwards.
Because every host records the highest manifest revision it has seen, an attacker cannot replay a manifest that
predates the revocation.

## Rotating a root key

Add the new root public key to `root/` and its fingerprint to `root/FINGERPRINTS`, sign the manifest with the new
key, then update the pinned fingerprint list in each project's deploy script (both fingerprints can be pinned during
the overlap) and finally remove the old key.

## Repository protection (settings owned by the organisation admins)

`main` is protected: pull requests only, review required from `@bhpetrol/release-key-owners` (CODEOWNERS), signed
commits required, no force-push, `verify manifest` check required.
