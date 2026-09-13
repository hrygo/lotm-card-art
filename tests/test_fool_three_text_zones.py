"""Contract tests for the Fool v2 three-text-zone frame template."""

import json
from pathlib import Path
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
        template = self.load_json("production/templates/card-text-panels.json")
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
            self.assertGreaterEqual(zone["width_ratio_to_column"], 1.12)
            self.assertLessEqual(zone["width_ratio_to_column"], 1.18)

    def test_geometry_lock_freezes_panel_ratio_and_diamond_upgrade(self):
        geometry = self.load_json(
            "production/symbols/quality-frame-three-text-direction.json"
        )
        self.assertEqual(geometry["version"], "1.0.0")
        self.assertEqual(geometry["geometry_id"], "fool-quality-frame-locked-master-v2")
        panels = geometry["text_zones"]
        self.assertAlmostEqual(panels["side_inlay_width_ratio"], 1.15)
        self.assertEqual(panels["side_inlay_width_ratio_tolerance"], [1.12, 1.18])
        self.assertEqual(panels["full_width_panel_count"], 1)
        self.assertEqual(panels["central_nameplate"]["role"], "character_name")
        diamond = geometry["bottom_gemstone"]
        self.assertEqual(diamond["center_design"], [512, 1429])
        self.assertAlmostEqual(diamond["scale_vs_v1"], 1.28)

    def test_catalog_has_exactly_ten_single_tier_emblems(self):
        catalog = self.load_json("production/symbols/fool-five-tier-kit.json")
        self.assertEqual(catalog["version"], "3.0.0")
        self.assertEqual(
            catalog["active_output"], "artifacts/production/fool-five-tier-kit-v2"
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


if __name__ == "__main__":
    unittest.main()
