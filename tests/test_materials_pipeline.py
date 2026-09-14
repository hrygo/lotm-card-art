"""Regression checks for the current Fool five-tier retained-material gate."""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import production as p


class MaterialGateTests(unittest.TestCase):
    def test_current_native_baseline_is_the_only_material_gate(self):
        report = p.validate_fool_materials(ROOT)
        self.assertEqual(report['status'], 'passed')
        self.assertEqual(report['retained_reusable_material_count'], 5)
        self.assertEqual(report['intermediate_2k_count'], 0)

    def test_retained_materials_are_distinct_native_registered_references(self):
        catalog = p.read(ROOT / 'production/symbols/fool-five-tier-kit.json')
        retained = catalog['retained_reusable_materials']
        self.assertEqual(retained['status'], 'retained-reference-assets')
        self.assertFalse(retained['embedded_in_active_frames'])
        digests = set()
        for item in retained['entries']:
            raw_path = ROOT / item['path']
            receipt_path = raw_path.parent / 'receipt.json'
            receipt = p.read(receipt_path)
            self.assertEqual(receipt['raw']['path'], item['path'])
            self.assertEqual(receipt['raw']['sha256'], item['sha256'])
            self.assertEqual(p.sha(raw_path), item['sha256'])
            self.assertEqual(p.cardctl.image_info(raw_path)['format'], 'PNG')
            self.assertEqual(
                [p.cardctl.image_info(raw_path)['width'], p.cardctl.image_info(raw_path)['height']],
                item['size_px'],
            )
            self.assertEqual(item['status'], 'retained-reference')
            digests.add(item['sha256'])
        self.assertEqual(len(digests), 5)

    def test_current_validator_reports_retained_reusable_materials(self):
        report = p.validate_fool_materials(ROOT)
        self.assertEqual(report['status'], 'passed')
        self.assertEqual(report['retained_reusable_material_count'], 5)


if __name__ == '__main__':
    unittest.main()
