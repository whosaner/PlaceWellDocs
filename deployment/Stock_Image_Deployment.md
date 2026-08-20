# Stock artwork deployment

Stock artwork is one logical release published to two targets:

- Firebase Hosting serves the mobile app over HTTPS.
- Linode stores the same manifest bytes and immutable WebPs for local UI and
  QR Service reads.

The paired invariant is strict: Firebase's live `manifest.v1.json` and
`/opt/placewell-stock/current/manifest.v1.json` must have the same SHA-256.
The manifest remains Firebase-oriented and keeps its existing `baseUrl`.
Linode consumers ignore `baseUrl` and resolve each entry's `file` under
`/opt/placewell-stock/current/img/`.

## Operator command

Run the dedicated script from any directory:

```powershell
C:\PlaceWell\Docs\scripts\deploy_stock_images.ps1
```

Validate and rebuild locally without contacting either target:

```powershell
C:\PlaceWell\Docs\scripts\deploy_stock_images.ps1 -ValidateOnly
```

The ordinary server deployment remains unchanged unless stock deployment is
explicitly requested:

```powershell
C:\PlaceWell\Docs\scripts\deploy.ps1 -DeployStockImages
```

That opt-in runs the normal UI/PDF/QR deployment first, then invokes the
dedicated stock script. Any stock failure propagates and prevents the final
deploy-complete message.

## Configuration and prerequisites

Defaults follow `Docs\scripts\deploy.ps1` and the masters repository:

| Setting | Default | Override |
|---|---|---|
| SSH target | `root@45.56.71.137` | `PLACEWELL_DEPLOY_SERVER` or `-Server` |
| Firebase project | `placewell-prod-60ef3` | `PLACEWELL_FIREBASE_PROJECT` or `-FirebaseProject` |
| Masters checkout | `C:\PlaceWell\PlaceWell-StockImageMasters` | `PLACEWELL_STOCK_MASTERS` or `-StockMastersRoot` |

No secret is stored in either script. SSH uses the operator's existing
OpenSSH key/agent or normal SSH authentication. Firebase uses the existing
Firebase CLI login or supported CI authentication environment. Required local
tools are Windows PowerShell 5.1 or newer, Python 3.13.1, `git`, `tar`, `ssh`,
`scp`, `curl.exe`, and the Firebase CLI.

The Linode target assumes AlmaLinux 9 tooling already used by the server:
`bash`, `python3`, GNU coreutils, `tar`, and `restorecon`. The default root SSH
account can provision and atomically activate `/opt/placewell-stock`. A
replacement deployment account needs equivalent write/rename permission and
permission to restore SELinux labels.

## Release layout and permissions

```text
/opt/placewell-stock/
├── current -> releases/<manifest-sha256>
└── releases/
    └── <manifest-sha256>/
        ├── manifest.v1.json
        ├── manifest.v1.json.sha256
        ├── catalog.v1.digest.json
        └── img/
            └── <semantic-name>.<sha256>.webp
```

The lowercase manifest SHA-256 is the release ID. Release directories are
read-only (`0555`) and files are read-only (`0444`). The root and `releases`
directories are traversable (`0755`), so the current root-run services and any
future non-root systemd service users can read them without write access.
Staging, incoming uploads, and the deployment lock are deployment-user-only.

`restorecon -RF /opt/placewell-stock` applies the normal SELinux labels for
files under `/opt`. No Apache `Alias`, static mount, or other public filesystem
exposure is required or permitted; previews remain served through the
authenticated UI. If a future hardened systemd unit adds filesystem sandboxing,
allow read access to `/opt/placewell-stock` with:

```ini
[Service]
ReadOnlyPaths=/opt/placewell-stock
```

Do not add `InaccessiblePaths=/opt` or otherwise hide the stock root from the
UI or QR Service units.

## Deployment transaction

`deploy_stock_images.ps1`:

1. Runs `PlaceWell-StockImageMasters\prepare_release.ps1`.
2. Recomputes the manifest SHA-256/revision and verifies manifest entries,
   every deployment WebP's content hash and byte size, and catalog totals.
3. Acquires the remote `/opt/placewell-stock/.deploy.lock`.
4. Uploads to a unique staging directory, verifies it on Linode, makes it
   read-only, atomically renames it into `releases/<release-id>`, restores
   SELinux labels, and proves the configured UI/QR systemd users can read the
   manifest and a WebP.
5. Deploys a short-lived Firebase preview channel from the masters repository.
6. Downloads and byte-compares the preview manifest/digest metadata, checks the
   revision and headers, and downloads/verifies every deployed WebP.
7. Re-verifies the finalized Linode release and service-user reads.
8. Atomically replaces `current` while retaining a rollback symlink under the
   remote deployment lock.
