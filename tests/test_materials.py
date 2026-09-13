"""Material recipe contract: reject ambiguous geometry before rendering."""
import copy
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import production as p
import materialctl as m


def recipe():
    return {'version': '2.0.0', 'mode': 'material-study', 'id': 'test',
            'profile': 'standard', 'background': '#112233',
            'anchors': {'window': [100, 200, 800, 1000]},
            'nodes': [{'id': 'line', 'shapes': [{'kind': 'rect',
                'rect': [0, 0, 1000, 1500], 'fill': '#778899'}]}]}


class MaterialContractTests(unittest.TestCase):
    def test_valid_recipe(self):
        request, deps = m.compile_recipe(ROOT, recipe())
        self.assertEqual(request['width'], 2048)
        self.assertEqual(request['nodes'][0]['id'], 'line')
        self.assertTrue(deps)

    def test_invalid_inputs(self):
        for key, value in [('mode', 'production'), ('background', 'red'),
                           ('profile', 'unknown'), ('version', '1.0.0'), ('typo', 1)]:
            with self.subTest(key=key):
                data = recipe(); data[key] = value
                with self.assertRaises(p.Invalid):
                    m.compile_recipe(ROOT, data)

    def test_duplicate_nodes_rejected(self):
        data = recipe(); data['nodes'] *= 2
        with self.assertRaisesRegex(p.Invalid, 'duplicate'):
            m.compile_recipe(ROOT, data)

    def test_unknown_node_key_rejected(self):
        data = recipe(); data['nodes'][0]['blend_typo'] = 'screen'
        with self.assertRaises(p.Invalid):
            m.compile_recipe(ROOT, data)

    def test_blend_and_nonfinite_rejected(self):
        for key, val in [('blend', 'erase'), ('opacity', float('nan')),
                         ('brightness', 4), ('feather', -1)]:
            data = recipe(); data['nodes'][0][key] = val
            with self.subTest(key=key), self.assertRaises(p.Invalid):
                m.compile_recipe(ROOT, data)

    def test_invalid_anchor(self):
        data = recipe(); data['anchors']['bad'] = [900, 0, 200, 100]
        with self.assertRaises(p.Invalid):
            m.compile_recipe(ROOT, data)

    def test_anchor_resolves_without_mutating(self):
        data = recipe(); data['nodes'][0]['shapes'][0]['rect'] = 'window'
        original = copy.deepcopy(data)
        request, _ = m.compile_recipe(ROOT, data)
        self.assertEqual(request['nodes'][0]['shapes'][0]['rect'], [100, 200, 800, 1000])
        self.assertEqual(original, data)

    def test_empty_name_blocked(self):
        data = recipe(); data['identity'] = {'test_name': ' ', 'layout':
            {'rect': [100, 1300, 800, 100], 'font': 'Songti SC', 'size': 44,
             'fill': '#ffffff', 'align': 'center'}}
        with self.assertRaises(p.Invalid):
            m.compile_recipe(ROOT, data)

    def test_identity_always_last(self):
        data = recipe(); data['identity'] = {'test_name': '姓名排版测试', 'layout':
            {'rect': [100, 1300, 800, 100], 'font': 'Songti SC', 'size': 44,
             'fill': '#ffffff', 'align': 'center'}}
        request, _ = m.compile_recipe(ROOT, data)
        self.assertEqual(request['nodes'][-1]['id'], '__identity')
        self.assertEqual(request['nodes'][-1]['shapes'][0]['text'], '姓名排版测试')

    def test_release_always_blocked(self):
        with self.assertRaisesRegex(p.Invalid, 'material-study'):
            m.gate(ROOT, 'artifacts/nonexistent', release=True)

    def test_existing_v1_mark_remains_supported(self):
        data = recipe()
        path = ROOT / 'production/assets/fool/rank-9.json'
        data['nodes'] = [{'id':'bad', 'vector': p.record(ROOT, path)}]
        # Existing v1 mark files remain supported; malformed shapes cannot pass.
        request, _ = m.compile_recipe(ROOT, data)
        self.assertTrue(request['nodes'][0]['shapes'])

    def test_name_layout_unknown_field_rejected(self):
        data = recipe(); data['identity'] = {'test_name':'测试', 'layout':
            {'rect':[100,1300,800,100], 'font':'Songti SC', 'size':44,
             'fill':'#ffffff', 'align':'center', 'text':'不允许覆盖姓名'}}
        with self.assertRaises(p.Invalid):
            m.compile_recipe(ROOT, data)

    def test_root_parameter_controls_schema(self):
        from tempfile import TemporaryDirectory
        with TemporaryDirectory() as tmp:
            root = Path(tmp)
            with self.assertRaises((OSError, p.Invalid)):
                m.shapes([{'kind':'rect','rect':[0,0,1000,1500]}], {}, root)
