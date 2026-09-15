"""Current art-contract and narrative approval boundaries; no service calls."""
import copy
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import production as p


class CurrentContractTests(unittest.TestCase):
    def test_all_ten_sequences_resolve_from_five_tiers(self):
        expected = ["true-god", "angel", "angel", "saint", "saint",
                    "mid", "mid", "mid", "low", "low"]
        self.assertEqual([p.visual_quality(ROOT, n)["id"] for n in range(10)], expected)
        for bad in [-1, 10, True, "9"]:
            with self.assertRaises(p.Invalid):
                p.visual_quality(ROOT, bad)

    def test_quality_tier_mapping_derives_from_the_single_source(self):
        self.assertEqual(
            p.quality_tier_mapping(ROOT),
            {"low": [9, 8], "mid": [7, 6, 5], "saint": [4, 3], "angel": [2, 1], "true-god": [0]},
        )
        self.assertEqual(list(p.quality_tier_mapping(ROOT)), list(p.TIER_ORDER))

    def test_non_bijective_quality_config_is_rejected(self):
        def synthetic(tiers):
            holder = tempfile.TemporaryDirectory()
            self.addCleanup(holder.cleanup)
            root = Path(holder.name)
            (root / "config").mkdir()
            p.write(root / "config/quality-color-tokens.json", {"tiers": tiers})
            return root

        valid = p.read(ROOT / "config/quality-color-tokens.json")["tiers"]
        cases = {
            "duplicate sequence": [dict(valid[0], sequences=[9, 9]), *valid[1:]],
            "missing sequence": [dict(valid[0], sequences=[9]), *valid[1:]],
            "unknown tier id": [dict(valid[0], id="saintly"), *valid[1:]],
            "non-integer sequence": [dict(valid[0], sequences=["9", 8]), *valid[1:]],
            "dropped tier": valid[:4],
        }
        for label, tiers in cases.items():
            with self.subTest(case=label):
                with self.assertRaises(p.Invalid):
                    p.quality_tiers(synthetic(tiers))

    def test_quality_task_accepts_saint_but_rejects_mismatch(self):
        task = p.read(ROOT / "production/tasks/hierarchy-low.json")
        task["quality"] = {"sequence": 4, "visual_tier": "saint"}
        task["spec"]["tier"] = "saint"
        p.validate_task(ROOT, task)
        task["quality"]["visual_tier"] = "angel"
        with self.assertRaises(p.Invalid):
            p.validate_task(ROOT, task)
        task["quality"]["visual_tier"] = "saint"
        task["spec"]["tier"] = "high"
        with self.assertRaises(p.Invalid):
            p.validate_task(ROOT, task)
        task["spec"]["tier"] = "angel"
        task.pop("quality")
        with self.assertRaises(p.Invalid):
            p.validate_task(ROOT, task)

    def test_snapshot_binds_current_contracts_and_rejects_omission(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            for rel in ["tools", "production/schemas", "docs", "config", ".agents/skills"]:
                shutil.copytree(ROOT / rel, root / rel)
            task = p.read(ROOT / "production/tasks/hierarchy-low.json")
            task["references"] = []
            sidecar = root / "brief.json"
            p.write(sidecar, {"geometry_id": "test-only"})
            task["contracts"] = [p.record(root, sidecar)]
            p.write(root / "task.json", task)
            out = p.compile_task(root, "task.json", "generated/production/test")
            p.check_snapshot(root, out)
            self.assertEqual((out / "prompt.txt").read_text(), task["prompt"] + "\n")
            self.assertEqual(p.read(out / "task.json")["references"], [])
            snap = p.read(out / "snapshot.json")
            paths = {d["path"] for d in snap["dependencies"]}
            self.assertTrue({"docs/production-sop-v3.md", "config/quality-color-tokens.json",
                             "docs/card-narrative-contract.md", "brief.json"} <= paths)
            original = copy.deepcopy(snap)
            snap["dependencies"] = [d for d in snap["dependencies"]
                                    if d["path"] != "config/quality-color-tokens.json"]
            p.write(out / "snapshot.json", snap)
            with self.assertRaises(p.Invalid):
                p.check_snapshot(root, out)
            p.write(out / "snapshot.json", original)
            p.write(sidecar, {"geometry_id": "changed"})
            with self.assertRaises(p.Invalid):
                p.check_snapshot(root, out)
            p.write(sidecar, {"geometry_id": "test-only"})
            palette = root / "config/quality-color-tokens.json"
            data = p.read(palette)
            data["tiers"][0]["primary"] = "#000000"
            p.write(palette, data)
            with self.assertRaises(p.Invalid):
                p.check_snapshot(root, out)


class NarrativeContractTests(unittest.TestCase):
    def pack(self):
        return p.read(ROOT / "production/templates/card-narrative.json")

    def test_pending_pack_is_not_audio_ready(self):
        pack = self.pack()
        p.validate_narrative(ROOT, pack)
        with self.assertRaises(p.Invalid):
            p.validate_narrative(ROOT, pack, ready_for_audio=True)

    def test_approved_text_is_bound_to_identity_and_source(self):
        pack = self.pack()
        for entry in pack["entries"]:
            entry["text"] = "仅用于测试的原创文案。"
            entry["gap"] = None
            entry["contentDigest"] = p.narrative_digest(pack, entry)
            entry["review"] = {"status": "approved", "approvedDigest": entry["contentDigest"],
                               "by": "test-reviewer", "reference": "test-only approval"}
        p.validate_narrative(ROOT, pack, ready_for_audio=True)
        for mutate in [lambda q: q["identity"].update(identitySliceID="another-period"),
                       lambda q: q["entries"][0].update(text="改写后的文案"),
                       lambda q: q["entries"][0].update(sourceKind="interpretation")]:
            changed = copy.deepcopy(pack)
            mutate(changed)
            with self.assertRaises(p.Invalid):
                p.validate_narrative(ROOT, changed, ready_for_audio=True)

    def test_canon_without_evidence_or_duplicate_id_rejected(self):
        pack = self.pack()
        pack["entries"][0]["sourceKind"] = "canon"
        pack["entries"][0]["text"] = "不得冒充原著引文。"
        with self.assertRaises(p.Invalid):
            p.validate_narrative(ROOT, pack)

    def test_missing_story_and_empty_approval_evidence_rejected(self):
        pack = self.pack()
        pack["entries"][2]["kind"] = "catchphrase"
        with self.assertRaises(p.Invalid):
            p.validate_narrative(ROOT, pack)
        pack = self.pack()
        entry = pack["entries"][0]
        entry.update(text="测试原创。", gap=None)
        entry["contentDigest"] = p.narrative_digest(pack, entry)
        entry["review"].update(status="approved", approvedDigest=entry["contentDigest"])
        with self.assertRaises(p.Invalid):
            p.validate_narrative(ROOT, pack)

    def test_subject_narrative_identity_binding(self):
        task = p.read(ROOT / "production/tasks/subject-fool-09.json")
        task["narrative"] = p.record(ROOT, ROOT / "production/templates/card-narrative.json")
        with self.assertRaisesRegex(p.Invalid, "identity disagree"):
            p.validate_task(ROOT, task)
        pack = self.pack()
        pack["entries"][1]["id"] = pack["entries"][0]["id"]
        with self.assertRaises(p.Invalid):
            p.validate_narrative(ROOT, pack)


class CarrierGeometrySingleSourceTests(unittest.TestCase):
    def contract(self):
        return json.loads((ROOT / "production/symbols/fool-carrier-execution-v1.json").read_text(encoding="utf-8"))

    def test_carrier_geometry_contract_is_hash_locked_by_a_pin(self):
        task = json.loads((ROOT / "production/tasks/fool-five-tier-frame-batch-v1.json").read_text(encoding="utf-8"))
        paths = [entry["path"] for entry in task["contracts"]]

        self.assertIn("production/symbols/fool-carrier-execution-v1.json", paths)

    def test_live_carrier_geometry_satisfies_the_relational_invariants(self):
        p._require_carrier_geometry_invariants(self.contract(), "fool")

    def test_off_center_gem_slot_is_rejected(self):
        contract = self.contract()
        contract["anchors"]["gem_slot"]["center_design"][0] = 500.0

        with self.assertRaisesRegex(p.Invalid, "not centered on the name surface"):
            p._require_carrier_geometry_invariants(contract, "fool")

    def test_gem_slot_intruding_into_name_clearance_is_rejected(self):
        contract = self.contract()
        contract["anchors"]["gem_slot"]["center_design"][1] = 1200.0

        with self.assertRaisesRegex(p.Invalid, "intrudes into the name surface clearance"):
            p._require_carrier_geometry_invariants(contract, "fool")

    def test_rank_numeral_dock_off_canvas_center_is_rejected(self):
        contract = self.contract()
        contract["anchors"]["rank_numeral_dock"]["center_design"][0] = 400.0

        with self.assertRaisesRegex(p.Invalid, "not centered on the canvas"):
            p._require_carrier_geometry_invariants(contract, "fool")

    def test_safe_rect_escaping_its_anchor_is_detected(self):
        self.assertTrue(p._rect_contains([0, 0, 10, 10], [1, 1, 8, 8]))
        self.assertFalse(p._rect_contains([0, 0, 10, 10], [5, 5, 10, 10]))


if __name__ == "__main__":
    unittest.main()
