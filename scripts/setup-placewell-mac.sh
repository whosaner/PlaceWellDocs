#!/bin/bash
set -euo pipefail

usage() {
  printf 'Usage: bash setup-placewell-mac.sh [workspace]\nDefault workspace: ~/PlaceWell\n'
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi
if [[ $# -gt 1 || "${1:-}" == -* ]]; then
  usage >&2
  exit 1
fi

for tool in git gh; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf 'Missing %s. Install Git and GitHub CLI first; see setup/MacBook_Setup.md.\n' "$tool" >&2
    exit 1
  fi
done
if ! git lfs version >/dev/null 2>&1; then
  printf 'Git LFS is required for the image masters. Install git-lfs first.\n' >&2
  exit 1
fi
if ! gh auth status --hostname github.com >/dev/null 2>&1; then
  printf 'Sign in first: gh auth login --hostname github.com --git-protocol https --web\n' >&2
  exit 1
fi
gh auth setup-git --hostname github.com

workspace="${1:-$HOME/PlaceWell}"
mkdir -p "$workspace"
workspace="$(cd "$workspace" && pwd -P)"

repositories=(
  "Docs|PlaceWellDocs|main"
  "PlaceWellApp|PlaceWellApp|main"
  "PlaceWellQRService|PlaceWellQRService|main"
  "PlaceWellPdfGenerator|PlaceWellPdfGenerator|main"
  "PlaceWellUI|PlaceWellUI|main"
  "Shopify|PlaceWell-Shopify|main"
  "PlaceWellAdmin|PlaceWellAdmin|main"
  "PlaceWell-StockImageMasters|PlaceWell-StockImageMasters|main"
  "PlaceWell-SpiceJarRenderer|PlaceWell-SpiceJarRenderer|main"
  "Label Templates|PlaceWell-LabelTemplates|main"
)

for entry in "${repositories[@]}"; do
  IFS='|' read -r folder repository branch <<< "$entry"
  destination="$workspace/$folder"
  printf '\n== %s (%s) ==\n' "$folder" "$branch"
  if [[ -e "$destination" || -L "$destination" ]]; then
    if [[ ! -d "$destination/.git" && ! -f "$destination/.git" ]]; then
      printf 'Refusing to overwrite non-repository path: %s\n' "$destination" >&2
      exit 1
    fi
    origin="$(git -C "$destination" remote get-url origin)"
    case "$origin" in
      "https://github.com/whosaner/$repository.git"|"https://github.com/whosaner/$repository"|"git@github.com:whosaner/$repository.git") ;;
      *) printf 'Unexpected origin in %s: %s\n' "$destination" "$origin" >&2; exit 1 ;;
    esac
    current_branch="$(git -C "$destination" branch --show-current)"
    if [[ "$current_branch" != "$branch" ]]; then
      printf 'Expected branch %s in %s, found %s. Resolve manually; nothing overwritten.\n' "$branch" "$destination" "$current_branch" >&2
      exit 1
    fi
    printf 'Already present; preserving local files and commits (no pull/reset).\n'
  else
    gh repo clone "whosaner/$repository" "$destination" -- --branch "$branch"
    git -C "$destination" lfs install --local
    git -C "$destination" lfs pull
  fi
done

printf '\nAll 10 repository checkouts are present in %s.\n' "$workspace"
printf 'Existing checkouts were not updated. Dependencies, secrets, photos, generated outputs,\n'
printf 'local-only files and external services are not copied or configured by this script.\n'
printf 'Next: read Docs/setup/MacBook_Setup.md for the manual-transfer checklist.\n'
