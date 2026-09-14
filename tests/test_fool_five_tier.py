"""Contract tests for the active Fool five-tier material kit."""

import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
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
        self.assertEqual(catalog["active_output"], "artifacts/production/fool-five-tier-direct-kit-v1")
        self.assertFalse(catalog["legacy_four_tier_status"]["active"])

    def test_old_four_tier_catalog_is_retired_and_not_the_active_successor(self):
        old_catalog = self.load_json("production/symbols/fool-frame-kit.json")
        historical_family = self.load_json("production/symbols/quality-frame-family.json")
        retirement = self.load_json("production/retirements/fool-four-tier-v1.json")

        self.assertEqual(old_catalog["status"], "retired-historical")
        self.assertFalse(old_catalog["active"])
        self.assertEqual(
            old_catalog["successor"],
            "production/symbols/fool-five-tier-kit.json",
        )
        self.assertEqual(historical_family["status"], "historical-inactive")
        self.assertEqual(
            historical_family["active_successor"],
            "production/symbols/fool-five-tier-kit.json",
        )
        self.assertTrue(historical_family["historical_samples_only"])
        self.assertEqual(retirement["status"], "retired-recoverable")
        for item in retirement["moved_to_trash"]:
            self.assertFalse((ROOT / item["original"]).exists(), item["original"])

    def test_catalog_binds_all_ten_approved_fool_emblems(self):
        catalog = self.load_json("production/symbols/fool-five-tier-kit.json")

        self.assertEqual(sorted(catalog["approved_emblems"]), list(range(10)))
        self.assertEqual(
            sorted(item["digit"] for item in catalog["emblem_inputs"]),
            list(range(10)),
        )

    def test_catalog_dependencies_and_emblem_hashes_are_current(self):
        catalog = self.load_json("production/symbols/fool-five-tier-kit.json")

        for record_name in ("direction", "geometry_lock", "color_tokens", "sequence_hierarchy", "matte", "recipe", "inscription_contract", "diamond_study", "diamond_integration_study"):
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

    def test_catalog_does_not_promote_absent_historical_material_studies(self):
        catalog = self.load_json("production/symbols/fool-five-tier-kit.json")

        studies = catalog["material_studies"]
        self.assertEqual(
            studies["status"],
            "historical-study-assets-not-present-in-current-worktree",
        )
        self.assertEqual(
            studies["assets"],
            [],
        )
        self.assertEqual(
            studies["engineering_status"],
            "not-a-current-dependency; native Agentic frame package is the official source",
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

    @unittest.skipUnless(
        sys.platform == "darwin" and shutil.which("swiftc"),
        "five-tier native renderer requires macOS/Swift",
    )
    def test_native_renderer_selftest_reports_five_tier_safety_markers(self):
        with tempfile.TemporaryDirectory(prefix="fool-five-tier-bin-") as directory:
            binary = Path(directory) / "foolkit5"
            subprocess.run(
                ["swiftc", "-O", str(ROOT / "tools/render/foolkit5.swift"), "-o", str(binary)],
                check=True,
                capture_output=True,
                text=True,
            )
            result = subprocess.run(
                [str(binary), "selftest"],
                check=True,
                capture_output=True,
                text=True,
            )
        for marker in (
            "five-tier-mapping",
            "geometry-zero",
            "alpha-real",
            "gem-highlight-preserved",
            "legacy-four-tier-rejected",
            "diamond-seat-integrated",
            "diamond-contact-shadow",
            "diamond-rail-continuity",
        ):
            self.assertIn(marker, result.stdout)

    def test_legacy_material_renderer_is_not_current_production_route(self):
        catalog = self.load_json("production/symbols/fool-five-tier-kit.json")
        self.assertEqual(catalog["status"], "official-agentic-visual-material-baseline")
        self.assertEqual(
            catalog["active_output"],
            "artifacts/production/fool-five-tier-direct-kit-v1",
        )
        self.assertTrue(catalog["resolution_policy"]["native_source_is_canonical"])
        self.assertEqual(catalog["resolution_policy"]["intermediate_2k_count"], 0)
        self.assertTrue(catalog["resolution_policy"]["final_card_only_sampling"])

    def test_active_output_manifest_has_all_ten_sequences_and_five_tiers(self):
        catalog = self.load_json("production/symbols/fool-five-tier-kit.json")
        self.assertEqual(catalog["version"], "5.0.0")
        self.assertEqual(catalog["active_output"], "artifacts/production/fool-five-tier-direct-kit-v1")
        output = ROOT / catalog["active_output"]
        manifest = json.loads((output / "manifest.json").read_text(encoding="utf-8"))

        self.assertEqual(manifest["mode"], "fool-five-tier-direct-batch-v1")
        self.assertTrue(manifest["direct_agentic_sources"])
        self.assertEqual(
            sorted(manifest["native_frame_hashes"]),
            ["angel", "low", "mid", "saint", "true-god"],
        )
        for tier, digest in manifest["native_frame_hashes"].items():
            self.assertEqual(
                production_contracts.sha(output / f"frame-{tier}-native.png"),
                digest,
            )
        self.assertEqual(
            manifest["sequence_mapping"],
            {
                "low": [9, 8],
                "mid": [7, 6, 5],
                "saint": [4, 3],
                "angel": [2, 1],
                "true-god": [0],
            },
        )
        self.assertEqual(
            sorted(digit for digits in manifest["sequence_mapping"].values() for digit in digits),
            list(range(10)),
        )
        self.assertEqual(manifest["geometry"]["max_geometry_drift_px"], 0)
        self.assertTrue(manifest["gem_slot"]["name_protection"])
        self.assertEqual(manifest["gem_slot"]["variant_count"], 5)
        self.assertTrue(manifest["material"]["embedded_gem_preserved"])
        self.assertTrue(manifest["no_cross_product_variants"])
        self.assertFalse(manifest["formal_release_approved"])
        self.assertEqual(manifest["status"], "user-approved-agentic-visual-baseline")

if __name__ == "__main__":
    unittest.main()
