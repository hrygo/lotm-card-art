"""Delivered material study must survive relocation and reject tampering."""
from pathlib import Path
import shutil
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'tools'))
import production as p
import materialctl as m

PILOT = 'artifacts/production/material-library-v1/r2/fool-low-named'


class MaterialPipelineTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        cls.root = Path(cls.tmp.name)
        seen = set()

        def add(rel):
            if rel in seen:
                return
            seen.add(rel)
            dest = cls.root/rel
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT/rel, dest)

        receipt = p.read(ROOT/PILOT/'receipt.json')
        add(PILOT+'/receipt.json')
        for item in receipt['dependencies'] + receipt['outputs']:
            add(item['path'])
        recipe = p.read(ROOT/PILOT/'recipe.json')
        assets = {n['receipt'] for n in recipe['nodes'] if 'receipt' in n}
        assets.add(recipe['identity']['subject_receipt'])
        for rel in assets:
            add(rel)
            asset = p.read(ROOT/rel)
            for item in asset['snapshot']['dependencies'] + [asset['raw']]:
                add(item['path'])
            for name in ('snapshot.json', 'task.json', 'prompt.txt'):
                add(asset['compiled']+'/'+name)
            if asset['kind'] == 'subject':
                for path in p.cardctl.context_paths(ROOT, ROOT/asset['task']['spec']['semantic_source']):
                    add(path.relative_to(ROOT).as_posix())
        for rel in ('production/schemas/task.schema.json', 'production/schemas/call.schema.json'):
            add(rel)

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def test_relocated_package_passes_without_generated_cache(self):
        self.assertFalse((self.root/'generated').exists())
        self.assertTrue(m.gate(self.root, PILOT)['passed'])

    def test_changed_output_or_component_or_task_blocks(self):
        for rel in (PILOT+'/final.png', 'production/library/components/window-low.json',
                    'production/tasks/material-silver-flat.json'):
            path = self.root/rel; old = path.read_bytes()
            try:
                path.write_bytes(old+b' ')
                with self.subTest(path=rel), self.assertRaisesRegex(p.Invalid, 'stale'):
                    m.gate(self.root, PILOT)
            finally:
                path.write_bytes(old)

    def test_omitted_output_binding_blocks(self):
        path=self.root/PILOT/'receipt.json'; old=path.read_bytes()
        try:
            receipt=p.read(path); receipt['outputs']=receipt['outputs'][1:];p.write(path,receipt)
            with self.assertRaisesRegex(p.Invalid, 'incomplete'):
                m.gate(self.root, PILOT)
        finally:
            path.write_bytes(old)
