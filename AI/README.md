# PlaceWell AI Context

This folder contains sanitized, upload-ready context for external AI tools such
as ChatGPT. It is intended for product, business, architecture, UX, planning,
and implementation discussions without exposing operational secrets.

## Recommended upload

For most conversations, upload:

1. `PLACEWELL_CHATGPT_CONTEXT.md`
2. Paste the contents of `STARTER_PROMPT.txt` as the first message

Add one authoritative specialist document only when the task needs it:

| Task | Optional additional document |
|---|---|
| Architecture or integration | `Docs\architecture\System_Overview.md` |
| Product planning or prioritization | `Docs\roadmap\ROADMAP.md` |
| Mobile release work | The latest version folder under `Docs\release\store-listing\` |
| Visual/UX work | `Docs\design\Design_System.md` |
| Scan landing behavior | `Docs\specs\PlaceWell_Scan_Landing_Spec.md` |

The context packet identifies dated facts and known uncertainties. Do not ask
an AI assistant to silently treat an old release checklist or roadmap snapshot
as current.

## Never upload

Do not upload or paste:

- `.env` or `.env.*` files
- EAS, HMAC, lookup, allocation, API, or signing secret values
- Service-account JSON files
- Certificates, signing keys, provisioning profiles, or keystores
- Server credentials, SSH keys, or password files
- Customer/order exports or production Firestore records
- Financial records from `Docs\Finances`
- `PlaceWellApp\PRE_BUILD_COMMANDS.txt` (it contains secret reference values)
- Deployment files that contain credentials or private operational details

The public QR URL format and public app/store URLs are safe to discuss. Secret
values used to sign or authorize those URLs are not.

## Maintenance

`Docs\context\PLACEWELL_CONTEXT.md` remains the canonical internal orientation
document. This folder is the sanitized external-AI handoff.

When PlaceWell changes materially:

1. Update the canonical context.
2. Update `PLACEWELL_CHATGPT_CONTEXT.md`.
3. Change the snapshot date.
4. Recheck all release-status claims against live stores or store consoles.
5. Search the packet for credentials, private customer data, and stale version
   references before sharing it.
*** End of File