9. Promotes the verified Firebase preview channel to `live` as the final
   state-changing operation, fully verifies live, then removes the rollback
   state and lock.

Firebase live is never changed before the preview and immutable Linode release
verify. If live promotion definitively remains on the recorded prior release,
the script restores the prior Linode `current` pointer before releasing the
lock. Any preparation, upload, preview, HTTP, digest, revision, size,
permission, or health check failure is nonzero and emits no
deployment-complete message. A finalized but inactive release may remain after
a later failure; it is harmless and can be reused by a retry.

The lock prevents concurrent stock deploys. A killed operator process normally
removes its own lock in cleanup. If the machine or SSH session died before
cleanup, inspect `/opt/placewell-stock/.deploy.lock/info`, confirm no deployment
is running, then remove that stale lock manually. Never remove a live lock.

If the script reports that Firebase promotion is **ambiguous**, it intentionally
leaves the lock, `activation-state`, and rollback symlink in place. Do not remove
them blindly. First compare Firebase live's manifest SHA-256 with `current` and
the rollback target. If Firebase serves the new digest, keep `current` and clear
the recovery artifacts only after the complete live release passes verification;
if Firebase consistently serves the recorded prior digest, restore the rollback
symlink to `current` and then clear the lock. An unknown digest, an unreachable
Firebase endpoint, or a new manifest whose objects or headers fail verification
is not proof that either rollback or finalization is safe.

## Verification

After a successful run:

```powershell
curl.exe https://placewell-prod-60ef3.web.app/stock-images/manifest.v1.json
ssh root@45.56.71.137 "readlink /opt/placewell-stock/current; sha256sum /opt/placewell-stock/current/manifest.v1.json"
```

The Firebase manifest SHA-256, the Linode SHA-256, and the `current` release
directory name must match. UI and QR processes should resolve files as:

```text
/opt/placewell-stock/current/img/<manifest-entry.file>
```

## Rollback or re-activation

Re-activation is also paired. Do not point Linode at a release whose manifest
is not live on Firebase.

1. Choose a retained release under `/opt/placewell-stock/releases/<release-id>`.
2. Verify its directory name equals the manifest SHA-256 and verify its
   manifest revision/object facts.
3. Roll Firebase Hosting back to the matching Hosting release, or redeploy the
   archived deterministic package for that release.
4. Download Firebase's live manifest and confirm its SHA-256 equals the chosen
   Linode release ID.
5. Acquire the same remote deployment lock and atomically replace `current`
   using a temporary symlink and `mv -Tf`.
6. Recheck `readlink`, manifest SHA-256, and consumer readability.

After Firebase is verified at the chosen digest, the server-side reactivation
shape is:

```bash
set -euo pipefail
root=/opt/placewell-stock
release=<64-character-manifest-sha256>
lock="$root/.deploy.lock"
tmp="$root/.current.rollback-manual.$$"
restore_tmp="$root/.current.restore-manual.$$"
had_current=0
old_target=
rollback_needed=0

finish() {
    status=$?
    trap - EXIT
    if [ "$rollback_needed" -eq 1 ]; then
        if [ "$had_current" -eq 1 ]; then
            ln -s "$old_target" "$restore_tmp"
            mv -Tf "$restore_tmp" "$root/current"
        else
            rm -f "$root/current"
        fi
    fi
    rm -f "$tmp" "$restore_tmp"
    rm -rf "$lock"
    exit "$status"
}

mkdir "$lock" || { echo "stock deployment lock is held" >&2; exit 73; }
trap finish EXIT
if [ -L "$root/current" ]; then
    had_current=1
    old_target="$(readlink "$root/current")"
elif [ -e "$root/current" ]; then
    echo "current is not a symlink" >&2
    exit 74
fi

printf '%s\n' "manual rollback to $release" > "$lock/info"

test "$(sha256sum "$root/releases/$release/manifest.v1.json" | awk '{print $1}')" = "$release"
# Confirm the already-downloaded Firebase manifest has this same SHA-256 here.
ln -s "releases/$release" "$tmp"
mv -Tf "$tmp" "$root/current"
rollback_needed=1
test "$(readlink "$root/current")" = "releases/$release"
test "$(sha256sum "$root/current/manifest.v1.json" | awk '{print $1}')" = "$release"
rollback_needed=0
```

If any verification before `mv -Tf` fails, `current` is untouched. A post-move
failure restores the prior symlink before releasing the lock. Prefer the
dedicated deployer whenever the prior deterministic package is available.

Retained releases support pinned in-flight forms and rollback. This initial
implementation never prunes `/opt/placewell-stock/releases` automatically.
Review storage and introduce a separately approved retention policy before
deleting any release or immutable Firebase object.
