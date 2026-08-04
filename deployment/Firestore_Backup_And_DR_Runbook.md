# PlaceWell — Firestore Backup & Disaster Recovery Runbook

> **Do this once.** It protects against the single worst data-loss scenario: if the
> `qr_codes` collection (or the whole Firestore database) is ever deleted, every
> **not-yet-activated physical label becomes un-onboardable and CANNOT be
> regenerated** — real label IDs are random and exist only in Firestore.

## Why this is critical

- Real label IDs are generated with `secrets.choice()` (see
  `PlaceWellQRService/app/label_id.py`) and written **only** to Firestore `qr_codes`
  (document ID = the label ID, set in `app/allocate.py`).
- They are **not derived from anything**, so a deleted record cannot be recomputed.
  Generating fresh IDs produces *different* codes that will not match the QR already
  **printed on the physical label**.
- Impact of losing `qr_codes`:
  | Who / flow | Effect |
  |---|---|
  | User whose label is already set up | ✅ Unaffected — content lives on-device; re-scans are fully offline |
  | In-app scan of a *new* (not-yet-setup) label | ⚠️ Still opens, but as a **blank** (no name/category/location pre-fill) |
  | Camera/browser scan by a new user (no app yet) | ❌ Landing page returns 404 "That's not a PlaceWell code" (`app/scan.py`) — breaks onboarding |
  | Order-QR bulk import | ❌ "Order Not Found" |
  | Scan counts / order records | ❌ Lost (anti-counterfeit signal resets; order links gone) |
- Demo fixtures (`PWMSP2`…) are re-seedable via `PlaceWellQRService/scripts/seed_test_fixtures.py`.
  **Real customer labels are not.**

## Environment

| Property | Value |
|---|---|
| GCP project | `placewell-prod-60ef3` |
| Firestore database | `(default)` |
| Location | `us-central1` |
| Collections | `qr_codes`, `orders` |
| Service account | `firebase-adminsdk-fbsvc@placewell-prod-60ef3.iam.gserviceaccount.com` |
| Console | https://console.firebase.google.com → Firestore → **Backups** |

## Prerequisites

- **Easiest:** open **Cloud Shell** (gcloud pre-installed and already authenticated) —
  https://console.cloud.google.com → the terminal icon (top-right). No install needed.
- Or install the Google Cloud CLI on Windows, then `gcloud auth login`.
- Point the CLI at the project:
  ```bash
  gcloud config set project placewell-prod-60ef3
  ```
- These steps need Owner/Editor (or `roles/datastore.owner`). The account that owns the
  Firebase project already has this.

---

## Step 1 — Enable Point-in-Time Recovery (PITR)  · 7-day continuous safety net

Console: Firestore → **Backups** → turn on **Point-in-time recovery**.

```bash
gcloud firestore databases update --database='(default)' --enable-pitr
# verify (expect POINT_IN_TIME_RECOVERY_ENABLED)
gcloud firestore databases describe --database='(default)' --format="value(pointInTimeRecoveryEnablement)"
```

Gives you: read/restore data as it existed at **any minute in the last 7 days** (any
second in the last hour). Perfect for "someone deleted records 20 minutes ago."

## Step 2 — Create scheduled backups  · managed, restorable to a new DB

```bash
# daily, keep 7 days
gcloud firestore backups schedules create --database='(default)' --recurrence=daily --retention=7d

# weekly (Sunday), keep 14 weeks (the maximum)
gcloud firestore backups schedules create --database='(default)' --recurrence=weekly --day-of-week=SUN --retention=14w

# verify
gcloud firestore backups schedules list --database='(default)'
gcloud firestore backups list --location=us-central1
```

If the CLI rejects a retention value, lower it — daily max is 7 days, weekly max is 14 weeks.

## Step 3 — Turn on database delete-protection  · stops accidental DB deletion

```bash
gcloud firestore databases update --database='(default)' --delete-protection
# verify (expect DELETE_PROTECTION_ENABLED)
gcloud firestore databases describe --database='(default)' --format="value(deleteProtectionState)"
```

## Step 4 (optional) — Off-site export to Cloud Storage  · an extra copy you own

```bash
# one-time bucket (same region)
gcloud storage buckets create gs://placewell-prod-firestore-backups --location=us-central1 --uniform-bucket-level-access

# manual export (all collections)
gcloud firestore export gs://placewell-prod-firestore-backups --database='(default)'

# or just the important collections
gcloud firestore export gs://placewell-prod-firestore-backups --database='(default)' --collection-ids=qr_codes,orders
```

Automate later with Cloud Scheduler → a small Cloud Function/HTTP job, or a weekly cron on
the Linode box (it already holds the service-account key). Automated exports need the SA to
have `roles/datastore.importExportAdmin` plus write access to the bucket:

```bash
gcloud projects add-iam-policy-binding placewell-prod-60ef3 \
  --member="serviceAccount:firebase-adminsdk-fbsvc@placewell-prod-60ef3.iam.gserviceaccount.com" \
  --role="roles/datastore.importExportAdmin"
```

## Step 5 — Second, independent copy: keep your allocations  · belt-and-suspenders

Firestore is one source of truth; keep a second one **outside** Firestore:

- `/api/qr/allocate` returns every `{item_id, qr_url}`, and the Operator UI / order
  pipeline already knows each label's name / category / SKU.
- Generated PDFs already land in `/opt/placewell-ui/output/` on the Linode server — they
  contain the real printed URLs (i.e. the label IDs).
- **Action:** back up `/opt/placewell-ui/output/` and any order log **off** the server
  (e.g. into the same GCS bucket). From these you can **re-seed Firestore with the same
  IDs** if all else fails.

---

## How to RESTORE (when something is lost)

| Scenario | Recovery |
|---|---|
| Records/collection deleted, DB still exists, <7 days ago | Export from PITR at a good timestamp, then import (below) |
| Records/collection deleted, you have an export | `gcloud firestore import gs://…/<EXPORT_FOLDER> --database='(default)'` |
| Whole `(default)` DB deleted | `gcloud firestore databases restore` from a scheduled backup into a **new** DB, then repoint the service |
| No Firestore backup at all | Re-seed from retained allocation data / PDFs (same IDs) — the only way to match printed labels |

**PITR export + import** (restore data as it was 30 min ago; use RFC3339 UTC):
```bash
gcloud firestore export gs://placewell-prod-firestore-backups/pitr-restore \
  --database='(default)' --snapshot-time=2026-08-04T11:30:00Z
gcloud firestore import gs://placewell-prod-firestore-backups/pitr-restore \
  --database='(default)'
```

**Restore a scheduled backup to a throwaway DB** (safe to test):
```bash
gcloud firestore backups list --location=us-central1
gcloud firestore databases restore \
  --source-backup=projects/placewell-prod-60ef3/locations/us-central1/backups/<BACKUP_ID> \
  --destination-database=placewell-restore-test
```

## Do this once: a restore DRILL

Before you ever need it, run the "restore to a throwaway DB" step once and confirm
`qr_codes` / `orders` come back. **A backup you have never restored is not a backup.**
Delete the throwaway DB afterwards.

## Notes / caveats

- PITR window is 7 days; scheduled backups extend coverage (7 days daily + 14 weeks weekly).
- `gcloud firestore databases restore` creates a **new** database; `gcloud firestore import`
  merges into an **existing** one.
- Keep at least one copy in a **different bucket/project** you control, in case the whole
  project is ever compromised.
- Re-check exact flags with `gcloud firestore backups schedules create --help` as the CLI evolves.
