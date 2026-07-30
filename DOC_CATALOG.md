# PlaceWell Documentation Catalog

Use this catalog when you know the task but not which PlaceWell document to open. Paths are relative to `C:\PlaceWell`. Start with the quick-reference table, then jump to the category that matches your work.

## Quick reference — common task to document

| If you want to... | Read first |
|---|---|
| Check out every repo from scratch | `Docs\setup\Project_Checkout_Guide.md` |
| Set up one local project | `Docs\setup\App_Setup.md`, `QRService_Setup.md`, `PdfGenerator_Setup.md`, or `UI_Setup.md` |
| Deploy QR service/UI/PDF code to Linode | `Docs\scripts\deploy.ps1` (one-shot), or `Docs\deployment\Server_Reference.md` + `Linode_Deployment.md`/`UI_Deployment.md` |
| Build or submit the mobile app | `Docs\release\iOS_Android_Build_Guide.md` and `PlaceWellApp\PRE_BUILD_COMMANDS.txt` |
| Manually validate a release | `Docs\release\Release_Validation_Checklist.md` and `PlaceWellApp\VERIFICATION_CHECKLIST.txt` |
| Understand system architecture and deep links | `Docs\architecture\System_Overview.md` |
| Understand scan landing page states | `Docs\specs\PlaceWell_Scan_Landing_Spec.md` |
| Run Maestro E2E tests (one command) | `Docs\maestro\Maestro_Setup_Guide.md`; `PlaceWellApp\scripts\maestro\README.md` (`npm run maestro`); `Docs\scripts\run-maestro.ps1` |
| Regenerate test QR codes/fixtures, or make correctly-signed demo QR PNGs | `Docs\scripts\seed-test-fixtures.ps1` (one-shot wrapper, pass your prod HMAC secret); `PlaceWellQRService\scripts\README.md` (`seed_test_fixtures.py`) |
| Run unit tests (app Jest + QR service pytest) | `Docs\scripts\run-tests.ps1` |
| Add a new label category | `Docs\setup\Adding_A_Category.md` |
| Generate PDFs or export label PNGs | `PlaceWellPdfGenerator\README.md` and `PlaceWellPdfGenerator\LABEL_EXPORT_WIKI.md` |
| Find the Android SHA-256 fingerprint process | `Docs\release\Release_Validation_Checklist.md` and `PlaceWellApp\PRE_BUILD_COMMANDS.txt` |

## Getting started and local setup

| Document | What it covers | Look here if you want to... | Key contents |
|---|---|---|---|
| `Docs\setup\Project_Checkout_Guide.md` | Full from-scratch setup for the multi-repo PlaceWell workspace. Covers prerequisites, clone commands, local setup, untracked secrets, and deployment quick references. | Build a new machine; clone every repo; learn which files are not in git. | Prerequisites; verified remotes/branches; per-project install/run/test; secret files; EAS build/submit; `deploy.ps1`. |
| `Docs\setup\App_Setup.md` | Mobile app setup for the Expo/React Native project. | Install app dependencies, run Expo locally, run Jest, or configure app secrets. | Node/EAS prerequisites; `npm install --legacy-peer-deps`; app secrets; `npx expo start`; tests; Maestro workspace; Firebase Analytics activation. |
| `Docs\setup\QRService_Setup.md` | Local setup for the FastAPI QR service. | Run the allocation/lookup/scan service locally or configure its `.env`. | Python venv; `pip install`; `.env` values; `uvicorn app.main:app --reload`; links to deployment and architecture docs. |
| `Docs\setup\PdfGenerator_Setup.md` | Local setup for the PDF generator library. | Recreate the PDF generator venv or run a standalone generator smoke test. | Python prerequisites; install commands; standalone generator command; integration with PlaceWellUI. |
| `Docs\setup\UI_Setup.md` | Local setup for the FastAPI operator web UI. | Run the internal label-order UI locally or configure QR/PDF paths. | Python venv; dependencies; `.env`; `uvicorn` on port 8080; links to UI deployment. |
| `Docs\setup\Admin_Setup.md` | Setup notes for PlaceWellAdmin tooling. | Work with the admin project/folder assumption or understand what admin manages. | Prerequisites; install/run; expected folder location; managed data areas; related docs. |
| `PlaceWellApp\README.md` | Short app quick start and links into central docs. | Quickly remember the app install/start commands. | `npm install --legacy-peer-deps`; `npx expo start`; links to setup, overview, design, release, and roadmap docs. |
| `PlaceWellQRService\README.md` | Short QR service quick start and documentation hub. | Recreate the service venv and launch the API quickly. | Venv creation; requirements install; `.env` copy; `uvicorn`; links to QR setup, architecture, deployment. |
| `PlaceWellPdfGenerator\README.md` | Short PDF generator quick start and docs hub. | Install and run the generator module. | Venv creation; requirements; `python -m placewell_generator.generator`; links to PDF setup and UI docs. |
| `PlaceWellUI\README.md` | Short UI quick start and documentation hub. | Start the operator UI locally. | Venv creation; requirements; `.env`; `uvicorn app.main:app --host 127.0.0.1 --port 8080 --reload`; links to setup/deployment. |

