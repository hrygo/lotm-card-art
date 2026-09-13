"""Native frozen-geometry tests for the single Klein Seer composition."""
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class KleinCarrierTests(unittest.TestCase):
    def test_native_contract(self):
        with tempfile.TemporaryDirectory(prefix="lotm-klein-test-") as temporary:
            binary = str(Path(temporary) / "klein-carrier")
            compile_result = subprocess.run(
                ["swiftc", "-O", str(ROOT / "tools/render/klein_carrier.swift"), "-o", binary],
                capture_output=True, text=True,
            )
            self.assertEqual(compile_result.returncode, 0, compile_result.stderr)
            run = subprocess.run([binary, "selftest"], capture_output=True, text=True)
            self.assertEqual(run.returncode, 0, run.stderr)
            report = json.loads(run.stdout)
            self.assertTrue(report["passed"])
            for key in ["pixel_shift", "internal_change", "hidden_overflow", "edge_alpha",
                        "name_padding", "material_legal", "sampling", "source_hash", "overwrite",
                        "bridge_background", "bridge_enclosed_silver", "opaque_identity"]:
                self.assertTrue(report["checks"][key], key)


if __name__ == "__main__":
    unittest.main()
