"""体积观测（计划 05-T3）：报告可读、超限只提示不阻断。"""

from pathlib import Path
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import production as p


class AssetSizeReportTests(unittest.TestCase):
    def test_live_artifacts_report_is_non_blocking(self):
        report = p.report_asset_size(ROOT)

        self.assertEqual(report["status"], "reported")
        self.assertFalse(report["blocking"])
        self.assertGreater(report["batch_count"], 0)
        self.assertGreater(report["total_mb"], 0)
        self.assertIsNotNone(report["max_file"])
        self.assertGreater(report["max_file"]["mb"], 0)

    def test_oversized_batch_warns_without_blocking(self):
        with tempfile.TemporaryDirectory() as tmp:
            batch = Path(tmp) / "repo" / "artifacts" / "lotm.probe"
            batch.mkdir(parents=True)
            (batch / "big.bin").write_bytes(b"0" * (3 * 1024 * 1024))
            (batch / "small.bin").write_bytes(b"0" * 1024)

            report = p.report_asset_size(Path(tmp) / "repo", single_file_mb=1.0, scope_total_mb=2.0)

            self.assertEqual(report["status"], "reported")
            self.assertFalse(report["blocking"])
            self.assertEqual(report["batch_count"], 1)
            self.assertEqual(report["batches"][0]["file_count"], 2)
            self.assertEqual(report["max_file"]["mb"], 3.0)
            self.assertEqual(report["warnings"], [
                "single file over budget: artifacts/lotm.probe/big.bin (3.0 MB)",
                "batch over budget: artifacts/lotm.probe (3.0 MB)",
            ])

    def test_missing_artifacts_directory_reports_empty(self):
        with tempfile.TemporaryDirectory() as tmp:
            report = p.report_asset_size(Path(tmp))

            self.assertEqual(report["batch_count"], 0)
            self.assertEqual(report["total_mb"], 0)
            self.assertIsNone(report["max_file"])
            self.assertEqual(report["warnings"], [])


if __name__ == "__main__":
    unittest.main()