## Architecture and project context

| Document | What it covers | Look here if you want to... | Key contents |
|---|---|---|---|
| `Docs\architecture\System_Overview.md` | End-to-end architecture across app, QR service, UI, PDF generator, Firestore, and hosted routes. | Understand how orders, QR codes, scan links, deep links, and analytics connect. | Ecosystem overview; production flow; scan/recall flow; project relationships; QR URL format; Firestore `qr_codes`/`orders`; analytics. |
| `Docs\context\PLACEWELL_CONTEXT.md` | Broad product, business, brand, and technical context for PlaceWell. | Get oriented before making product/technical decisions. | Product definition; QR decisions; brand palette/type; MVP products; Etsy/B2B go-to-market; tech stack; roles; closed decisions; next steps. |
| `PlaceWellApp\PLACEWELL_CONTEXT.md` | App-local copy of the complete PlaceWell context. | Work inside PlaceWellApp with the same business/technical grounding. | Same major topics as central context: product, QR, brand, product line, GTM, stack, decisions, work style. |
| `PlaceWellApp\docs\overview\App_Overview.md` | App-specific architecture, MVP requirements, QR/deep-link strategy, and setup. | Understand mobile screens, label data, app flow, and app project structure. | Project summary; architecture; label data model; QR format; validation/deep links; MVP screens; setup; tests; key source areas. |
| `PlaceWellApp\AGENTS.md` | Instructions for coding agents working in the app repo. | Delegate or perform app work while following repo-specific rules. | Quick facts; user collaboration rules; topical guides; hard rules. |
| `PlaceWellApp\agents\conventions.md` | App coding conventions. | Match existing file layout, theme token, component, comment, test, import, and git conventions. | File layout; theme tokens; component style; comments; tests; imports; git; non-conventions. |
| `PlaceWellApp\agents\workflow.md` | Collaboration workflow for user-facing app changes. | Plan, discuss, execute, document, and hand off app work safely. | Feedback-plan-approval-execute flow; question strategy; issue presentation; commits; docs updates; self-review checklist. |
| `PlaceWellApp\agents\gesture-stack.md` | React Native gesture responder guidance. | Fix bottom sheets, dropdowns, touchables, or scroll gesture conflicts. | Responder conflict model; symptom/cause cheat sheet; canonical bottom-sheet recipe; platform notes; anti-patterns. |
| `PlaceWellApp\agents\ux-patterns.md` | Reusable PlaceWell app UX implementation patterns. | Implement pickers, grouped lists, photo steps, inline add-new inputs, or apply-all defaults consistently. | Bottom-sheet picker; grouped BulkImport lists; photo step; add-new above keyboard; navigation state sync; apply-all/global defaults. |

