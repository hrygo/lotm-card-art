"""Reseal tool tests: drift detection, surgical rewrite, scope boundary."""

import hashlib
import io
import json
from contextlib import redirect_stdout
from pathlib import Path
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import pin_seal


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


class SyntheticTreeTests(unittest.TestCase):
    def make_tree(self) -> Path:
        holder = tempfile.TemporaryDirectory()
        self.addCleanup(holder.cleanup)
        root = Path(holder.name)
        (root / "config").mkdir()
        (root / "docs").mkdir()
        (root / "production/tasks").mkdir(parents=True)
        (root / "artifacts/production/sample/v001").mkdir(parents=True)
        (root / "config/quality-color-tokens.json").write_text('{"schema_version":"1"}\n', encoding="utf-8")
        (root / "docs/production-sop-v3.md").write_text("# sop\n", encoding="utf-8")
        self.write_contract(
            root / "production/tasks/sample-v1.json",
            [
                {"path": "config/quality-color-tokens.json", "sha256": digest(root / "config/quality-color-tokens.json")},
                {"path": "docs/production-sop-v3.md", "sha256": digest(root / "docs/production-sop-v3.md")},
            ],
        )
        return root

    @staticmethod
    def write_contract(path: Path, contracts: list) -> None:
        payload = {"task_id": "sample", "revision": 1, "contracts": contracts, "note": "keep me byte for byte"}
        path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    def test_check_passes_when_every_pin_matches(self):
        root = self.make_tree()
        problems, total = pin_seal.audit(root)
        self.assertEqual(problems, [])
        self.assertEqual(total, 2)

    def test_tampered_pin_is_detected_and_the_path_is_named(self):
        root = self.make_tree()
        contract = root / "production/tasks/sample-v1.json"
        payload = json.loads(contract.read_text(encoding="utf-8"))
        payload["contracts"][1]["sha256"] = "0" * 64
        contract.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        problems, _ = pin_seal.audit(root)
        self.assertIn("docs/production-sop-v3.md", problems[0])
        self.assertIn("production/tasks/sample-v1.json", problems[0])
        out = io.StringIO()
        with redirect_stdout(out):
            code = pin_seal.main(["--check", "--root", str(root)])
        self.assertNotEqual(code, 0)
        self.assertRegex(out.getvalue(), r"STALE\s+production/tasks/sample-v1\.json")

    def test_changed_source_is_resealed_without_touching_other_bytes(self):
        root = self.make_tree()
        contract = root / "production/tasks/sample-v1.json"
        before = contract.read_text(encoding="utf-8")
        (root / "config/quality-color-tokens.json").write_text('{"schema_version":"2"}\n', encoding="utf-8")
        rewritten = pin_seal.seal(root)
        self.assertEqual(rewritten, ["production/tasks/sample-v1.json"])
        after = contract.read_text(encoding="utf-8")
        mask = lambda t: pin_seal.MASK_RE.sub(r'\1"<HASH>"', t)
        self.assertEqual(mask(before), mask(after))
        problems, _ = pin_seal.audit(root)
        self.assertEqual(problems, [])
        self.assertEqual(pin_seal.seal(root), [])

    def test_missing_pinned_file_is_an_error_not_a_skip(self):
        root = self.make_tree()
        (root / "docs/production-sop-v3.md").unlink()
        problems, _ = pin_seal.audit(root)
        self.assertEqual(len(problems), 1)
        self.assertIn("MISSING", problems[0])
        with self.assertRaises(pin_seal.PinError):
            pin_seal.seal(root)

    def test_receipts_under_artifacts_are_out_of_scope(self):
        root = self.make_tree()
        self.write_contract(
            root / "artifacts/production/sample/v001/task.json",
            [{"path": "config/quality-color-tokens.json", "sha256": "0" * 64}],
        )
        problems, total = pin_seal.audit(root)
        self.assertEqual(total, 2)
        self.assertEqual(problems, [])

    def test_repository_live_pins_all_verify(self):
        problems, total = pin_seal.audit(ROOT)
        self.assertEqual(problems, [], f"活合同 pin 漂移：{problems}")
        self.assertGreater(total, 0)


if __name__ == "__main__":
    unittest.main()
