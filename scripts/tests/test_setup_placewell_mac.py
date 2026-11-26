import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "setup-placewell-mac.sh"
BASH = shutil.which("bash") or r"C:\Program Files\Git\bin\bash.exe"
REAL_GIT = shutil.which("git")


class CheckoutScriptTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.workspace = self.root / "workspace with spaces"
        self.env = dict(os.environ, MOCK_ROOT=str(self.root), REAL_GIT=REAL_GIT)
        self.env["PATH"] = str(self.bin) + os.pathsep + self.env["PATH"]
        self.env["MOCK_BIN"] = (
            "/" + self.bin.drive[0].lower() + self.bin.as_posix()[2:]
            if os.name == "nt" else str(self.bin)
        )
        self.write_tool("git", """#!/bin/bash
set -eu
if [[ "${1:-}" == lfs || "${3:-}" == lfs ]]; then
  [[ "${MOCK_LFS_MISSING:-}" != 1 ]] || exit 1
  echo "$*" >> "$MOCK_ROOT/lfs.log"
  exit 0
fi
exec "$REAL_GIT" "$@"
""")
        self.write_tool("gh", """#!/bin/bash
set -eu
if [[ "$1 $2" == "auth status" ]]; then
  [[ "${MOCK_AUTH_FAILURE:-}" != 1 ]]
elif [[ "$1 $2" == "auth setup-git" ]]; then
  exit 0
elif [[ "$1 $2" == "repo clone" ]]; then
  [[ "$5" == -- && "$6" == --branch ]]
  [[ "${MOCK_CLONE_FAILURE:-}" != 1 ]] || exit 1
  echo "$3|$7" >> "$MOCK_ROOT/clones.log"
  "$REAL_GIT" init -q -b "$7" "$4"
  "$REAL_GIT" -C "$4" -c user.name=Test -c user.email=test@example.invalid commit -q --allow-empty -m fixture
  "$REAL_GIT" -C "$4" remote add origin "https://github.com/$3.git"
else
  exit 1
fi
""")

    def write_tool(self, name, content):
        path = self.bin / name
        path.write_text(content, encoding="utf-8", newline="\n")
        path.chmod(0o755)

    def run_script(self, *args):
        return subprocess.run(
            [BASH, "-c", 'export PATH="$MOCK_BIN:$PATH"; exec bash "$@"',
             "checkout-test", str(SCRIPT), *map(str, args)],
            env=self.env, capture_output=True, text=True,
        )

    def test_clones_all_working_branches_and_reruns_without_overwriting(self):
        result = self.run_script(self.workspace)
        self.assertEqual(result.returncode, 0, result.stderr)
        clones = (self.root / "clones.log").read_text().splitlines()
        self.assertEqual(len(clones), 10)
        self.assertIn("whosaner/PlaceWellDocs|feature/stock-jar-images", clones)
        self.assertIn("whosaner/PlaceWellUI|feature/stock-jar-images", clones)
        self.assertIn("whosaner/PlaceWellQRService|feature/stock-jar-images", clones)
        self.assertTrue((self.workspace / "Label Templates" / ".git").is_dir())
        self.assertEqual((self.root / "lfs.log").read_text().count("lfs pull"), 10)
        local = self.workspace / "Docs" / "local.txt"
        local.write_text("preserve me")
        result = self.run_script(self.workspace)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(local.read_text(), "preserve me")
        self.assertEqual(len((self.root / "clones.log").read_text().splitlines()), 10)

    def test_stops_before_cloning_if_auth_or_lfs_is_missing(self):
        for flag in ("MOCK_AUTH_FAILURE", "MOCK_LFS_MISSING"):
            with self.subTest(flag=flag):
                self.env[flag] = "1"
                self.assertNotEqual(self.run_script(self.workspace).returncode, 0)
                self.assertFalse(self.workspace.exists())
                del self.env[flag]

    def test_refuses_non_repository_and_reports_clone_failures(self):
        (self.workspace / "Docs").mkdir(parents=True)
        result = self.run_script(self.workspace)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Refusing to overwrite", result.stderr)
        self.env["MOCK_CLONE_FAILURE"] = "1"
        result = self.run_script(self.root / "fresh")
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("All 10", result.stdout)

    def test_refuses_wrong_branch_or_origin(self):
        self.assertEqual(self.run_script(self.workspace).returncode, 0)
        docs = self.workspace / "Docs"
        subprocess.run([REAL_GIT, "-C", str(docs), "checkout", "-qb", "other"], check=True)
        result = self.run_script(self.workspace)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Expected branch", result.stderr)
        subprocess.run([REAL_GIT, "-C", str(docs), "checkout", "-q", "feature/stock-jar-images"], check=True)
        subprocess.run([REAL_GIT, "-C", str(docs), "remote", "set-url", "origin", "https://github.com/other/repo.git"], check=True)
        result = self.run_script(self.workspace)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Unexpected origin", result.stderr)


if __name__ == "__main__":
    unittest.main()
