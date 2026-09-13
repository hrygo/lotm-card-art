"""Native frame preparation regression tests; no network or third-party Python."""
import pathlib
import shutil
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]


class FoolKitTests(unittest.TestCase):
    def test_sample_gate_rejects_tampering_and_overwrite(self):
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            for relative in ["tools/render/foolkit.swift", "production/symbols/fool-kit-matte.json", "artifacts/production/fool-quality-frame-low/v001/raw.png", "artifacts/production/fool-fusion-9/v001/raw.png"]:
                target = root / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(ROOT / relative, target)
            binary = root / "foolkit"
            subprocess.run(["swiftc", "-O", str(root / "tools/render/foolkit.swift"), "-o", str(binary)], check=True, capture_output=True)
            out = root / "artifacts/production/result"
            def run(*args):
                return subprocess.run([str(binary), *map(str, args)], capture_output=True, text=True)
            self.assertEqual(run("prepare", root, out, "sample").returncode, 0)
            checked = run("gate", root, out)
            self.assertEqual(checked.returncode, 0, checked.stderr)
            self.assertNotEqual(run("prepare", root, out, "sample").returncode, 0)
            with (out / "frame-high.png").open("ab") as stream:
                stream.write(b"tampered")
            self.assertNotEqual(run("gate", root, out).returncode, 0)

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
