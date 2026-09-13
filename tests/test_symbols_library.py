"""Art inventory checks do not substitute for visual approval."""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import production as p
import materialctl as m


class SymbolLibraryTests(unittest.TestCase):
    def catalog(self):
        return p.read(ROOT / 'production/symbols/catalog.json')

    def test_all_pathways_have_distinct_real_emblems(self):
        items = self.catalog()['emblems']
        expected = {item['id'] for item in p.read(ROOT / 'catalog/pathways.json')['pathways']}
        self.assertEqual({item['pathway_id'] for item in items}, expected)
        hashes = {p.check_asset(ROOT, item['receipt'])['raw']['sha256'] for item in items}
        self.assertEqual(len(hashes), 22)

    def test_assets_remain_unapproved_and_traceable(self):
        catalog = self.catalog()
        for item in catalog['emblems'] + catalog['numerals'] + catalog['fusions'] + catalog['frames']:
            with self.subTest(id=item['id']):
                asset = p.check_asset(ROOT, item['receipt'])
                self.assertEqual(asset['approval']['status'], 'pending')

    def test_exact_digit_and_tier_inventory(self):
        catalog = self.catalog()
        self.assertEqual(sorted(item['digit'] for item in catalog['numerals']), list(range(10)))
        self.assertEqual({item['tier'] for item in catalog['frames']}, {'low', 'mid', 'high', 'true-god'})
        self.assertEqual({item['digit'] for item in catalog['fusions']}, {0, 4, 7, 9})
        self.assertTrue(all(item['pathway_id'] == 'fool' for item in catalog['numerals'] + catalog['fusions'] + catalog['frames']))

    def test_current_render_jobs_have_real_alpha(self):
        for job in self.catalog()['render_jobs']:
            with self.subTest(id=job['id']):
                self.assertTrue(m.gate(ROOT, job['output'])['passed'])
                metadata = p.read(ROOT / job['output'] / 'renderer.json')
                for source in metadata['inputs']:
                    self.assertTrue(source['alpha']['has_real_transparency'])
                    self.assertGreater(source['alpha']['transparent'], 10000)

    def test_frame_safe_area_limits_are_not_hidden(self):
        checks = p.read(ROOT / 'production/symbols/frame-window-check.json')
        self.assertFalse(checks['requested_window_passed'])
        self.assertEqual(checks['threshold_alpha'], 0.01)
        self.assertEqual(len(checks['frames']), 4)
        self.assertTrue(all(row['conservative_clear_fraction'] >= 0.9999 for row in checks['frames']))

    def test_failed_fusions_cannot_be_counted_as_transparent_assets(self):
        catalog = self.catalog()
        self.assertEqual(catalog['transparent_candidate_files'], 36)
        for item in catalog['fusions']:
            self.assertEqual(item['status'], 'blocked-alpha')
            self.assertFalse(item['usable_as_transparent_layer'])
            p.check_asset(ROOT, item['failed_repair_receipt'])
        metadata = p.read(ROOT / catalog['diagnostic_jobs'][0]['output'] / 'renderer.json')
        rejected = [source for source in metadata['inputs'] if not source['alpha']['has_real_transparency']]
        self.assertEqual(len(rejected), 4)
