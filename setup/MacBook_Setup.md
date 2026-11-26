# PlaceWell MacBook checkout

This script clones the ten GitHub repositories into `~/PlaceWell` with the
same folder names and working branches as the Windows workspace. It does not
start services, deploy, install app dependencies, copy secrets, or reproduce
the complete Windows filesystem.

## Run on the MacBook

Install Apple's command-line tools (`xcode-select --install`) if Git is
missing. With Homebrew already installed:

```sh
brew install gh git-lfs
gh auth login --hostname github.com --git-protocol https --web
gh auth setup-git --hostname github.com
mkdir -p "$HOME/PlaceWell"
gh repo clone whosaner/PlaceWellDocs "$HOME/PlaceWell/Docs" -- --branch main
bash "$HOME/PlaceWell/Docs/scripts/setup-placewell-mac.sh"
```

If Docs already exists, skip its bootstrap clone and run the script from it.
Use `bash "$HOME/PlaceWell/Docs/scripts/setup-placewell-mac.sh" "/your/workspace"`
to choose another root. The script stops on failed authentication, missing
tools, failed clones/LFS downloads, unexpected existing folders, wrong remotes,
or wrong branches. Re-running preserves matching existing checkouts; it does
not pull, reset, switch branches, or overwrite local work. GitHub CLI's
authentication helper is configured for HTTPS clones. Git LFS retrieves the
actual tracked image masters, not just pointer files.

| Folder | GitHub repository | Working branch |
|---|---|---|
| Docs | whosaner/PlaceWellDocs | main |
| PlaceWellApp | whosaner/PlaceWellApp | main |
| PlaceWellQRService | whosaner/PlaceWellQRService | main |
| PlaceWellPdfGenerator | whosaner/PlaceWellPdfGenerator | main |
| PlaceWellUI | whosaner/PlaceWellUI | main |
| Shopify | whosaner/PlaceWell-Shopify | main |
| PlaceWellAdmin | whosaner/PlaceWellAdmin | main |
| PlaceWell-StockImageMasters | whosaner/PlaceWell-StockImageMasters | main |
| PlaceWell-SpiceJarRenderer | whosaner/PlaceWell-SpiceJarRenderer | main |
| Label Templates | whosaner/PlaceWell-LabelTemplates | main |

On November 26, 2026, completed `feature/stock-jar-images` work was consolidated
into the primary branches, and the remaining four `master` branches were renamed
to `main` using GitHub's branch rename API. All ten GitHub default branches and
Windows local checkouts now use `main`. Code/history were unchanged by the rename.
Old feature branches are retained for reference, not ongoing development.

If you already cloned on the old feature branches, first ensure there are no
uncommitted changes, fetch, and switch to the primary branches:

```sh
git -C "$HOME/PlaceWell/Docs" fetch origin
git -C "$HOME/PlaceWell/Docs" switch main
git -C "$HOME/PlaceWell/Docs" merge --ff-only origin/main
git -C "$HOME/PlaceWell/PlaceWellUI" fetch origin
git -C "$HOME/PlaceWell/PlaceWellUI" switch main
git -C "$HOME/PlaceWell/PlaceWellUI" merge --ff-only origin/main
git -C "$HOME/PlaceWell/PlaceWellQRService" fetch origin
git -C "$HOME/PlaceWell/PlaceWellQRService" switch main
git -C "$HOME/PlaceWell/PlaceWellQRService" merge --ff-only origin/main
```

If switching or fast-forwarding fails, stop and resolve the local work rather
than forcing a reset. Skip commands for repositories you have not cloned yet.

For an existing clone still on `master` (Docs, UI, PDF Generator, or Admin),
apply this sequence in that repository, after ensuring a clean worktree:

```sh
git fetch origin
git branch -m master main
git branch --set-upstream-to=origin/main main
git merge --ff-only origin/main
git remote set-head origin -a
```

Do not run the rename if a local `main` already exists; inspect both local
branches first. Renaming preserves local commits; a failed fast-forward requires
manual reconciliation, not a reset. GitHub's defaults moved to `main`, with no
custom branch protections, repository webhooks, GitHub Pages, or checked-in
Actions workflows on the four renamed repositories at the time of migration.
Private-repository rulesets were unavailable under the current GitHub plan.

## Local-only Windows files

The November 26 audit found that **not everything under `C:\PlaceWell` is in
GitHub**. Cloning retrieves tracked files only. Copy desired local-only folders
to the same relative locations on the Mac; do not upload private credentials
or private financial records to GitHub.

Entire top-level folders outside the ten repositories:

| Windows folder | Transfer guidance |
|---|---|
| `Photos` | Copy original product/photo source files you need. |
| `Images` | Copy if you want the local rendered/exported images. |
| `StockImageMixedTestPack-v2` | Copy if you need the saved test pack. |
| `BeNiralu` | Separate local folder, not a PlaceWell GitHub checkout. Copy only if wanted. |
| `tools` | Local utilities, builds and logs. Review individually; Windows helpers are not Mac setup tools. |
| `.pytest_cache` | Generated cache; do not transfer. |

Within repositories, the following local-only material also needs a decision:

| Relative path | Transfer guidance |
|---|---|
| `Docs\Finances` | Private records; transfer securely only if needed. Never commit. |
| `Docs\research\poc\box-tote-labels\SL522-XW_Typography_Layout_POC.pdf` and `SL573-XW_Typography_Layout_POC.pdf` | Duplicate local copies; canonical copies are tracked in `experimental-design-concepts`. |
| `PlaceWellApp\.env.local`, `GoogleService-Info.plist`, `credentials.json`, `credentials\android\keystore.jks`, `placewell-prod-60ef3-ad6015673661.json` | Private local configuration/build/submission credentials. Transfer through a secure channel or obtain from the appropriate provider. Never paste their contents into GitHub. |
| `PlaceWellQRService\serviceAccountKey.json` | Private service credential; transfer securely or provision separately. |
| `PlaceWellApp\artifacts`, `builds`, `screenshots`, `src\screens\LabelFormScreen.js.backup` | Optional saved outputs and backup. |
| `PlaceWellPdfGenerator\output` | Optional generated PDFs/images; clone does not restore saved output. |
| `PlaceWell-StockImageMasters\hosting\stock-images\img` | Local generated hosting images. Regenerate using the repository's release workflow, or copy if preserving this exact release. |
| `Shopify\Approved Baselines\homepage-approved-2026-09-07.zip` | Optional local archive; the baseline directory itself is tracked. |
| `Shopify\Mock Specs\temp` | Optional temporary reference files. |

Do not copy Windows `.venv`, `node_modules`, `__pycache__`, `.pytest_cache`,
`.expo`, `.firebase`, or Python `.egg-info` directories. Recreate dependencies
on the Mac from each repository's manifests and setup documentation. Empty
directories are not tracked by Git.

The checkout guide also describes required `.env` configuration for UI/QR
services. Files absent from the Windows audit still need provisioning if a
workflow requires them. Use each `.env.example`, adapting Windows paths to
Mac paths; do not blindly copy Windows settings. GitHub, Firebase/EAS/Shopify
authentication, deployed server files, Firestore records and order state are
not cloned. Copilot session artifacts outside `C:\PlaceWell` are outside this
inventory.

This is a **checkout script**, not a guarantee that all existing Windows
commands or applications are macOS-compatible. Use Python virtual environments
with `bin/python` and shell equivalents rather than Windows `.ps1`/`.bat`
launchers. Consult the per-project setup docs before running or deploying.
