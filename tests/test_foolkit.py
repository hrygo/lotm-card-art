"""Native frame preparation regression tests; no network or third-party Python."""
import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]


class FoolKitTests(unittest.TestCase):
    def test_legacy_route_does_not_fallback_after_retirement(self):
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            binary = root / "foolkit"
            subprocess.run(["swiftc", "-O", str(ROOT / "tools/render/foolkit.swift"), "-o", str(binary)], check=True, capture_output=True)
            out = root / "artifacts/production/result"
            def run(*args):
                return subprocess.run([str(binary), *map(str, args)], capture_output=True, text=True)
            result = run("prepare", root, out, "sample")
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("fool-quality-frame-low/v001/raw.png", result.stderr)

    def test_native_geometry_and_matte_regressions(self):
        with tempfile.TemporaryDirectory() as directory:
            binary = pathlib.Path(directory) / "foolkit"
            compiled = subprocess.run(
                ["swiftc", "-O", str(ROOT / "tools/render/foolkit.swift"), "-o", str(binary)],
                capture_output=True, text=True,
            )
            self.assertEqual(compiled.returncode, 0, compiled.stderr)
            result = subprocess.run([str(binary), "selftest"], capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("shift-rejected", result.stdout)
            self.assertIn("checker-removed", result.stdout)
            self.assertIn("highlight-preserved", result.stdout)
            self.assertIn("seed-hole-removed", result.stdout)
            self.assertIn("material-alpha-unchanged", result.stdout)


if __name__ == "__main__":
    unittest.main()
