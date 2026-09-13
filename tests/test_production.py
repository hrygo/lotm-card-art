"""Behavior tests for immutable production tasks and release boundaries."""
import copy
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import production as p


class ProductionTests(unittest.TestCase):
    def task(self):
        return json.loads((ROOT / "production/tasks/subject-fool-09.json").read_text())

    def test_three_real_task_contracts(self):
        for path in (ROOT / "production/tasks").glob("*.json"):
            p.validate_task(ROOT, json.loads(path.read_text()))

    def test_wrong_kind_payload_rejected(self):
        task = self.task()
        task["kind"] = "foundation"
        with self.assertRaises(p.Invalid):
            p.validate_task(ROOT, task)

    def test_protagonist_name_required(self):
        task = self.task()
        task["spec"].pop("protagonist", None)
        with self.assertRaises(p.Invalid):
            p.validate_task(ROOT, task)

    def test_empty_protagonist_name_rejected(self):
        task = self.task()
        task["spec"]["protagonist"] = {"kind":"archetype","name_zh":"  ","name_status":"proposed","evidence_refs":[]}
        with self.assertRaises(p.Invalid):
            p.validate_task(ROOT, task)

    def test_named_character_requires_character_id(self):
        task = self.task()
        task["spec"]["protagonist"] = {"kind":"character","name_zh":"奥黛丽","name_status":"proposed","evidence_refs":[]}
        with self.assertRaises(p.Invalid):
            p.validate_task(ROOT, task)

    def test_nameplate_text_is_derived_not_manual(self):
        task = self.task()
        task["spec"]["protagonist"] = {"kind":"archetype","name_zh":"无名占卜者","name_status":"proposed","evidence_refs":[]}
        layout = {"rect":[160,1325,680,65],"font":"Songti SC","size":42,"fill":"#ffffff","align":"center"}
        result = p.nameplate_shape(task["spec"],layout)
        self.assertEqual(result["text"],"无名占卜者")
        layout["text"] = "错误姓名"
        with self.assertRaises(p.Invalid):
            p.nameplate_shape(task["spec"],layout)

    def test_slot_cannot_disagree_with_source(self):
        task = self.task()
        task["spec"]["slot_id"] = "lotm.fool.s08"
        with self.assertRaises(p.Invalid):
            p.validate_task(ROOT, task)

    def test_outside_reference_rejected(self):
        task = self.task()
        task["references"] = [{"path": "../private.png", "sha256": "a"*64, "role": "style"}]
        with self.assertRaises(p.Invalid):
            p.validate_task(ROOT, task)

    def test_nonfinite_number_rejected(self):
        with self.assertRaises(p.Invalid):
            p.validate_schema(float("nan"), {"type": "number"})

    def test_unknown_fields_rejected(self):
        task = self.task()
        task["auto_approve"] = True
        with self.assertRaises(p.Invalid):
            p.validate_task(ROOT, task)

    def test_bad_reference_hash_rejected(self):
        task = self.task()
        task["references"] = [{"path": "AGENTS.md", "sha256": "a"*64, "role": "style"}]
        with self.assertRaises(p.Invalid):
            p.validate_task(ROOT, task)

    def test_immutable_output(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            out = p.new_output(root, "generated/production/a", "generated/production")
            out.mkdir(parents=True)
            with self.assertRaises(p.Invalid):
                p.new_output(root, "generated/production/a", "generated/production")
            with self.assertRaises(p.Invalid):
                p.new_output(root, "pathways/destroy", "generated/production")

    def test_concept_release_rejected(self):
        with self.assertRaises(p.Invalid):
            p.require_release_mode({"mode": "concept"})

    def test_hash_lock_detects_change(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            file = root / "input.txt"
            file.write_text("first")
            refs = [p.record(root, file)]
            p.verify_records(root, refs)
            file.write_text("second")
            with self.assertRaises(p.Invalid):
                p.verify_records(root, refs)

    def test_shape_command_and_bounds_rejected(self):
        for shape in [
            {"kind": "rect", "rect": [0, 0, 1001, 1500]},
            {"kind": "path", "rect": [0, 0, 1000, 1500], "commands": [["X", 2, 3]]},
            {"kind": "text", "rect": [0, 0, 100, 20], "text": ""},
        ]:
            with self.assertRaises(p.Invalid):
                p.validate_shape(shape)


if __name__ == "__main__":
    unittest.main()
