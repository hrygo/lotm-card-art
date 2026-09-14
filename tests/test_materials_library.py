"""Current reusable-material checks and the retired material-study boundary."""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'tools'))
import production as p
import materialctl as m


class MaterialLibraryTests(unittest.TestCase):
    def test_retained_materials_are_distinct_native_registered_references(self):
        catalog = p.read(ROOT / 'production/symbols/fool-five-tier-kit.json')
        retained = catalog['retained_reusable_materials']
        self.assertEqual(retained['status'], 'retained-reference-assets')
        self.assertFalse(retained['embedded_in_active_frames'])
        digests=set()
        for item in retained['entries']:
            raw_path = ROOT / item['path']
            receipt_path = raw_path.parent / 'receipt.json'
            receipt = p.read(receipt_path)
            self.assertEqual(receipt['raw']['path'], item['path'])
            self.assertEqual(receipt['raw']['sha256'], item['sha256'])
            self.assertEqual(p.sha(raw_path), item['sha256'])
            self.assertEqual(p.cardctl.image_info(raw_path)['format'], 'PNG')
            self.assertEqual([p.cardctl.image_info(raw_path)['width'], p.cardctl.image_info(raw_path)['height']], item['size_px'])
            self.assertEqual(item['status'], 'retained-reference')
            digests.add(item['sha256'])
        self.assertEqual(len(digests),5)

    def test_material_study_catalog_is_retired_and_does_not_publish_outputs(self):
        catalog = p.read(ROOT / 'production/library/catalog.json')
        self.assertEqual(catalog['status'], 'retired-historical')
        self.assertFalse(catalog['active'])
        self.assertEqual(catalog['replacement_catalog'], 'production/symbols/fool-five-tier-kit.json')
        self.assertEqual(catalog['render_jobs'], [])
        self.assertEqual(len(catalog['historical_render_jobs']), 11)

    def test_components_and_marks_resolve(self):
        catalog = p.read(ROOT / 'production/library/catalog.json')
        for item in catalog['components'] + catalog['composite_marks']:
            p.verify_records(ROOT, [item])
            asset = p.read(ROOT / item['path'])
            self.assertEqual(asset['status'], 'proposed')
            m.shapes(asset['shapes'], {}, ROOT)

    def test_current_validator_reports_retained_reusable_materials(self):
        report = p.validate_fool_materials(ROOT)
        self.assertEqual(report['status'], 'passed')
        self.assertEqual(report['retained_reusable_material_count'], 5)
