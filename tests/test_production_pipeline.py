"""Read-through verification of the delivered pilot in an isolated repository copy."""
from pathlib import Path
import shutil
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/"tools"))
import production as p

PILOT = "artifacts/production/fool-09-pilot/named-v002"


@unittest.skipUnless((ROOT/PILOT/"render-receipt.json").exists(), "delivered pilot not in this checkout")
class ProductionPipelineTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory()
        cls.root = Path(cls.temp.name)
        cls.paths = set()

        def add(rel):
            if rel in cls.paths:
                return
            src = ROOT/rel
            dest = cls.root/rel
            dest.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(src,dest)
            cls.paths.add(rel)

        render = p.read(ROOT/PILOT/"render-receipt.json")
        add(PILOT+"/render-receipt.json")
        add(PILOT+"/review.json")
        for item in render["dependencies"]+[render["manifest"],render["final"],render["preview"]]+render["output_records"]:
            add(item["path"])
        manifest = p.read(ROOT/PILOT/"manifest.json")
        for layer in manifest["layers"]:
            asset = p.read(ROOT/layer["receipt"])
            for item in asset["snapshot"]["dependencies"]+[asset["raw"]]:
                add(item["path"])
            for name in ("snapshot.json","task.json","prompt.txt"):
                add(asset["compiled"]+"/"+name)
            if asset["kind"]=="subject":
                source=ROOT/asset["task"]["spec"]["semantic_source"]
                for path in p.cardctl.context_paths(ROOT,source):
                    add(path.relative_to(ROOT).as_posix())
        for rel in ("production/schemas/task.schema.json","production/schemas/call.schema.json",
                    "production/schemas/composition.schema.json","config/project.json"):
            add(rel)

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    def test_self_contained_after_generated_cache_is_removed(self):
        self.assertFalse((self.root/"generated").exists())
        self.assertTrue(p.gate(self.root,PILOT)["passed"])

    def test_pilot_release_is_blocked(self):
        with self.assertRaisesRegex(p.Invalid,"concept"):
            p.gate(self.root,PILOT,release=True)

    def test_protagonist_name_is_present_in_actual_typesetting(self):
        receipt = p.read(self.root/PILOT/"render-receipt.json")
        self.assertIn("无名占卜者", [item["text"] for item in receipt["renderer"]["fonts"]])

    def test_changed_final_invalidates_gate(self):
        path=self.root/PILOT/"final.png"
        old=path.read_bytes()
        try:
            path.write_bytes(old+b"changed")
            with self.assertRaisesRegex(p.Invalid,"stale"):
                p.gate(self.root,PILOT)
        finally:
            path.write_bytes(old)

    def test_changed_vector_invalidates_gate(self):
        path=self.root/"production/assets/fool/rank-9.json"
        old=path.read_bytes()
        try:
            path.write_bytes(old+b" ")
            with self.assertRaisesRegex(p.Invalid,"stale"):
                p.gate(self.root,PILOT)
        finally:
            path.write_bytes(old)

    def test_changed_task_invalidates_gate(self):
        path=self.root/"production/tasks/subject-fool-09.json"
        old=path.read_bytes()
        try:
            path.write_bytes(old+b" ")
            with self.assertRaisesRegex(p.Invalid,"stale"):
                p.gate(self.root,PILOT)
        finally:
            path.write_bytes(old)


if __name__=="__main__":
    unittest.main()