## Deployment and server operations

| Document | What it covers | Look here if you want to... | Key contents |
|---|---|---|---|
| `Docs\deployment\Server_Reference.md` | Day-to-day Linode server reference. | Check routes, service names, file locations, env vars, update commands, logs, or troubleshooting. | Server summary; public routes/internal services; systemd services; file paths; service management; update quick refs; env vars; Firestore; DNS; troubleshooting. |
| `Docs\deployment\Linode_Deployment.md` | Full first-time Linode deployment guide for the QR service and Apache/SSL stack. | Build a new server or understand the original provisioning flow. | Linode provisioning; DNS; Apache/firewall; FastAPI files; Firebase key; `.env`; venv; systemd; reverse proxy; Let's Encrypt; verification; update commands. |
| `Docs\deployment\UI_Deployment.md` | Full deployment guide for the operator UI on Linode. | Deploy or repair the web UI, Apache password protection, reverse proxy, and UI service. | Copy files; Python env; UI `.env`; manual run; systemd; Apache Basic Auth; reverse proxy; verification; code/CSV updates; commands; server paths. |
| `Docs\scripts\deploy.ps1` | One-shot PowerShell deploy script. Packages QR Service + PDF Generator + UI, uploads via scp, extracts on Linode, and restarts services. | Push local server-side code changes to Linode in a single command (does NOT deploy the mobile app). | Stages UI/PDF/QR into tarballs; `scp` to `root@45.56.71.137`; ssh extract to `/opt/placewell-ui` and `/opt/placewell-service`; `systemctl restart`; cleanup. Uses absolute paths — run from anywhere. |

## Build, release, and validation

| Document | What it covers | Look here if you want to... | Key contents |
|---|---|---|---|
| `Docs\release\iOS_Android_Build_Guide.md` | Production EAS build and submit process for iOS and Android. | Install EAS, configure Firebase files, build both platforms, submit builds, or answer EAS prompts. | EAS one-time setup; Firebase iOS/Android setup; App Store Connect; pre-build checklist; iOS build/submit; Android build/submit; build both; routine updates; key files. |
| `Docs\release\Release_Validation_Checklist.md` | App Store / Play Store readiness checklist. | Validate release assets, accounts, analytics, security, tooling, builds, and Android App Links. | Assets; account/config; Firebase Analytics; security; build tooling; pre-build validation; iOS/Android phases; SHA-256 fingerprint retrieval; assetlinks/AASA locations; current status. |
| `PlaceWellApp\VERIFICATION_CHECKLIST.txt` | Manual app and server verification checklist for a build. | Test scanner/deep-link flows, label setup, bulk import, home, server landing page, and regressions before release. | Camera scan without/with app; in-app scanner; label setup/detail/recall; BulkImport; home; scan landing page; regressions; known issues. |
| `PlaceWellApp\PRE_BUILD_COMMANDS.txt` | Operational pre-build command reference. Contains sensitive secret values. | Prepare EAS secrets, sync server/app secrets, deploy scan landing changes, rebuild, submit, or fix App Links. | EAS secret commands; Linode `.env`; server restart/deploy; build/submit; reference secret values; lookup-secret mismatch fix; App Links SHA-256 instructions. |
| `PlaceWellApp\NEXT_STEPS.txt` | Current short action plan for the app build/release flow. | See the immediate build, submit, Android manual upload, install, and verification sequence. | Build both platforms; submit iOS; manually upload Android AAB; install internal test; use verification checklist; summary of recent scanner/deep-link fixes. |
| `PlaceWellApp\docs\release\Release_Validation_Checklist.md` | App-repo copy of the release validation checklist. | Validate release readiness while working inside PlaceWellApp. | Same release phases as central checklist: assets, accounts, analytics, security, tooling, pre-build, iOS/Android, SHA-256/App Links. |

