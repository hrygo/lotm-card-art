"""Contract-first tests for the Fool Agentic mother-to-sequence pipeline."""

import hashlib
import json
from pathlib import Path
import shutil
import sys
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import production


class MotherContractTests(unittest.TestCase):
    def load(self, relative: str) -> dict:
        with (ROOT / relative).open(encoding="utf-8") as stream:
            return json.load(stream)

    def test_mother_interface_freezes_empty_zones_and_single_gem_slot(self):
        template = self.load("production/templates/fool-mother-frame-interface-v1.json")
        self.assertEqual(template["schema_version"], "1.0.0")
        self.assertEqual(template["geometry_id"], "fool-agentic-mother-v2")
        self.assertEqual(template["coordinate_system"], "design-space-top-left-image-normalized")
        self.assertEqual(template["right_sequence_zone"]["status"], "reserved-empty")
        self.assertEqual(template["name_surface"]["background_pixels"], 0)
        self.assertEqual(template["gem_slot"]["count"], 1)
        self.assertEqual(template["gem_slot"]["tier_variant_count"], 5)
        self.assertEqual(template["thresholds"]["geometry_displacement_max_px"], 0)
        self.assertEqual(template["thresholds"]["outside_edit_domain_pixels_max"], 0)

    def test_catalog_has_five_tier_assets_and_ten_sequence_outputs(self):
        catalog = self.load("production/symbols/fool-mother-frame-v1.json")
        self.assertEqual(catalog["version"], "1.0.0")
        self.assertEqual(catalog["pathway_id"], "fool")
        self.assertEqual(
            catalog["sequence_mapping"],
            {"low": [9, 8], "mid": [7, 6, 5], "saint": [4, 3], "angel": [2, 1], "true-god": [0]},
        )
        self.assertEqual(catalog["tier_order"], ["low", "mid", "saint", "angel", "true-god"])
        self.assertEqual(len(catalog["sequence_outputs"]), 10)
        self.assertEqual({row["digit"] for row in catalog["sequence_outputs"]}, set(range(10)))
        self.assertEqual({row["tier"] for row in catalog["sequence_outputs"]}, set(catalog["tier_order"]))
        self.assertEqual(len(catalog["approved_emblems"]), 10)
        self.assertTrue(catalog["no_cross_product_variants"])
        self.assertEqual(catalog["status"], "historical-interface-contract")

    def test_batch_tasks_use_explicit_stage_contracts(self):
        expected = {
            "fool-mother-frame-v1.json": "mother",
            "fool-five-tier-frame-batch-v1.json": "tiers",
            "fool-ten-sequence-frame-batch-v1.json": "sequences",
        }
        for filename, stage in expected.items():
            task = self.load(f"production/tasks/{filename}")
            self.assertEqual(task["kind"], "hierarchy")
            self.assertEqual(task["mode"], "concept")
            self.assertEqual(task["spec"]["stage"], stage)
            production.validate_task(ROOT, task)

    def test_v3_sop_is_the_active_pipeline_entry(self):
        text = (ROOT / "docs/production-sop-v3.md").read_text(encoding="utf-8")
        self.assertIn("Agentic 母版", text)
        self.assertIn("五档", text)
        self.assertIn("十序列", text)
        self.assertIn("max_geometry_drift_px=0", text)
        self.assertIn("姓名区不得携带背景", text)

    def test_current_fool_carrier_contract_is_executable_and_hexagonal(self):
        report = production.validate_fool_carrier_contract(ROOT)

        self.assertEqual(report["status"], "passed")
        self.assertEqual(report["geometry_id"], "fool-agentic-mother-v2")
        self.assertEqual(report["emblem_dock_mode"], "rank-numeral-dock-current-route")
        self.assertFalse(report["through_hole"])
        self.assertEqual(report["gem_slot"]["shape"], "regular-equilateral-hexagon")
        self.assertEqual(report["gem_slot"]["center_design"], [512.0, 1421.0])
        self.assertEqual(report["thresholds"]["geometry_displacement_max_px"], 0)
        self.assertEqual(report["thresholds"]["outside_edit_domain_pixels_max"], 0)

        pipeline = (ROOT / "tools/render/foolpipeline5.swift").read_text(encoding="utf-8")
        self.assertIn("loadFoolCarrierExecutionContract", pipeline)


