"""Regression tests for the adopted cross-path sequence rank taxonomy."""

from pathlib import Path
import json
import unittest


ROOT = Path(__file__).resolve().parents[1]


class SequenceHierarchyTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.project = json.loads((ROOT / "config/project.json").read_text(encoding="utf-8"))
        cls.hierarchy_path = ROOT / cls.project["sequence_hierarchy_path"]
        cls.hierarchy = json.loads(cls.hierarchy_path.read_text(encoding="utf-8"))
        cls.schema = json.loads(
            (ROOT / cls.project["sequence_hierarchy_schema_path"]).read_text(encoding="utf-8")
        )

    def test_current_fifth_epoch_mapping_covers_every_sequence_once(self):
        levels = self.hierarchy["sequence_levels"]
        self.assertEqual([level["sequence"] for level in levels], list(range(9, -1, -1)))
        self.assertEqual(
            [level["tier_id"] for level in levels],
            [
                "low_sequence",
                "low_sequence",
                "mid_sequence",
                "mid_sequence",
                "mid_sequence",
                "high_sequence",
                "high_sequence",
                "high_sequence",
                "high_sequence",
                "true_god",
            ],
        )

    def test_state_labels_do_not_turn_king_of_angels_into_a_sequence(self):
        states = {state["id"]: state for state in self.hierarchy["state_labels"]}
        king = states["king_of_angels"]
        self.assertTrue(king["not_a_sequence"])
        self.assertEqual(king["applies_to_sequences"], [1])
        self.assertEqual(states["true_god"]["applies_to_sequences"], [0])

    def test_sequence_zero_is_a_card_slot_not_a_special_event(self):
        policy = self.hierarchy["sequence_zero_card_policy"]
        self.assertEqual(policy["card_kind"], "sequence_card")
        self.assertFalse(policy["is_special_event"])
        self.assertEqual(policy["rank_label_zh"], "真神")

    def test_fool_name_claims_cover_the_full_9_to_0_path(self):
        canon = json.loads((ROOT / "pathways/fool/canon.json").read_text(encoding="utf-8"))
        claims = {
            claim["sequences"][0]: claim
            for claim in canon["claims"]
            if claim["predicate"] == "sequence_name" and len(claim["sequences"]) == 1
        }
        self.assertEqual(sorted(claims, reverse=True), list(range(9, -1, -1)))
        self.assertEqual(claims[0]["value"], "愚者")
        self.assertEqual(claims[1]["value"], "诡秘侍者")
        self.assertTrue(all(claim["verification"]["status"] == "verified" for claim in claims.values()))

    def test_hierarchy_schema_declares_the_sequence_zero_policy(self):
        self.assertEqual(self.schema["properties"]["sequence_levels"]["maxItems"], 10)
        policy = self.schema["properties"]["sequence_zero_card_policy"]["properties"]
        self.assertEqual(policy["card_kind"]["const"], "sequence_card")
        self.assertFalse(policy["is_special_event"]["const"])

    def test_project_references_the_single_hierarchy_source(self):
        self.assertIn("config/sequence-hierarchy.json", self.project["design_document_paths"])
        self.assertIn("schemas/sequence-hierarchy.schema.json", self.project["design_document_paths"])
        self.assertTrue(self.hierarchy_path.is_file())
        schema_path = ROOT / self.project["sequence_hierarchy_schema_path"]
        self.assertTrue(schema_path.is_file())


if __name__ == "__main__":
    unittest.main()