## Testing and E2E automation

| Document | What it covers | Look here if you want to... | Key contents |
|---|---|---|---|
| `Docs\maestro\Maestro_Setup_Guide.md` | Practical Maestro E2E setup and usage guide. | Install Maestro, run smoke/regression flows, create scenarios, configure test data, or troubleshoot. | Java 17; Maestro CLI; Android emulator/APK; smoke/single/regression/watch commands; scenario generator; folder structure; test data; `MAESTRO_TEST_MODE`; iOS; CI/CD; troubleshooting. |
| `Docs\maestro\Maestro_Implementation_Plan.md` | Detailed plan for comprehensive Maestro test coverage. | Design or expand the E2E suite, add testIDs, define scenarios, or plan CI. | Codebase observations; scenario table; workspace layout; CLI install; test data strategy; env vars; testID additions; full scenario catalog; scenario generation; CI rollout; risks. |
| `PlaceWellApp\scripts\maestro\README.md` | The Node runner/generator tooling behind `npm run maestro`. | Run tests end to end with one command, or understand the `.maestro` (flows) vs `scripts/maestro` (tooling) split. | `run-maestro.mjs` orchestrator (CLI/device/app-install/seed/run steps); `run-smoke.mjs`; `seed-fixtures.mjs`; `derive-env.mjs`; scenario generator; npm scripts; `builds/` drop folder; bundletool `.aab` install; auto-start emulator. |
| `PlaceWellQRService\scripts\README.md` | The repeatable test-fixture QR seeder (`seed_test_fixtures.py`). | Regenerate the deterministic test labels + order in Firestore after deletion, or get the `PW_*` deep-link URLs for Maestro. | Fixed-ID fixtures; `--dry-run`/`--env-out`/`--qr-images`; idempotent Firestore upsert; signatures via the server HMAC secret; runs as a host init step before `maestro test`. |
| `Docs\scripts\run-maestro.ps1` | PowerShell entry that wraps `npm run maestro`. | Run Maestro tests without typing npm commands (interactive menu or direct passthrough). | `cd`s into the sibling PlaceWellApp repo; menu (smoke/screenshots/regression/seed-only/custom); forwards args; execution-policy note. |
| `Docs\scripts\run-tests.ps1` | PowerShell runner for the projects' unit tests. | Run all unit suites (or one project) and get a per-project pass/fail summary. | PlaceWellApp Jest + PlaceWellQRService pytest; skips PdfGenerator/UI (empty test dirs); per-project venv detection; `.\run-tests.ps1 [app\|qrservice\|pdf\|ui]`; execution-policy note. |
| `Docs\scripts\seed-test-fixtures.ps1` | PowerShell wrapper for the QR fixture seeder that passes your production HMAC secret so signatures are valid. | Generate correctly-signed demo QR codes/URLs for App Store & Play review, or seed/regenerate the deterministic test labels in Firestore. | Passes `-HmacSecret` to `seed_test_fixtures.py` as `PLACEWELL_HMAC_SECRET` (child process only, restored afterwards); `-DryRun` (no Firestore writes), `-QrImages -Out <dir>`, `-EnvOut`; forwards extra args after `--`; resolves sibling `PlaceWellQRService`; fixed/deterministic fixture IDs; execution-policy note. |

## Features and specifications

