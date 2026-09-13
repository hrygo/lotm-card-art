"""Pixel outcomes from the real native materials renderer."""
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class MaterialNativeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        cls.root = Path(cls.tmp.name)
        cls.binary = cls.root / 'materials'
        result = subprocess.run(['swiftc', str(ROOT/'tools/render/materials.swift'),
            '-o', str(cls.binary)], capture_output=True, text=True, timeout=180)
        if result.returncode:
            raise AssertionError(result.stderr)

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def draw(self, nodes, background='#ffffff', probes=None):
        out = Path(tempfile.mkdtemp(dir=self.root))
        req = {'width': 200, 'height': 300, 'background': background, 'nodes': nodes,
               'probes': probes or [[500, 750]]}
        (out/'request.json').write_text(json.dumps(req))
        result = subprocess.run([str(self.binary), str(out/'request.json'), str(out)],
                                capture_output=True, text=True, timeout=60)
        return result, out

    def node(self, fill='#ff0000'):
        return {'id': 'test', 'shapes': [{'kind':'rect', 'rect':[0,0,1000,1500], 'fill':fill}]}

    def test_order_and_multiply(self):
        a = self.node('#808080'); b = self.node('#808080'); b['blend'] = 'multiply'
        result, out = self.draw([a, b])
        self.assertEqual(result.returncode, 0, result.stderr)
        pixel = json.loads((out/'renderer.json').read_text())['probes'][0]['rgba']
        self.assertAlmostEqual(pixel[0], 64, delta=3)
        result, out = self.draw([self.node(), self.node('#0000ff')])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads((out/'renderer.json').read_text())['probes'][0]['rgba'][:3], [0,0,255])

    def test_evenodd_hole_reveals_background(self):
        node = self.node()
        node['mask'] = [{'kind':'path', 'rect':[0,0,1000,1500], 'fill':'#ffffff',
            'commands':[['M',0,0],['L',1000,0],['L',1000,1500],['L',0,1500],['Z'],
                        ['M',200,200],['L',800,200],['L',800,1300],['L',200,1300],['Z']]}]
        result, out = self.draw([node])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads((out/'renderer.json').read_text())['probes'][0]['rgba'], [255]*4)

    def test_feather_and_transparent_canvas(self):
        node = self.node(); node['feather'] = 20
        node['mask'] = [{'kind':'rect','rect':[250,250,500,1000],'fill':'#ffffff'}]
        result, out = self.draw([node], 'none', [[250,750],[500,750],[100,750]])
        self.assertEqual(result.returncode, 0, result.stderr)
        pixels = json.loads((out/'renderer.json').read_text())['probes']
        self.assertTrue(40 < pixels[0]['rgba'][3] < 220, pixels)
        self.assertEqual(pixels[1]['rgba'][3], 255)
        self.assertEqual(pixels[2]['rgba'][3], 0)

    def test_brightness_changes_pixel(self):
        node = self.node('#404040'); node['brightness'] = .15
        result, out = self.draw([node])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertGreater(json.loads((out/'renderer.json').read_text())['probes'][0]['rgba'][0], 64)

    def test_long_name_overflow_is_error(self):
        node = {'id':'name', 'shapes':[{'kind':'text', 'rect':[0,0,40,10],
                'text':'很长的主角姓名', 'font':'Songti SC', 'size':44, 'fill':'#ffffff'}]}
        result, out = self.draw([node])
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('overflow', result.stderr)
        self.assertFalse((out/'final.png').exists())

    def test_corrected_title_box_fits_without_shrinking(self):
        node = {'id':'title', 'shapes':[{'kind':'text', 'rect':[200,232,600,70],
            'text':'占 卜 家', 'font':'Songti SC', 'size':42, 'fill':'#ffffff'}]}
        result, out = self.draw([node])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads((out/'renderer.json').read_text())['fonts'][0]['text'], '占 卜 家')

    def test_screen_pixel(self):
        a=self.node('#808080'); b=self.node('#808080'); b['blend']='screen'
        result, out = self.draw([a,b])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertAlmostEqual(json.loads((out/'renderer.json').read_text())['probes'][0]['rgba'][0],192,delta=3)

    def test_shadow_produces_contact_pixels(self):
        node = {'id':'square','shapes':[{'kind':'rect','rect':[300,300,200,200], 'fill':'#ffffff'}],
                'shadow':{'x':20,'y':20,'blur':3,'opacity':1}}
        result, out = self.draw([node], '#ffffff', [[510,400]])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertLess(json.loads((out/'renderer.json').read_text())['probes'][0]['rgba'][0], 128)
