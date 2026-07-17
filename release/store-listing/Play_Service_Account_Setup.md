# Play Service Account Setup for EAS Submit

Use this guide when `eas submit --platform android` fails with a Google Play service-account permission error.

## What must be connected

Automated Play submission needs two permission layers:

1. **Google Cloud API enablement** — the Cloud project that owns the service account must have the Google Play Android Developer API enabled.
2. **Google Play Console access** — the service account must be invited or linked in Play Console with enough app-level permissions for `com.placewell.app`.

Both layers are required. Enabling the API alone is not enough, and Play Console access alone will still fail if the API is disabled.

## Service account details

- **Google Cloud project number:** 670747107857
- **Service account:** eas-submit-play-store@placewell-prod-60ef3.iam.gserviceaccount.com
- **Android package:** com.placewell.app

## Step 1 — Enable the Google Play Android Developer API

1. Open Google Cloud Console.
2. Switch to the project with project number **670747107857**.
3. Go to **APIs & Services → Library**.
4. Search for **Google Play Android Developer API**.
5. Open it and click **Enable**.
6. Confirm the service account still exists under **IAM & Admin → Service Accounts**.

## Step 2 — Grant Play Console permissions

Preferred path:

1. Open Google Play Console.
2. Go to **Users and permissions**.
3. Click **Invite new user**.
4. Enter:
   `eas-submit-play-store@placewell-prod-60ef3.iam.gserviceaccount.com`
5. Grant app access for **PlaceWell / com.placewell.app**.
6. Assign either:
   - **Release Manager** for the app, or
   - **Admin** if Release Manager is not sufficient for your workflow.
7. Ensure the role can create/edit releases and upload app bundles.
8. Send the invite and confirm it appears as active/accepted if Play Console shows that state.

Alternative path, if available:

1. In Play Console, go to **Setup → API access**.
2. Link the Cloud project if it is not already linked.
3. Grant the same service account access to **com.placewell.app**.
4. Assign **Release Manager** or **Admin** permissions.

## Known Play Console issue

Some Play Console accounts cannot access the **API access** page or see incomplete API-access controls. If that page is unavailable, use **Users and permissions → Invite new user** instead. Inviting the service account directly is the practical workaround.

## Step 3 — Retry EAS submit

From the app project, retry:

```powershell
eas submit --platform android
```

If submission still fails, confirm:

- The API is enabled in the Cloud project numbered **670747107857**.
- The service account email is exact.
- The service account has app access to **com.placewell.app**.
- The role includes release creation and app-bundle upload permissions.
- The Play app exists and the package name matches **com.placewell.app**.

## Fallback — manual AAB upload

If automated submit remains blocked:

1. Open the EAS build page for the Android production build.
2. Download the `.aab` artifact.
3. Open Google Play Console.
4. Choose **PlaceWell / com.placewell.app**.
5. Go to the target track, such as **Testing** or **Production**.
6. Click **Create new release**.
7. Upload the downloaded AAB.
8. Add release notes.
9. Save, review, and roll out according to the selected track.