| Document | What it covers | Look here if you want to... | Key contents |
|---|---|---|---|
| `Docs\features\ScanToRecall.md` | Scan-to-Recall product spec and developer guide. | Build or modify freshness tracking, recall screens, shelf-life logic, or scan flows. | Intent; locked/open decisions; data model; shelf-life table; freshness/burn-rate logic; flows; auto-save; cross-platform notes; acceptance criteria; source files; backend requirements; tests; phases. |
| `Docs\specs\PlaceWell_Scan_Landing_Spec.md` | Requirements for the public scan landing page. | Understand landing-page states, platform detection, App Links/AASA requirements, or server-side QR resolution. | Purpose/non-goals; route; deep-link mechanism; hosting files; server resolution; state matrix; platform detection; configurable surfaces; Firestore additions; state copy; design; acceptance criteria; open items. |
| `Docs\setup\Adding_A_Category.md` | Cross-project guide for adding a new content category. | Add a new label category across UI, QR service, PDF generator, and app. | Architecture; UI category config and CSV; dimensions; QR allocation/lookup; PDF rendering; app label config; placeholder illustrations; QR client; checklist; file reference. |
| `PlaceWellApp\docs\features\ScanToRecall.md` | App-repo copy of the Scan-to-Recall spec/developer guide. | Work on Scan-to-Recall from inside the app repo. | Same spec/developer sections as central feature doc: data model, shelf life, flows, source files, backend requirements, tests. |
| `PlaceWellApp\docs\setup\Adding_A_Category.md` | App-repo copy of the cross-project category guide. | Add new categories while working in the app repo. | Same cross-project category flow: UI config/CSV, QR service, PDF generator, app config/placeholders/client, checklist. |

## Design and UX

| Document | What it covers | Look here if you want to... | Key contents |
|---|---|---|---|
| `Docs\design\Design_System.md` | PlaceWell visual system and UI rules. | Apply colors, typography, spacing, glass styling, navigation, home layout, or cross-platform design constraints. | Porcelain Sky palette; background; frosted glass without `expo-blur`; typography/wordmark; spacing/radius; navigation; home screen; scan tab button; installed packages; phase status; cross-platform rules; do-not-change list. |
| `PlaceWellApp\docs\design\Design_System.md` | App-repo copy of the design system. | Reference design rules while editing app screens/components. | Same design topics as central design doc: palette, typography, glass, spacing, navigation, home, scan button, platform rules. |

## Roadmap and planning

| Document | What it covers | Look here if you want to... | Key contents |
|---|---|---|---|
| `Docs\roadmap\ROADMAP.md` | Unified product/project roadmap (single source of truth). | See shipped work, pre-launch must-haves, priorities, deferred items, detailed roadmap features, and business growth plans. | Condensed shipped summary; in-progress; pre-launch; SDK 55 deferrals; high/medium/low priorities; roadmap features (deferred deep linking, AI vision, brand jar catalog, multi-photo); coming soon; tabled; future/premium/business. |

## Etsy and business

| Document | What it covers | Look here if you want to... | Key contents |
|---|---|---|---|
| `Docs\etsy\Etsy_Launch_Plan.md` | Etsy listing and launch strategy for PlaceWell by BeNiralu. | Create the Etsy listing, pricing, photos, variations, shipping policy, or launch checklist. | Competitor analysis; differentiation; titles; listing description; tags; pricing; required photos; variations; shipping/policies; listing checklist; final recommendation. |

## PDF and label production references

| Document | What it covers | Look here if you want to... | Key contents |
|---|---|---|---|
| `PlaceWellPdfGenerator\LABEL_EXPORT_WIKI.md` | Step-by-step wiki for splitting label PDFs into individual 300 DPI PNGs for Cricut. | Export label PNGs, configure crop dimensions for shapes, remove round-label backgrounds, or troubleshoot exporter dependencies. | Overview; prerequisites; generate source PDF; configure `extract_labels_from_pdf.py`; round/rectangle/square settings; run script; transparent background; output folders; Cricut tips; troubleshooting; script reference. |

## Catalog and documentation maintenance

| Document | What it covers | Look here if you want to... | Key contents |
|---|---|---|---|
| `Docs\DOC_CATALOG.md` | This index of central docs, project README files, app agent guides, and notable reference files. | Find the right document for a task or audit docs coverage. | Quick reference; setup; architecture; deployment; build/release; testing; features/specs; design; roadmap; Etsy/business; PDF references; maintenance. |
