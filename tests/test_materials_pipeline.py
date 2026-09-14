"""Regression checks for the post-cleanup material-production boundary."""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import production as p


class MaterialPipelineTests(unittest.TestCase):
    def test_retired_material_studies_are_not_current_inputs(self):
        catalog = p.read(ROOT / 'production/library/catalog.json')
        self.assertEqual(catalog['status'], 'retired-historical')
        self.assertFalse(catalog['active'])
        self.assertEqual(catalog['render_jobs'], [])
        for rel in (
            'artifacts/production/material-library-v1',
            'artifacts/production/material-studies',
            'artifacts/production/sacred-slate-master',
        ):
            self.assertFalse((ROOT / rel).exists(), rel)

    def test_current_native_baseline_is_the_only_material_gate(self):
        report = p.validate_fool_materials(ROOT)
        self.assertEqual(report['status'], 'passed')
        self.assertEqual(report['retained_reusable_material_count'], 5)
        self.assertEqual(report['intermediate_2k_count'], 0)


if __name__ == '__main__':
    unittest.main()
