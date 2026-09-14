"""Validation tests for the retained Fool Agentic material baseline."""

from pathlib import Path
import copy
import sys
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import production


class FoolMaterialValidationTests(unittest.TestCase):
    def test_current_material_baseline_is_self_consistent_after_cleanup(self):
        report = production.validate_fool_materials(ROOT)

        self.assertEqual(report["status"], "passed")
        self.assertEqual(report["tier_count"], 5)
        self.assertEqual(report["sequence_count"], 10)
        self.assertEqual(report["fusion_digit_count"], 10)
        self.assertEqual(
            report["retained_fusion_runs"],
            {
                "0": "v002",
                "1": "v001",
                "2": "v001",
                "3": "v001",
                "4": "v002",
                "5": "v001",
                "6": "v001",
                "7": "v002",
                "8": "v001",
                "9": "v002",
            },
        )
        self.assertEqual(report["intermediate_2k_count"], 0)
        self.assertGreater(report["retired_path_count"], 0)

    def test_report_does_not_treat_standalone_numerals_as_current_assets(self):
        report = production.validate_fool_materials(ROOT)

        self.assertEqual(report["standalone_numeral_status"], "retired-standalone-numerals")
        self.assertEqual(
            report["active_fusion_catalog"],
            "production/symbols/fool-fusion-family.json",
        )
        self.assertEqual(
            report["layered_asset_baseline"],
            "production/symbols/fool-layered-asset-baseline-v1.json",
        )

    def test_retained_material_hash_tampering_is_rejected(self):
        original_sha = production.sha

        def tampered_sha(path):
            if str(path).endswith("material-fool-veil/v001/raw.png"):
                return "0" * 64
            return original_sha(path)

        with patch.object(production, "sha", side_effect=tampered_sha):
            with self.assertRaisesRegex(production.Invalid, "retained material hash"):
                production.validate_fool_materials(ROOT)

    def _tamper_sidecar(self, mutate):
        real_read = production.read

        def tampered_read(path):
            data = real_read(path)
            if str(path).endswith("production/approvals/fool-agentic-visual-baseline-v1.json"):
                data = copy.deepcopy(data)
                mutate(data)
            return data

        return patch.object(production, "read", side_effect=tampered_read)

    def test_renderer_status_alone_cannot_satisfy_visual_approval(self):
        # 视觉批准必须来自人工 sidecar，而不是渲染器写入的状态字符串。
        with self._tamper_sidecar(lambda d: d.update(visual_approved=False)):
            with self.assertRaisesRegex(production.Invalid, "visual approval sidecar"):
                production.validate_fool_materials(ROOT)

    def test_visual_approval_sidecar_must_not_approve_release(self):
        with self._tamper_sidecar(lambda d: d.update(release_approved=True)):
            with self.assertRaisesRegex(production.Invalid, "must not approve release"):
                production.validate_fool_materials(ROOT)

    def test_visual_approval_sidecar_hash_binding_is_enforced(self):
        def break_manifest_binding(d):
            d["approved_assets"]["five_tier_frames"]["manifest_sha256"] = "0" * 64

        with self._tamper_sidecar(break_manifest_binding):
            with self.assertRaisesRegex(production.Invalid, "manifest binding is stale"):
                production.validate_fool_materials(ROOT)


if __name__ == "__main__":
    unittest.main()
