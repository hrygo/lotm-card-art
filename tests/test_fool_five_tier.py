"""Contract tests for the active Fool five-tier material kit."""

import json
from pathlib import Path
import sys
import unittest


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import production as production_contracts


class FoolFiveTierContractTests(unittest.TestCase):
    def load_json(self, relative: str) -> dict:
        with (ROOT / relative).open(encoding="utf-8") as stream:
            return json.load(stream)

    def test_catalog_declares_exact_five_tier_sequence_mapping_and_active_output(self):
        catalog = self.load_json("production/symbols/fool-five-tier-kit.json")

        self.assertEqual(
            catalog["sequence_mapping"],
            {
                "low": [9, 8],
                "mid": [7, 6, 5],
                "saint": [4, 3],
                "angel": [2, 1],
                "true-god": [0],
            },
        )
        self.assertEqual(catalog["active_output"], "artifacts/production/fool-five-tier-kit-v1")
        self.assertFalse(catalog["legacy_four_tier_status"]["active"])

    def test_catalog_binds_all_ten_approved_fool_emblems(self):
        catalog = self.load_json("production/symbols/fool-five-tier-kit.json")

        self.assertEqual(sorted(catalog["approved_emblems"]), list(range(10)))
        self.assertEqual(
            sorted(item["digit"] for item in catalog["emblem_inputs"]),
            list(range(10)),
        )

    def test_catalog_dependencies_and_emblem_hashes_are_current(self):
        catalog = self.load_json("production/symbols/fool-five-tier-kit.json")

        for record_name in ("direction", "geometry_lock", "color_tokens", "sequence_hierarchy", "matte"):
            record = catalog[record_name]
            self.assertEqual(
                production_contracts.sha(ROOT / record["path"]),
                record["sha256"],
                record_name,
            )
        for item in catalog["emblem_inputs"]:
            self.assertEqual(
                production_contracts.sha(ROOT / item["path"]),
                item["sha256"],
                f"emblem {item['digit']}",
            )

    def test_existing_fusion_family_records_user_approval_for_every_digit(self):
        family = self.load_json("production/symbols/fool-fusion-family.json")

        self.assertEqual([item["digit"] for item in family["entries"]], list(range(10)))
        approval = family["current_user_approval"]
        self.assertEqual(approval["status"], "user-approved-visual-baseline")
        self.assertEqual(approval["digits"], list(range(10)))
        self.assertEqual(
            approval["basis"],
            "用户在当前会话明确确认：9-0 圣徽全面都认可",
        )
        self.assertFalse(family["release_approved"])

    def test_each_tier_task_uses_a_matching_representative_sequence(self):
        representatives = {
            "low": 9,
            "mid": 7,
            "saint": 4,
            "angel": 2,
            "true-god": 0,
        }

        for tier, sequence in representatives.items():
            task = self.load_json(f"production/symbols/tasks/fool-quality-frame-{tier}-v2.json")
            self.assertEqual(task["kind"], "hierarchy")
            self.assertEqual(task["quality"], {"sequence": sequence, "visual_tier": tier})
            self.assertEqual(task["spec"]["tier"], tier)
            production_contracts.validate_task(ROOT, task)


if __name__ == "__main__":
    unittest.main()
