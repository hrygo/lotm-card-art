"""Contract tests for the Fool v3 inscription-band frame template."""

import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class FoolThreeTextZoneContractTests(unittest.TestCase):
    def load_json(self, relative: str) -> dict:
        with (ROOT / relative).open(encoding="utf-8") as stream:
            return json.load(stream)

    def test_schema_is_strict_and_names_exactly_three_fields(self):
        schema = self.load_json("production/schemas/card-text-panels.schema.json")
        self.assertEqual(schema["type"], "object")
        self.assertEqual(
            schema["required"],
            ["schema_version", "pathway_name", "sequence_name", "character_name"],
        )
        self.assertFalse(schema["additionalProperties"])
        self.assertEqual(
            set(schema["properties"]["pathway_name"]["properties"]["zone"]["enum"]),
            {"left-column-inlay"},
        )
        self.assertEqual(
            set(schema["properties"]["sequence_name"]["properties"]["zone"]["enum"]),
            {"right-column-inlay"},
        )
        self.assertEqual(
            set(schema["properties"]["character_name"]["properties"]["zone"]["enum"]),
            {"central-nameplate"},
        )

    def test_template_has_local_side_inlays_and_one_full_width_nameplate(self):
        template = self.load_json("production/templates/card-text-panels-v3.json")
        zones = template["zones"]
        self.assertEqual(
            [zone["id"] for zone in zones],
            ["pathway_name", "sequence_name", "character_name"],
        )
        self.assertEqual(
            [zone["kind"] for zone in zones],
            ["left-column-inlay", "right-column-inlay", "central-nameplate"],
        )
        self.assertEqual(sum(zone["full_width"] for zone in zones), 1)
        for zone in zones[:2]:
            self.assertTrue(zone["local_vertical_span"])
            self.assertAlmostEqual(zone["width_ratio_to_column"], 1.5)
            self.assertEqual(zone["capacity_min_characters"], 6)
            self.assertEqual(zone["inscription_render_mode"], "exact-glyph-relief")

    def test_geometry_lock_freezes_panel_ratio_and_diamond_upgrade(self):
        geometry = self.load_json(
            "production/symbols/quality-frame-three-text-direction-v3.json"
        )
        self.assertEqual(geometry["version"], "2.0.0")
        self.assertEqual(geometry["geometry_id"], "fool-quality-frame-locked-master-v3")
        panels = geometry["text_zones"]
        self.assertAlmostEqual(panels["side_inlay_width_ratio"], 1.5)
        self.assertEqual(panels["side_inlay_width_ratio_tolerance"], [1.49, 1.51])
        self.assertEqual(panels["full_width_panel_count"], 1)
        self.assertEqual(panels["left"]["inlay_rect_design"], [38, 780, 108, 280])
        self.assertEqual(panels["right"]["inlay_rect_design"], [878, 780, 108, 280])
        self.assertEqual(panels["left"]["text_safe_rect_design"], [50, 796, 84, 248])
        self.assertEqual(panels["right"]["text_safe_rect_design"], [890, 796, 84, 248])
        self.assertEqual(geometry["side_inscription"]["minimum_characters"], 6)
        self.assertEqual(geometry["side_inscription"]["render_mode"], "exact-glyph-relief")
        self.assertEqual(panels["central_nameplate"]["role"], "character_name")
        diamond = geometry["bottom_gemstone"]
        self.assertEqual(diamond["center_design"], [512, 1429])
        self.assertAlmostEqual(diamond["scale_vs_v1"], 1.28)

    def test_catalog_has_exactly_ten_single_tier_emblems(self):
        catalog = self.load_json("production/symbols/fool-five-tier-kit.json")
        self.assertEqual(catalog["version"], "4.0.0")
        self.assertEqual(
            catalog["active_output"], "artifacts/production/fool-five-tier-kit-v4"
        )
        self.assertEqual(len(catalog["emblem_inputs"]), 10)
        self.assertEqual(
            {item["digit"] for item in catalog["emblem_inputs"]}, set(range(10))
        )
        self.assertEqual(
            {item["tier"] for item in catalog["emblem_inputs"]},
            {"low", "mid", "saint", "angel", "true-god"},
        )
        for item in catalog["emblem_inputs"]:
            self.assertEqual(item["color_binding"], item["tier"])

    def test_catalog_mapping_is_one_to_one_and_no_cross_product_output(self):
        catalog = self.load_json("production/symbols/fool-five-tier-kit.json")
        mapping = catalog["sequence_mapping"]
        flattened = [digit for digits in mapping.values() for digit in digits]
        self.assertEqual(sorted(flattened), list(range(10)))
        self.assertEqual(len(flattened), len(set(flattened)))
        output_contract = catalog["output_contract"]
        self.assertEqual(output_contract["emblem_count"], 10)
        self.assertEqual(output_contract["sequence_composition_count"], 10)
        self.assertNotIn("{tier}", output_contract["emblem_name_pattern"])
        self.assertNotIn("{tier}", output_contract["sequence_name_pattern"])

    def test_legacy_four_tier_and_fifty_variant_patterns_are_rejected(self):
        catalog = self.load_json("production/symbols/fool-five-tier-kit.json")
        self.assertFalse(catalog["legacy_four_tier_status"]["active"])
        self.assertNotIn("50", json.dumps(catalog["output_contract"], ensure_ascii=False))

    def test_inscription_contract_is_study_informed_but_exact_and_six_character_safe(self):
        contract = self.load_json(
            "production/symbols/inscriptions/fool-side-inscription-v1.json"
        )
        self.assertEqual(contract["render_policy"]["mode"], "exact-glyph-relief")
        self.assertTrue(contract["render_policy"]["flat_coretext_final_layer_forbidden"])
        self.assertGreaterEqual(contract["capacity"]["minimum_characters"], 6)
        self.assertEqual(contract["geometry"]["width_ratio_to_column"], 1.5)
        self.assertTrue(contract["style_reference"]["pixel_role"].endswith("reference-only"))

    def test_diamond_study_is_five_tier_input_not_a_cross_product(self):
        catalog = self.load_json("production/symbols/fool-five-tier-kit.json")
        study = catalog["diamond_study"]
        self.assertEqual(study["tier_order"], ["low", "mid", "saint", "angel", "true-god"])
        self.assertEqual(len(study["crop_rects_px"]), 5)
        self.assertEqual(catalog["output_contract"]["diamond_layer_names"], [
            "diamond-low.png",
            "diamond-mid.png",
            "diamond-saint.png",
            "diamond-angel.png",
            "diamond-true-god.png",
        ])
        self.assertTrue(catalog["output_contract"]["no_cross_product_variants"])

    @unittest.skipUnless(
        shutil.which("swiftc"),
        "v2 native renderer requires Swift",
    )
    def test_native_renderer_selftest_reports_single_tier_emblem_safety_markers(self):
        with tempfile.TemporaryDirectory(prefix="fool-v2-bin-") as directory:
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
            "v2-three-text-zones",
            "emblem-tier-binding",
            "emblem-alpha-byte-stable",
            "diamond-v2",
            "diamond-study-embedded",
        ):
            self.assertIn(marker, result.stdout)

    @unittest.skipUnless(
        sys.platform == "darwin" and shutil.which("swiftc"),
        "designed inscription renderer requires macOS/Swift",
    )
    def test_inscription_renderer_selftest_reports_width_and_capacity_markers(self):
        with tempfile.TemporaryDirectory(prefix="fool-inscription-bin-") as directory:
            binary = Path(directory) / "fooltext3"
            subprocess.run(
                ["swiftc", "-O", str(ROOT / "tools/render/fooltext3.swift"), "-o", str(binary)],
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
            "local-inlay-1.5x-wider",
            "six-character-inscription-capacity",
            "exact-glyph-relief",
            "empty-character-name-safe",
            "text-orientation-upright-top-left",
            "text-orientation-sentinel",
            "name-ink-premium-relief",
            "inscription-contrast-gated",
        ):
            self.assertIn(marker, result.stdout)

    def test_active_text_manifest_records_orientation_and_visual_contract(self):
        manifest = self.load_json(
            "artifacts/production/fool-three-text-sample-v8/manifest.json"
        )
        self.assertEqual(manifest["version"], 3)
        self.assertEqual(manifest["coordinate_system"], "design-space-top-left-image-normalized")
        self.assertEqual(manifest["orientation"], "upright")
        self.assertTrue(manifest["orientation_sentinel"]["passed"])
        self.assertGreaterEqual(manifest["contrast"]["minimum_ratio"], 4.5)
        self.assertGreaterEqual(manifest["name"]["minimum_cap_height_final_px"], 78)
        self.assertEqual(manifest["geometry"]["max_drift_final_px"], 0)


if __name__ == "__main__":
    unittest.main()
