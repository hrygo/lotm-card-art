"""Validation tests for the two current Fool full-card candidates."""

from pathlib import Path
import copy
import struct
import sys
import unittest
import zlib
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import production


def _chunk(kind, data):
    return (struct.pack(">I", len(data)) + kind + data
            + struct.pack(">I", zlib.crc32(data, zlib.crc32(kind)) & 0xffffffff))


def _solid_png(width, height):
    raw = (b"\0" + b"\x18\x18\x18" * width) * height
    return (b"\x89PNG\r\n\x1a\n"
            + _chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
            + _chunk(b"sRGB", b"\0")
            + _chunk(b"IDAT", zlib.compress(raw))
            + _chunk(b"IEND", b""))


class FoolCardValidationTests(unittest.TestCase):
    def test_external_audrey_assets_remain_a_complete_preserved_package(self):
        report = production.validate_external_audrey_assets(ROOT)

        self.assertEqual(report["status"], "preserved")
        self.assertEqual(report["artwork_file_count"], 3)
        self.assertEqual(report["audio_file_count"], 6)
        self.assertTrue(report["six_dimension_source"])
        self.assertTrue(report["story_source"])

    def test_current_fool_audio_and_app_assets_are_one_complete_package(self):
        report = production.validate_fool_audio_package(ROOT)

        self.assertEqual(report["status"], "passed")
        self.assertEqual(report["card_count"], 2)
        self.assertEqual(report["audio_file_count"], 12)
        self.assertEqual(report["app"]["card_art_count"], 2)
        self.assertEqual(report["app"]["audio_file_count"], 12)
        self.assertEqual(report["app"]["card_art_names"], [
            "fool-s00-card-agentic-v1-v001",
            "fool-s09-card-name-edit-v1-v001",
        ])
        self.assertEqual(report["app"]["audio_resource_names"], sorted([
            "s00-greeting-v2",
            "s00-catchphrase-01-v2",
            "s00-catchphrase-02-v2",
            "s00-story-01-v2",
            "s00-story-02-v2",
            "s00-story-03-v2",
            "s09-greeting-v1",
            "s09-catchphrase-01-v1",
            "s09-catchphrase-02-v1",
            "s09-story-01-v1",
            "s09-story-02-v1",
            "s09-story-03-v1",
        ]))

    def test_current_card_candidates_are_registered_and_native(self):
        report = production.validate_fool_cards(ROOT)

        self.assertEqual(report["status"], "passed")
        self.assertEqual(report["candidate_count"], 2)
        self.assertEqual(
            report["card_ids"],
            [
                "lotm.fool.s09.klein-moretti.tingen-01",
                "lotm.fool.s00.klein-moretti.mr-fool-01",
            ],
        )
        self.assertEqual(report["native_canvas_sizes"], {"s09": [1024, 1536], "s00": [1024, 1536]})
        self.assertFalse(report["formal_release_approved"])
        self.assertEqual(report["final_sampling"]["card_count"], 2)
        self.assertEqual(set(report["final_sampling"]["approval_statuses"].values()), {"pending"})
        self.assertEqual(report["final_sampling"]["candidate_manifest"],
                         "production/cards/fool-card-candidates-v1.json")
        self.assertEqual(report["visual_review"]["status"], "pending-user-visual-approval")
        self.assertEqual(report["visual_review"]["card_count"], 2)

    def test_s09_global_rerender_is_not_reported_as_local_zero_drift_edit(self):
        report = production.validate_fool_cards(ROOT)

        self.assertEqual(report["s09_local_edit_status"], "rejected-global-rerender")
        self.assertAlmostEqual(report["s09_changed_ratio"], 0.8710549672444662, places=12)
        self.assertEqual(report["s09_changed_pixels_outside_name_surface"], 1292203)
        self.assertEqual(report["s09_recomputed_changed_pixels"], 1370051)

    def test_card_candidate_hash_tampering_is_rejected(self):
        original_sha = production.sha

        def tampered_sha(path):
            if str(path).endswith("fool-s00-card-agentic-v1/v001/raw.png"):
                return "0" * 64
            return original_sha(path)

        with patch.object(production, "sha", side_effect=tampered_sha):
            with self.assertRaisesRegex(production.Invalid, "card candidate hash"):
                production.validate_fool_cards(ROOT)

    def test_recorded_pixel_audit_tampering_is_rejected(self):
        original_read = production.read

        def tampered_read(path):
            value = original_read(path)
            if str(path).endswith("production/cards/fool-card-candidates-v1.json"):
                value = copy.deepcopy(value)
                value["cards"][0]["local_edit_audit"]["changed_ratio"] = 0.01
            return value

        with patch.object(production, "read", side_effect=tampered_read):
            with self.assertRaisesRegex(production.Invalid, "pixel audit"):
                production.validate_fool_cards(ROOT)

    def _final_manifest(self, root, approval_status="pending", intermediate_2k_count=0):
        source = root / "source.png"
        source.write_bytes((ROOT / "artifacts/production/fool-s00-card-agentic-v1/v001/raw.png").read_bytes())
        candidate_path = root / "candidate.json"
        production.write(candidate_path, {
            "schema_version": "1.0.0",
            "status": "candidate-pending-user-visual-review",
            "cards": [{
                "card_id": "lotm.fool.s00.klein-moretti.mr-fool-01",
                "path": "source.png",
                "sha256": production.sha(source),
                "size_px": [1024, 1536],
            }],
        })
        manifest = {
            "schema_version": "1.0.0",
            "status": "pending-user-visual-approval" if approval_status == "pending" else "approved-for-final-sampling",
            "candidate_manifest": {
                "path": "candidate.json",
                "sha256": production.sha(candidate_path),
            },
            "policy": {
                "native_canvas": [1024, 1536],
                "allowed_profiles": {
                    "standard": {"size_px": [2048, 3072]},
                    "collector": {"size_px": [4096, 6144]},
                },
                "crop_count_before_final": 0,
                "intermediate_2k_count": intermediate_2k_count,
                "final_resample_count_per_output": 1,
                "source_must_be_complete_native_card": True,
            },
            "cards": [{
                "card_id": "lotm.fool.s00.klein-moretti.mr-fool-01",
                "source_native": {
                    "path": "source.png",
                    "sha256": production.sha(source),
                    "size_px": [1024, 1536],
                    "role": "complete-native-card",
                },
                "user_visual_approval": {
                    "status": approval_status,
                    "by": "reviewer" if approval_status == "approved" else None,
                    "reference": "review-ref" if approval_status == "approved" else None,
                },
            }],
            "formal_release_approved": False,
        }
        manifest_path = root / "manifest.json"
        production.write(manifest_path, manifest)
        return manifest_path

    def test_final_sampling_rejects_pending_user_visual_approval(self):
        import tempfile

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            manifest = self._final_manifest(root)
            with self.assertRaisesRegex(production.Invalid, "visual approval"):
                production.finalize_fool_card(root, "manifest.json",
                                              "lotm.fool.s00.klein-moretti.mr-fool-01",
                                              "standard", "artifacts/production/final-standard")

    def test_final_sampling_accepts_only_one_direct_native_transform(self):
        import tempfile

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            manifest = self._final_manifest(root, approval_status="approved")

            def fake_sips(args, **kwargs):
                Path(args[-1]).write_bytes(_solid_png(2048, 3072))

            with patch.object(production.subprocess, "run", side_effect=fake_sips) as run:
                result = production.finalize_fool_card(
                    root, "manifest.json",
                    "lotm.fool.s00.klein-moretti.mr-fool-01",
                    "standard", "artifacts/production/final-standard")

            self.assertEqual(result["final_size"], [2048, 3072])
            self.assertEqual(result["intermediate_2k_count"], 0)
            self.assertEqual(result["final_resample_count"], 1)
            run.assert_called_once()
            receipt = production.read(root / "artifacts/production/final-standard/receipt.json")
            self.assertEqual(receipt["source_native"]["size_px"], [1024, 1536])
            self.assertEqual(receipt["final"]["size_px"], [2048, 3072])

    def test_final_sampling_rejects_intermediate_2k_chain(self):
        import tempfile

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._final_manifest(root, approval_status="approved", intermediate_2k_count=1)
            with self.assertRaisesRegex(production.Invalid, "intermediate 2K"):
                production.finalize_fool_card(root, "manifest.json",
                                              "lotm.fool.s00.klein-moretti.mr-fool-01",
                                              "standard", "artifacts/production/final-standard")

    def test_final_receipt_is_bound_to_approved_manifest(self):
        import tempfile

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            manifest = self._final_manifest(root, approval_status="approved")

            def fake_sips(args, **kwargs):
                Path(args[-1]).write_bytes(_solid_png(2048, 3072))

            with patch.object(production.subprocess, "run", side_effect=fake_sips):
                production.finalize_fool_card(
                    root, "manifest.json",
                    "lotm.fool.s00.klein-moretti.mr-fool-01",
                    "standard", "artifacts/production/final-standard")

            receipt_path = root / "artifacts/production/final-standard/receipt.json"
            receipt = production.read(receipt_path)
            receipt["manifest"]["sha256"] = "0" * 64
            production.write(receipt_path, receipt)
            with self.assertRaisesRegex(production.Invalid, "manifest"):
                production.validate_final_sample(
                    root, "artifacts/production/final-standard/receipt.json")

    def test_final_sampling_does_not_claim_formal_release(self):
        import tempfile

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            manifest_path = self._final_manifest(root, approval_status="approved")
            manifest = production.read(manifest_path)
            manifest["formal_release_approved"] = True
            production.write(manifest_path, manifest)
            with self.assertRaisesRegex(production.Invalid, "formal release"):
                production.finalize_fool_card(
                    root, "manifest.json",
                    "lotm.fool.s00.klein-moretti.mr-fool-01",
                    "standard", "artifacts/production/final-standard")

    def test_final_sampling_rejects_stale_candidate_binding(self):
        import tempfile

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            manifest_path = self._final_manifest(root, approval_status="approved")
            candidate_path = root / "candidate.json"
            candidate = production.read(candidate_path)
            candidate["cards"][0]["path"] = "another-source.png"
            production.write(candidate_path, candidate)
            manifest = production.read(manifest_path)
            manifest["candidate_manifest"]["sha256"] = production.sha(candidate_path)
            production.write(manifest_path, manifest)
            with self.assertRaisesRegex(production.Invalid, "current candidate"):
                production.finalize_fool_card(
                    root, "manifest.json",
                    "lotm.fool.s00.klein-moretti.mr-fool-01",
                    "standard", "artifacts/production/final-standard")


if __name__ == "__main__":
    unittest.main()
