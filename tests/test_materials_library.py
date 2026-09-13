"""The catalog is an inventory of usable files, not a count of intentions."""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'tools'))
import production as p
import materialctl as m


class MaterialLibraryTests(unittest.TestCase):
    def test_rasters_are_distinct_registered_assets(self):
        catalog=p.read(ROOT/'production/library/catalog.json')
        digests=set()
        for item in catalog['raster_assets']:
            asset=p.check_asset(ROOT,item['receipt'])
            digests.add(asset['raw']['sha256'])
            self.assertEqual(asset['approval']['status'],'pending')
        self.assertEqual(len(digests),5)

    def test_components_and_marks_resolve(self):
        catalog=p.read(ROOT/'production/library/catalog.json')
        for item in catalog['components']+catalog['composite_marks']:
            p.verify_records(ROOT,[item])
            asset=p.read(ROOT/item['path'])
            self.assertEqual(asset['status'],'proposed')
            m.shapes(asset['shapes'],{},ROOT)

    def test_every_recipe_and_output_is_current(self):
        catalog=p.read(ROOT/'production/library/catalog.json')
        for job in catalog['render_jobs']:
            with self.subTest(id=job['id']):
                m.compile_recipe(ROOT,p.read(ROOT/job['recipe']))
                self.assertTrue(m.gate(ROOT,job['output'])['passed'])

    def test_real_alpha_not_merely_an_alpha_channel(self):
        meta=p.read(ROOT/'artifacts/production/material-library-v1/r2/alpha-white/renderer.json')
        alpha=meta['inputs'][0]['alpha']
        self.assertGreater(alpha['transparent'],1000000)
        self.assertGreater(alpha['partial'],10000)
        self.assertTrue(alpha['has_real_transparency'])
