"""Exercise real decoding, typesetting and image export, not mocked rendering."""
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import cardctl


@unittest.skipUnless(sys.platform == "darwin" and shutil.which("swiftc"), "native renderer requires macOS/Swift")
class NativeCompositorTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        cls.root = Path(cls.tmp.name)
        cls.binary = cls.root / "compose"
        subprocess.run(["swiftc", str(ROOT/"tools/render/compose.swift"), "-o", str(cls.binary)],
                       check=True, capture_output=True, timeout=180)

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def render(self, shapes, layers=None):
        out = Path(tempfile.mkdtemp(dir=self.root))
        req = {"width": 600, "height": 900, "background":"#152033", "layers":layers or [], "shapes":shapes}
        source = out/"request.json"
        source.write_text(json.dumps(req))
        result = subprocess.run([str(self.binary),str(source),str(out)],capture_output=True,text=True,timeout=60)
        return result,out

    def test_native_chinese_typesetting_and_srgb_png(self):
        result,out = self.render([{"kind":"text","rect":[100,100,800,180],
                                  "text":"占卜家 · 愚者途径","font":"Songti SC","size":50,"fill":"#ffffff","align":"center"}])
        self.assertEqual(result.returncode,0,result.stderr)
        info = cardctl.image_info(out/"final.png")
        self.assertEqual((info["width"],info["height"]),(600,900))
        self.assertTrue(info["color_tags"])
        self.assertTrue(json.loads((out/"renderer.json").read_text())["fonts"][0]["runs"])
        self.assertEqual(cardctl.image_info(out/"preview.png")["width"],360)

    def test_overflow_fails_instead_of_truncating(self):
        result,out = self.render([{"kind":"text","rect":[0,0,40,10],
                                  "text":"不允许隐藏溢出的中文","font":"Songti SC","size":80,"fill":"#ffffff"}])
        self.assertNotEqual(result.returncode,0)
        self.assertIn("overflow",result.stderr)
        self.assertFalse((out/"final.png").exists())

    def test_corrupt_raster_fails(self):
        bad = self.root/"bad.png"
        bad.write_bytes(b"not a png")
        result,out = self.render([], [{"path":str(bad),"rect":[0,0,1000,1500],"opacity":1,"fit":"cover"}])
        self.assertNotEqual(result.returncode,0)
        self.assertFalse((out/"final.png").exists())


if __name__ == "__main__":
    unittest.main()
