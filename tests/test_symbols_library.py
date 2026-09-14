"""Checks for current symbol inventory and historical-registry boundaries."""

from pathlib import Path
import sys
import unittest


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import production as p


class SymbolLibraryTests(unittest.TestCase):
    def catalog(self):
        return p.read(ROOT / "production/symbols/catalog.json")

    def test_all_pathways_have_distinct_traceable_emblem_sources(self):
        catalog = self.catalog()
        items = catalog["emblems"]
        expected = {item["id"] for item in p.read(ROOT / "catalog/pathways.json")["pathways"]}
        self.assertEqual({item["pathway_id"] for item in items}, expected)
        hashes = set()
        for item in items:
            receipt = p.read(ROOT / item["receipt"])
            raw = receipt["raw"]
            path = ROOT / raw["path"]
            self.assertTrue(path.is_file(), item["id"])
            self.assertEqual(p.sha(path), raw["sha256"], item["id"])
            self.assertEqual(p.cardctl.image_info(path)["format"], "PNG")
            hashes.add(raw["sha256"])
        self.assertEqual(len(hashes), 22)

    def test_historical_registry_does_not_define_current_fool_assets(self):
        catalog = self.catalog()
        self.assertEqual(catalog["status"], "historical-pre-native-fool-baseline")
        self.assertEqual(
            catalog["active_fool_catalog"],
            "production/symbols/fool-five-tier-kit.json",
        )
        self.assertEqual(
            catalog["active_fool_fusion_catalog"],
            "production/symbols/fool-fusion-family.json",
        )

    def test_current_fool_materials_use_native_baseline_gate(self):
        report = p.validate_fool_materials(ROOT)
        self.assertEqual(report["status"], "passed")
        self.assertEqual(report["tier_count"], 5)
        self.assertEqual(report["sequence_count"], 10)
        self.assertEqual(report["fusion_digit_count"], 10)

    def test_exact_digit_and_tier_inventory(self):
        kit = p.read(ROOT / "production/symbols/fool-five-tier-kit.json")
        family = p.read(ROOT / "production/symbols/fool-fusion-family.json")
        flattened = [digit for digits in kit["sequence_mapping"].values() for digit in digits]
        self.assertEqual(sorted(flattened), list(range(10)))
        self.assertEqual(len(flattened), len(set(flattened)))
        self.assertEqual([item["digit"] for item in family["entries"]], list(range(10)))
        self.assertEqual(
            p.read(ROOT / "production/symbols/fool-rank-numerals-v1.json")["status"],
            "retired-standalone-numerals",
        )

    def test_fusion_references_are_opaque_visual_baselines_not_layers(self):
        family = p.read(ROOT / "production/symbols/fool-fusion-family.json")
        for item in family["entries"]:
            with self.subTest(digit=item["digit"]):
                self.assertEqual(item["retention"], "keep")
                self.assertFalse(item["engineering"]["has_real_transparency"])
                self.assertTrue(item["art_review"]["status"].startswith("user-approved-"))

    def test_legacy_render_gallery_is_not_current_output(self):
        catalog = self.catalog()
        self.assertTrue(all(not (ROOT / job["output"]).exists() for job in catalog["render_jobs"]))


if __name__ == "__main__":
    unittest.main()
