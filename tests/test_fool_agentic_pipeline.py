"""Contract-first tests for the Fool Agentic mother-to-sequence pipeline."""

import json
from pathlib import Path
import sys
import unittest


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import production


class MotherContractTests(unittest.TestCase):
    def load(self, relative: str) -> dict:
        with (ROOT / relative).open(encoding="utf-8") as stream:
            return json.load(stream)

    def test_mother_interface_freezes_empty_zones_and_single_gem_slot(self):
        template = self.load("production/templates/fool-mother-frame-interface-v1.json")
        self.assertEqual(template["schema_version"], "1.0.0")
        self.assertEqual(template["geometry_id"], "fool-agentic-mother-v1")
        self.assertEqual(template["coordinate_system"], "design-space-top-left-image-normalized")
        self.assertEqual(template["right_sequence_zone"]["status"], "reserved-empty")
        self.assertEqual(template["name_surface"]["background_pixels"], 0)
        self.assertEqual(template["gem_slot"]["count"], 1)
        self.assertEqual(template["gem_slot"]["tier_variant_count"], 5)
        self.assertEqual(template["thresholds"]["geometry_displacement_max_px"], 0)
        self.assertEqual(template["thresholds"]["outside_edit_domain_pixels_max"], 0)

    def test_catalog_has_five_tier_assets_and_ten_sequence_outputs(self):
        catalog = self.load("production/symbols/fool-mother-frame-v1.json")
        self.assertEqual(catalog["version"], "1.0.0")
        self.assertEqual(catalog["pathway_id"], "fool")
        self.assertEqual(
            catalog["sequence_mapping"],
            {"low": [9, 8], "mid": [7, 6, 5], "saint": [4, 3], "angel": [2, 1], "true-god": [0]},
        )
        self.assertEqual(catalog["tier_order"], ["low", "mid", "saint", "angel", "true-god"])
        self.assertEqual(len(catalog["sequence_outputs"]), 10)
        self.assertEqual({row["digit"] for row in catalog["sequence_outputs"]}, set(range(10)))
        self.assertEqual({row["tier"] for row in catalog["sequence_outputs"]}, set(catalog["tier_order"]))
        self.assertEqual(len(catalog["approved_emblems"]), 10)
        self.assertTrue(catalog["no_cross_product_variants"])
        self.assertEqual(catalog["status"], "pending-mother-generation")

    def test_batch_tasks_use_explicit_stage_contracts(self):
        expected = {
            "fool-mother-frame-v1.json": "mother",
            "fool-five-tier-frame-batch-v1.json": "tiers",
            "fool-ten-sequence-frame-batch-v1.json": "sequences",
        }
        for filename, stage in expected.items():
            task = self.load(f"production/tasks/{filename}")
            self.assertEqual(task["kind"], "hierarchy")
            self.assertEqual(task["mode"], "concept")
            self.assertEqual(task["spec"]["stage"], stage)
            production.validate_task(ROOT, task)

    def test_v3_sop_is_the_active_pipeline_entry(self):
        text = (ROOT / "docs/production-sop-v3.md").read_text(encoding="utf-8")
        self.assertIn("Agentic 母版", text)
        self.assertIn("五档", text)
        self.assertIn("十序列", text)
        self.assertIn("max_geometry_drift_px=0", text)
        self.assertIn("姓名区不得携带背景", text)


if __name__ == "__main__":
    unittest.main()
