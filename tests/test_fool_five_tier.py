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
        self.assertEqual(catalog["active_output"], "artifacts/production/fool-five-tier-kit-v1")
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

    def test_catalog_binds_five_agentic_material_studies_without_promoting_them(self):
        catalog = self.load_json("production/symbols/fool-five-tier-kit.json")

        studies = catalog["material_studies"]
        self.assertEqual(
            studies["status"],
            "generated-pending-visual-material-review",
        )
        self.assertEqual(
            [item["tier"] for item in studies["assets"]],
            ["low", "mid", "saint", "angel", "true-god"],
        )
        for item in studies["assets"]:
            asset = ROOT / item["path"]
            call = ROOT / item["call"]
            self.assertTrue(asset.is_file(), item["path"])
            self.assertTrue(call.is_file(), item["call"])
            self.assertEqual(production_contracts.sha(asset), item["sha256"])
            self.assertEqual(item["role"], "agentic-material-reference")
            self.assertEqual(item["presentation_background"], "opaque")
            self.assertEqual(item["visual_status"], "pending")
        self.assertEqual(
            studies["engineering_status"],
            "study-only; deterministic renderer remains the sole active pixel production path",
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
        ):
            self.assertIn(marker, result.stdout)

    @unittest.skipUnless(
        sys.platform == "darwin" and shutil.which("swiftc"),
        "five-tier native renderer requires macOS/Swift",
    )
    def test_native_renderer_prepare_and_gate_produce_active_five_tier_kit(self):
        with tempfile.TemporaryDirectory(prefix="fool-five-tier-run-") as directory:
            binary = Path(directory) / "foolkit5"
            subprocess.run(
                ["swiftc", "-O", str(ROOT / "tools/render/foolkit5.swift"), "-o", str(binary)],
                check=True,
                capture_output=True,
                text=True,
            )
            output_parent = tempfile.TemporaryDirectory(
                prefix=".fool-five-tier-test-",
                dir=ROOT / "artifacts/production",
            )
            output = Path(output_parent.name) / "kit"
            try:
                subprocess.run(
                    [str(binary), "prepare", str(ROOT), str(output), "all"],
                    check=True,
                    capture_output=True,
                    text=True,
                )
                gated = subprocess.run(
                    [str(binary), "gate", str(ROOT), str(output)],
                    check=True,
                    capture_output=True,
                    text=True,
                )

                expected = {
                    "frame-low.png",
                    "frame-mid.png",
                    "frame-saint.png",
                    "frame-angel.png",
                    "frame-true-god.png",
                    "contact-sheet.png",
                    "five-tiers.png",
                    "emblems-white.png",
                    "emblems-dark.png",
                    "manifest.json",
                }
                expected.update({f"emblem-{digit}.png" for digit in range(10)})
                expected.update({f"fool-{digit}-frame.png" for digit in range(10)})
                self.assertTrue(expected.issubset({path.name for path in output.iterdir()}))
                self.assertFalse((output / "four-frames.png").exists())

                manifest = json.loads((output / "manifest.json").read_text(encoding="utf-8"))
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
                self.assertEqual(sorted(item["digit"] for item in manifest["entries"]), list(range(10)))
                self.assertEqual(manifest["geometry_difference_pixels"], 0)
                self.assertFalse(manifest["formal_release_approved"])
                self.assertIn("PASS: five-tier", gated.stdout)
            finally:
                output_parent.cleanup()

    def test_active_output_manifest_has_all_ten_sequences_and_five_tiers(self):
        catalog = self.load_json("production/symbols/fool-five-tier-kit.json")
        output = ROOT / catalog["active_output"]
        manifest = json.loads((output / "manifest.json").read_text(encoding="utf-8"))

        self.assertEqual(
            manifest["catalog_sha256"],
            production_contracts.sha(ROOT / "production/symbols/fool-five-tier-kit.json"),
        )
        self.assertEqual(
            manifest["frame_files"],
            [
                "frame-low.png",
                "frame-mid.png",
                "frame-saint.png",
                "frame-angel.png",
                "frame-true-god.png",
            ],
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
            sorted(item["digit"] for item in manifest["entries"]),
            list(range(10)),
        )
        self.assertTrue(
            all(item["geometry_difference_pixels"] == 0 for item in manifest["entries"])
        )
        self.assertEqual(manifest["geometry_difference_pixels"], 0)
        self.assertTrue(manifest["alpha"]["emblems_have_transparency"])
        self.assertTrue(manifest["alpha"]["frame_has_transparency"])
        self.assertTrue(manifest["legacy_four_tier_rejected"])
        self.assertFalse(manifest["formal_release_approved"])
        self.assertEqual(manifest["visual_status"], "pending")

if __name__ == "__main__":
    unittest.main()
