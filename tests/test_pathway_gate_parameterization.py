"""Pathway gate parameterization: identity binding, namespacing, no silent pass."""

import json
from pathlib import Path
import sys
import unittest


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import production


class PathwayGateParameterizationTests(unittest.TestCase):
    def test_generic_entry_is_equivalent_to_the_fool_wrapper(self):
        self.assertEqual(
            production.validate_pathway_materials(ROOT, "fool"),
            production.validate_fool_materials(ROOT),
        )
        self.assertEqual(
            production.validate_pathway_carrier_contract(ROOT, "fool"),
            production.validate_fool_carrier_contract(ROOT),
        )

    def test_fool_keeps_the_frozen_flat_layout_and_others_use_the_namespace(self):
        fool = production.pathway_material_context(ROOT, "fool")
        self.assertEqual(fool["form"], "legacy-flat")
        self.assertEqual(fool["label"], "Fool")
        self.assertEqual(fool["five_tier_catalog"], "production/symbols/fool-five-tier-kit.json")
        other = production.pathway_material_context(ROOT, "door")
        self.assertEqual(other["form"], "namespaced")
        self.assertEqual(other["label"], "door")
        self.assertTrue(other["carrier_contract"].startswith("production/symbols/door/"))

    def test_every_catalog_pathway_resolves_to_its_own_asset_root(self):
        catalog = json.loads((ROOT / "catalog/pathways.json").read_text(encoding="utf-8"))
        roots = {}
        for entry in catalog["pathways"]:
            context = production.pathway_material_context(ROOT, entry["id"])
            self.assertEqual(context["pathway_id"], entry["id"])
            self.assertEqual(context["geometry_id"], f"{entry['id']}-agentic-mother-v2")
            roots[entry["id"]] = context["carrier_contract"]
        self.assertEqual(len(roots), len(catalog["pathways"]))
        self.assertEqual(len(set(roots.values())), len(catalog["pathways"]))
        self.assertEqual(roots["fool"], "production/symbols/fool-carrier-execution-v1.json")
        for pathway_id, rel in roots.items():
            if pathway_id != "fool":
                self.assertEqual(rel, f"production/symbols/{pathway_id}/carrier-execution.json")

    def test_unproduced_pathways_fail_loudly_and_name_their_contract(self):
        for pathway_id in ("door", "error", "sun"):
            with self.subTest(pathway=pathway_id):
                with self.assertRaises(production.Invalid) as caught:
                    production.validate_pathway_materials(ROOT, pathway_id)
                self.assertIn(f"production/symbols/{pathway_id}/carrier-execution.json", str(caught.exception))

    def test_unknown_pathway_cannot_be_validated(self):
        with self.assertRaises(production.Invalid):
            production.validate_pathway_materials(ROOT, "not-a-pathway")


if __name__ == "__main__":
    unittest.main()