class RendererTests(unittest.TestCase):
    @unittest.skipUnless(sys.platform == "darwin" and shutil.which("swiftc"), "native Fool pipeline requires macOS/Swift")
    def test_pipeline_selftest_reports_stage_safety_markers(self):
        with tempfile.TemporaryDirectory(prefix="fool-pipeline-bin-") as directory:
            binary = Path(directory) / "foolpipeline5"
            subprocess.run(
                ["swiftc", "-O", str(ROOT / "tools/render/foolpipeline5.swift"), "-o", str(binary)],
                check=True,
                capture_output=True,
                text=True,
            )
            result = subprocess.run([str(binary), "selftest"], check=True, capture_output=True, text=True)
        for marker in (
            "mother-contract",
            "carrier-contract",
            "single-gem-slot",
            "right-zone-empty",
            "name-surface-background-free",
            "five-tier-mapping",
            "geometry-zero",
            "sequence-local-diff",
            "local-composite",
            "numeral-progression",
            "numeral-native-material",
            "real-alpha",
        ):
            self.assertIn(marker, result.stdout)

    @unittest.skipUnless(sys.platform == "darwin" and shutil.which("swiftc"), "native Fool pipeline requires macOS/Swift")
    def test_pipeline_mother_stage_produces_clean_alpha_and_masks(self):
        with tempfile.TemporaryDirectory(prefix="fool-pipeline-bin-") as directory:
            binary = Path(directory) / "foolpipeline5"
            subprocess.run(
                ["swiftc", "-O", str(ROOT / "tools/render/foolpipeline5.swift"), "-o", str(binary)],
                check=True,
                capture_output=True,
                text=True,
            )
            parent = tempfile.TemporaryDirectory(prefix=".fool-mother-test-", dir=ROOT / "artifacts/production")
            output = Path(parent.name) / "mother"
            try:
                subprocess.run(
                    [
                        str(binary),
                        "mother",
                        str(ROOT),
                        "artifacts/production/fool-mother-frame-v1/studies/fool-mother-agentic-high-detail-candidate-n.png",
                        str(output),
                    ],
                    check=True,
                    capture_output=True,
                    text=True,
                )
                gate = subprocess.run(
                    [str(binary), "gate", str(ROOT), str(output)],
                    capture_output=True,
                    text=True,
                )
                manifest = json.loads((output / "manifest.json").read_text(encoding="utf-8"))
                self.assertEqual(manifest["geometry_id"], "fool-agentic-mother-v2")
                self.assertEqual(manifest["status"], "pending-engineering-review")
                self.assertEqual(manifest["carrier_contract"]["geometry_id"], "fool-agentic-mother-v2")
                self.assertEqual(manifest["carrier_contract"]["emblem_dock_mode"], "rank-numeral-dock-current-route")
                self.assertTrue(manifest["alpha"]["has_zero"])
                self.assertTrue((output / "frame-core-native.png").is_file())
                self.assertFalse((output / "frame-core.png").exists())
                self.assertTrue((output / "masks").is_dir())
                self.assertEqual(gate.returncode, 0, gate.stderr or gate.stdout)
                self.assertIn("carrier-contract", gate.stdout)
            finally:
                parent.cleanup()

    @unittest.skipUnless(sys.platform == "darwin" and shutil.which("swiftc"), "native Fool pipeline requires macOS/Swift")
    def test_pipeline_tiers_stage_freezes_direct_agentic_tier_frames(self):
        with tempfile.TemporaryDirectory(prefix="fool-pipeline-bin-") as directory:
            binary = Path(directory) / "foolpipeline5"
            subprocess.run(
                ["swiftc", "-O", str(ROOT / "tools/render/foolpipeline5.swift"), "-o", str(binary)],
                check=True,
                capture_output=True,
                text=True,
            )
            parent = tempfile.TemporaryDirectory(prefix=".fool-tier-test-", dir=ROOT / "artifacts/production")
            mother = Path(parent.name) / "mother"
            tiers = Path(parent.name) / "tiers"
            try:
                subprocess.run(
                    [
                        str(binary),
                        "mother",
                        str(ROOT),
                        "artifacts/production/fool-mother-frame-v1/studies/fool-mother-agentic-high-detail-candidate-n.png",
                        str(mother),
                    ],
                    check=True,
                    capture_output=True,
                    text=True,
                )
                subprocess.run(
                    [str(binary), "tiers", str(ROOT), str(mother), str(tiers)],
                    check=True,
                    capture_output=True,
                    text=True,
                )
                gate = subprocess.run(
                    [str(binary), "gate", str(ROOT), str(tiers)],
                    capture_output=True,
                    text=True,
                )
                manifest = json.loads((tiers / "manifest.json").read_text(encoding="utf-8"))
                self.assertEqual(gate.returncode, 0, gate.stderr or gate.stdout)
                self.assertEqual(manifest["mode"], "fool-five-tier-direct-batch-v1")
                self.assertTrue(manifest["direct_agentic_sources"])
                self.assertEqual(manifest["color_transform"], "none")
                self.assertIn("geometry-zero", gate.stdout)
            finally:
                parent.cleanup()

    @unittest.skipUnless(sys.platform == "darwin" and shutil.which("swiftc"), "native Fool pipeline requires macOS/Swift")
    def test_pipeline_sequence_stage_outputs_name_free_frames_for_agentic(self):
        with tempfile.TemporaryDirectory(prefix="fool-pipeline-bin-") as directory:
            binary = Path(directory) / "foolpipeline5"
            subprocess.run(
                ["swiftc", "-O", str(ROOT / "tools/render/foolpipeline5.swift"), "-o", str(binary)],
                check=True,
                capture_output=True,
                text=True,
            )
            parent = tempfile.TemporaryDirectory(prefix=".fool-sequence-test-", dir=ROOT / "artifacts/production")
            output = Path(parent.name) / "sequences"
            try:
                subprocess.run(
                    [
                        str(binary),
                        "sequences",
                        str(ROOT),
                        "artifacts/production/fool-five-tier-direct-kit-v1",
                        str(output),
                    ],
                    check=True,
                    capture_output=True,
                    text=True,
                )
                gate = subprocess.run(
                    [str(binary), "gate", str(ROOT), str(output)],
                    capture_output=True,
                    text=True,
                )
                manifest = json.loads((output / "manifest.json").read_text(encoding="utf-8"))
                self.assertEqual(gate.returncode, 0, gate.stderr or gate.stdout)
                self.assertEqual(manifest["mode"], "fool-ten-sequence-frame-batch-native-diagnostic-v3")
                self.assertEqual(manifest["native_canvas"], [1024, 1536])
                self.assertEqual(manifest["intermediate_2k_count"], 0)
                self.assertTrue(manifest["no_sequence_name_pixels"])
                self.assertEqual(manifest["right_inscription_stage"]["status"], "reserved-empty")
                self.assertEqual(manifest["right_inscription_stage"]["next_owner"], "AgenticSequenceInscription")
                self.assertEqual(len(manifest["entries"]), 10)
                for entry in manifest["entries"]:
                    self.assertNotIn("inscription", entry)
                    self.assertNotIn("numeral", entry)
                    self.assertEqual(entry["right_inscription_local_diff"]["changed_pixels"], 0)
                    self.assertEqual(entry["geometry"]["max_drift_native_px"], 0)
            finally:
                parent.cleanup()

    def test_legacy_localized_inscription_route_is_retired(self):
        catalog = json.loads(
            (ROOT / "production/symbols/fool-agentic-sequence-inscriptions-v2.json")
            .read_text(encoding="utf-8")
        )
        self.assertEqual(catalog["stage"], "agentic-complete-frame-baseline")
        self.assertEqual(
            catalog["localized_ingest"]["mode"],
            "retired-legacy-localized-ingest",
        )
        self.assertTrue(catalog["localized_ingest"]["candidate_background_is_not_imported"])
        self.assertTrue(catalog["localized_ingest"]["program_must_not_add_sequence_name"])

    @unittest.skipUnless(sys.platform == "darwin" and shutil.which("swiftc"), "native Fool pipeline requires macOS/Swift")
    def test_output_path_validation_is_escape_safe_and_symlink_agnostic(self):
        with tempfile.TemporaryDirectory(prefix="fool-pipeline-bin-") as directory:
            binary = Path(directory) / "foolpipeline5"
            subprocess.run(
                ["swiftc", "-O", str(ROOT / "tools/render/foolpipeline5.swift"), "-o", str(binary)],
                check=True,
                capture_output=True,
                text=True,
            )
            candidate = "artifacts/production/fool-mother-frame-v1/studies/fool-mother-agentic-high-detail-candidate-n.png"
            for escape in ("artifacts/production-evil/x", "artifacts/x", "artifacts/production"):
                result = subprocess.run(
                    [str(binary), "mother", str(ROOT), candidate, str(ROOT / escape)],
                    capture_output=True,
                    text=True,
                )
                self.assertNotEqual(result.returncode, 0, escape)
                self.assertIn("Output must be a child of artifacts/production", result.stderr + result.stdout)
            with tempfile.TemporaryDirectory(prefix=".fool-path-test-", dir=ROOT / "artifacts/production") as parent:
                existing = Path(parent) / "mother"
                existing.mkdir()
                result = subprocess.run(
                    [str(binary), "mother", str(ROOT), candidate, str(existing)],
                    capture_output=True,
                    text=True,
                )
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("Output already exists", result.stderr + result.stdout)
            alternate_root = "/" + str(ROOT)[len("/private/"):] if str(ROOT).startswith("/private/") else None
            if alternate_root is not None and Path(alternate_root).is_dir():
                cross_form = ROOT / "artifacts/production/.fool-cross-form-test"
                try:
                    result = subprocess.run(
                        [str(binary), "mother", str(alternate_root), candidate, str(cross_form / "mother")],
                        capture_output=True,
                        text=True,
                    )
                    self.assertEqual(result.returncode, 0, result.stderr or result.stdout)
                finally:
                    shutil.rmtree(cross_form, ignore_errors=True)

    @unittest.skipUnless(sys.platform == "darwin" and shutil.which("swiftc"), "native Fool pipeline requires macOS/Swift")
    def test_pathway_flag_resolves_the_declared_pathway_contract(self):
        """SYNTHETIC probe pathway: paths come from the contract, never from a hardcoded fool default."""
        with tempfile.TemporaryDirectory(prefix="fool-pipeline-bin-") as directory:
            binary = Path(directory) / "foolpipeline5"
            subprocess.run(
                ["swiftc", "-O", str(ROOT / "tools/render/foolpipeline5.swift"), "-o", str(binary)],
                check=True,
                capture_output=True,
                text=True,
            )
            with tempfile.TemporaryDirectory(prefix="pathway-flag-probe-") as root_directory:
                root = Path(root_directory)
                symbols = root / "production/symbols/synthetic"
                symbols.mkdir(parents=True)
                for name in ("five-tier-kit.json", "sequence-inscriptions.json", "rank-numerals.json"):
                    (symbols / name).write_text('{"synthetic_probe": true}', encoding="utf-8")

                def declared(name: str, *, corrupt: bool = False) -> dict:
                    payload = (symbols / name).read_bytes()
                    return {
                        "path": f"production/symbols/synthetic/{name}",
                        "sha256": "0" * 64 if corrupt else hashlib.sha256(payload).hexdigest(),
                        "purpose": "synthetic-probe",
                    }

                (symbols / "carrier-execution.json").write_text(
                    json.dumps(
                        {
                            "pathway_id": "synthetic",
                            "catalogs": {
                                "five_tier_kit": declared("five-tier-kit.json"),
                                "sequence_inscriptions": declared("sequence-inscriptions.json"),
                                "rank_numerals": declared("rank-numerals.json", corrupt=True),
                            },
                        }
                    ),
                    encoding="utf-8",
                )
                probe_input = "artifacts/production/fool-mother-frame-v1/studies/fool-mother-agentic-high-detail-candidate-n.png"
                mirror = root / probe_input
                mirror.parent.mkdir(parents=True)
                shutil.copyfile(ROOT / probe_input, mirror)
                parent = tempfile.TemporaryDirectory(prefix=".pathway-flag-test-", dir=ROOT / "artifacts/production")
                try:
                    result = subprocess.run(
                        [
                            str(binary),
                            "--pathway",
                            "synthetic",
                            "mother",
                            str(root),
                            probe_input,
                            str(Path(parent.name) / "mother"),
                        ],
                        capture_output=True,
                        text=True,
                    )
                finally:
                    parent.cleanup()
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("Carrier catalog changed: rank_numerals", result.stderr)
                self.assertNotIn("fool-carrier-execution", result.stderr)

    @unittest.skipUnless(sys.platform == "darwin" and shutil.which("swiftc"), "native Fool pipeline requires macOS/Swift")
    def test_catalog_path_must_be_repository_relative(self):
        """SYNTHETIC counterexample: an out-of-root catalog path is rejected on path shape, not on hash."""
        with tempfile.TemporaryDirectory(prefix="fool-pipeline-abs-") as directory:
            binary = Path(directory) / "foolpipeline5"
            subprocess.run(
                ["swiftc", "-O", str(ROOT / "tools/render/foolpipeline5.swift"), "-o", str(binary)],
                check=True,
                capture_output=True,
                text=True,
            )
            outside = Path(directory) / "outside-catalog.json"
            outside.write_text('{"synthetic_probe": true}', encoding="utf-8")
            with tempfile.TemporaryDirectory(prefix="pathway-abs-probe-") as root_directory:
                root = Path(root_directory)
                symbols = root / "production/symbols/synthetic"
                symbols.mkdir(parents=True)
                for name in ("sequence-inscriptions.json", "rank-numerals.json"):
                    (symbols / name).write_text('{"synthetic_probe": true}', encoding="utf-8")

                def declared(name: str) -> dict:
                    payload = (symbols / name).read_bytes()
                    return {
                        "path": f"production/symbols/synthetic/{name}",
                        "sha256": hashlib.sha256(payload).hexdigest(),
                        "purpose": "synthetic-probe",
                    }

                (symbols / "carrier-execution.json").write_text(
                    json.dumps(
                        {
                            "pathway_id": "synthetic",
                            "catalogs": {
                                "five_tier_kit": {
                                    "path": str(outside),
                                    "sha256": hashlib.sha256(outside.read_bytes()).hexdigest(),
                                    "purpose": "synthetic-probe",
                                },
                                "sequence_inscriptions": declared("sequence-inscriptions.json"),
                                "rank_numerals": declared("rank-numerals.json"),
                            },
                        }
                    ),
                    encoding="utf-8",
                )
                probe_input = "artifacts/production/fool-mother-frame-v1/studies/fool-mother-agentic-high-detail-candidate-n.png"
                mirror = root / probe_input
                mirror.parent.mkdir(parents=True)
                shutil.copyfile(ROOT / probe_input, mirror)
                parent = tempfile.TemporaryDirectory(prefix=".pathway-abs-test-", dir=ROOT / "artifacts/production")
                try:
                    result = subprocess.run(
                        [
                            str(binary),
                            "--pathway",
                            "synthetic",
                            "mother",
                            str(root),
                            probe_input,
                            str(Path(parent.name) / "mother"),
                        ],
                        capture_output=True,
                        text=True,
                    )
                finally:
                    parent.cleanup()
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("Catalog path must be repository-relative", result.stderr)
                self.assertNotIn("Carrier catalog changed", result.stderr)


if __name__ == "__main__":
    unittest.main()
