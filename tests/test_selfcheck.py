"""fresh checkout 自证脚本的组成与错误路径（不执行重步骤）。"""

import io
from contextlib import redirect_stdout
from pathlib import Path
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import selfcheck


class SelfcheckTests(unittest.TestCase):
    def test_list_covers_scaffold_pins_gates_and_suite(self):
        out = io.StringIO()
        with redirect_stdout(out):
            code = selfcheck.main(["--list"])

        self.assertEqual(code, 0)
        listed = out.getvalue()
        for needle in (
            "scaffold",
            "pin_seal.py --check",
            "check-fool-materials",
            "check-fool-cards",
            "unittest discover -s tests",
        ):
            self.assertIn(needle, listed)

    def test_missing_repository_root_is_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            code = selfcheck.main(["--root", tmp])

        self.assertEqual(code, 2)
        self.assertTrue((ROOT / "tools" / "cardctl.py").is_file())


if __name__ == "__main__":
    unittest.main()
