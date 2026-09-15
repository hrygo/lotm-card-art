#!/usr/bin/env python3
"""Offline Agent task compiler, asset registry, native compositor and gates."""
from __future__ import annotations
import argparse
import copy
import hashlib
import html
import json
import math
from pathlib import Path
import re
import shutil
import struct
import subprocess
import sys
import wave
import zlib
from datetime import datetime, timezone

import cardctl

ROOT = Path(__file__).resolve().parents[1]


class Invalid(ValueError):
    pass


def read(path):
    return json.loads(Path(path).read_text(encoding="utf-8"),
                      object_pairs_hook=cardctl.pairs_no_duplicates)


def write(path, value):
    Path(path).write_text(json.dumps(value, ensure_ascii=False, indent=2,
                                    allow_nan=False) + "\n", encoding="utf-8")


def sha(path):
    return cardctl.digest_file(Path(path))


NATIVE_BASELINE_STATUSES = {
    "user-approved-agentic-visual-baseline",   # 既封存基线上的历史机器写入标记，仅作描述
    "agentic-native-material-baseline",        # 渲染器今后写入的中性标记
}


def inside(root, rel):
    if not isinstance(rel, str) or not rel or Path(rel).is_absolute():
        raise Invalid("expected nonempty repository-relative path")
    path = (root / rel).resolve()
    if not path.is_relative_to(root.resolve()):
        raise Invalid("path escapes repository: " + rel)
    return path


def record(root, path):
    return {"path": path.resolve().relative_to(root.resolve()).as_posix(), "sha256": sha(path)}


def require_visual_approval_sidecar(root, manifest_rel, required_file):
    """视觉批准必须来自独立的人工 sidecar，而不是渲染器自己写入的状态字符串。"""
    rel = "production/approvals/fool-agentic-visual-baseline-v1.json"
    sidecar = read(required_file(rel, "Fool visual approval sidecar"))
    if sidecar.get("kind") != "visual_approval_sidecar":
        raise Invalid("visual approval sidecar kind is invalid")
    if sidecar.get("visual_approved") is not True:
        raise Invalid("visual approval sidecar does not record user visual approval")
    basis = sidecar.get("basis")
    if not isinstance(basis, dict) or not str(basis.get("user_quote", "")).strip():
        raise Invalid("visual approval sidecar lacks a user basis quote")
    if sidecar.get("release_approved") is not False:
        raise Invalid("visual approval sidecar must not approve release")
    assets = sidecar.get("approved_assets")
    if not isinstance(assets, dict):
        raise Invalid("visual approval sidecar lacks approved assets")
    frames = assets.get("five_tier_frames", {})
    if frames.get("manifest_path") != manifest_rel or frames.get("manifest_sha256") != sha(inside(root, manifest_rel)):
        raise Invalid("visual approval sidecar manifest binding is stale")
    mother = assets.get("mother_frame", {})
    mother_rel = mother.get("path")
    if not isinstance(mother_rel, str) or not mother_rel:
        raise Invalid("visual approval sidecar lacks a mother-frame binding")
    if sha(inside(root, mother_rel)) != mother.get("sha256"):
        raise Invalid("visual approval sidecar mother-frame binding is stale")
    return sidecar


def verify_records(root, records):
    for item in records:
        path = inside(root, item["path"])
        if not path.is_file() or sha(path) != item["sha256"]:
            raise Invalid("missing/stale dependency: " + item["path"])


def new_output(root, rel, prefix):
    path = inside(root, rel)
    if not path.is_relative_to(inside(root, prefix)) or path == inside(root, prefix):
        raise Invalid("output must be a child of " + prefix)
    if path.exists():
        raise Invalid("immutable output already exists: " + rel)
    return path


def validate_schema(value, schema, where="$"):
    """Validate the deliberately bounded JSON Schema vocabulary used here."""
    if "oneOf" in schema:
        matches = 0
        for choice in schema["oneOf"]:
            try:
                validate_schema(value, choice, where)
                matches += 1
            except Invalid:
                pass
        if matches != 1:
            raise Invalid(where + ": expected exactly one payload shape")
    if "const" in schema and value != schema["const"]:
        raise Invalid(where + ": wrong constant")
    if "enum" in schema and value not in schema["enum"]:
        raise Invalid(where + ": invalid enum")
    types = schema.get("type", [])
    if isinstance(types, str):
        types = [types]
    tests = {"object": lambda: type(value) is dict, "array": lambda: type(value) is list,
             "string": lambda: type(value) is str, "integer": lambda: type(value) is int,
             "number": lambda: type(value) in (float, int),
             "boolean": lambda: type(value) is bool, "null": lambda: value is None}
    if types and not any(tests[t]() for t in types):
        raise Invalid(where + ": wrong type")
    if type(value) in (int, float):
        if not math.isfinite(value):
            raise Invalid(where + ": nonfinite number")
        if value < schema.get("minimum", -math.inf) or value > schema.get("maximum", math.inf):
            raise Invalid(where + ": out of range")
    if isinstance(value, str):
        if len(value.strip()) < schema.get("minLength", 0):
            raise Invalid(where + ": empty text")
        if "pattern" in schema and not re.search(schema["pattern"], value):
            raise Invalid(where + ": pattern mismatch")
    if isinstance(value, list):
        if not schema.get("minItems", 0) <= len(value) <= schema.get("maxItems", math.inf):
            raise Invalid(where + ": array length")
        for i, item in enumerate(value):
            validate_schema(item, schema.get("items", {}), f"{where}[{i}]")
    if isinstance(value, dict):
        props = schema.get("properties", {})
        if set(schema.get("required", [])) - set(value):
            raise Invalid(where + ": missing required fields")
        if schema.get("additionalProperties") is False and set(value) - set(props):
            raise Invalid(where + ": unknown fields")
        for key in value.keys() & props.keys():
            validate_schema(value[key], props[key], where + "." + key)


def schema(root, name):
    return read(root / f"production/schemas/{name}.schema.json")


def visual_quality(root, sequence):
    """Resolve visual quality without changing the canonical rank taxonomy."""
    if type(sequence) is not int or not 0 <= sequence <= 9:
        raise Invalid("quality sequence must be an integer from 0 to 9")
    tiers = read(root / "config/quality-color-tokens.json")["tiers"]
    ids = [row["id"] for row in tiers]
    numbers = [n for row in tiers for n in row["sequences"]]
    if (len(ids) != 5 or set(ids) != {"low", "mid", "saint", "angel", "true-god"}
            or any(type(n) is not int for n in numbers) or sorted(numbers) != list(range(10))):
        raise Invalid("quality configuration must cover all ten sequences exactly once")
    if any(not re.fullmatch(r"#[0-9a-fA-F]{6}", row["primary"]) for row in tiers):
        raise Invalid("invalid quality primary color")
    return next(row for row in tiers if sequence in row["sequences"])


def validate_external_audrey_assets(root):
    """Ensure the external Audrey source package survives Fool cleanup."""
    root = Path(root).resolve()
    artwork_root = "artifacts/lotm.visionary.s07/render-v001"
    artwork_files = [
        f"{artwork_root}/audrey-s07-psychologist-raw.png",
        f"{artwork_root}/audrey-s07-psychologist-v001.png",
        f"{artwork_root}/audrey-s07-psychologist-collector-v001.png",
    ]
    audio_root = "artifacts/lotm.visionary.s07/audio-v001"
    audio_files = [
        f"{audio_root}/audrey-greeting-v1.wav",
        f"{audio_root}/audrey-catchphrase-01-v1.wav",
        f"{audio_root}/audrey-catchphrase-02-v1.wav",
        f"{audio_root}/audrey-story-01-v1.wav",
        f"{audio_root}/audrey-story-02-v1.wav",
        f"{audio_root}/audrey-story-03-v1.wav",
    ]
    six_dimension_rel = "pathways/visionary/sequences/07/card.json"
    story_rel = "docs/research/2026-09-13-audrey-s07-research.md"
    required = artwork_files + audio_files + [six_dimension_rel, story_rel]
    for rel in required:
        if not inside(root, rel).is_file():
            raise Invalid("external Audrey preservation asset missing: " + rel)

    try:
        for rel in artwork_files:
            info = cardctl.image_info(inside(root, rel))
            if info["format"] != "PNG":
                raise Invalid("external Audrey artwork must be PNG: " + rel)
    except (OSError, cardctl.DataError) as exc:
        raise Invalid("external Audrey artwork is unreadable: " + str(exc)) from exc

    six_dimension_source = read(inside(root, six_dimension_rel))
    semantics = six_dimension_source.get("semantics", {})
    expected_dimensions = {"identity", "acting", "abilities", "potion", "ascension", "limitations"}
    if (six_dimension_source.get("card_id") != "lotm.visionary.s07"
            or six_dimension_source.get("sequence") != 7
            or set(semantics) != expected_dimensions):
        raise Invalid("external Audrey six-dimensional source is incomplete")

    cleanup_rel = "production/retirements/fool-failed-materials-2026-09-14.json"
    cleanup_path = inside(root, cleanup_rel)
    if cleanup_path.is_file():
        moved_paths = {item.get("path") for item in read(cleanup_path).get("moved_to_trash", [])}
        if any(rel in moved_paths for rel in required):
            raise Invalid("external Audrey preservation asset is listed for cleanup")

    return {
        "status": "preserved",
        "artwork_file_count": len(artwork_files),
        "audio_file_count": len(audio_files),
        "six_dimension_source": True,
        "story_source": True,
        "artwork_root": artwork_root,
        "audio_root": audio_root,
        "six_dimension_path": six_dimension_rel,
        "story_path": story_rel,
    }


PATHWAY_LABELS = {"fool": "Fool"}


def pathway_material_context(root, pathway_id):
    """Resolve the contracts and asset paths a pathway's material gate must audit.

    `fool` keeps the frozen flat (historical) layout recorded in
    `docs/pathway-namespace.md`; every other pathway follows the namespaced
    convention `production/symbols/<pathway>/…`. Expectations are declared here
    instead of being read back from the assets under audit, so a stale or
    redirected catalog cannot validate itself.
    """
    label = PATHWAY_LABELS.get(pathway_id, pathway_id)
    if pathway_id == "fool":
        return {
            "pathway_id": pathway_id,
            "label": label,
            "form": "legacy-flat",
            "carrier_contract": "production/symbols/fool-carrier-execution-v1.json",
            "carrier_schema": "fool-carrier-execution",
            "rank_contract_type": "fool-rank-numeral-dock",
            "geometry_id": "fool-agentic-mother-v2",
            "native_canvas": [1024, 1536],
            "frame_generator": "foolpipeline5.mother",
            "five_tier_catalog": "production/symbols/fool-five-tier-kit.json",
            "five_tier_output": "artifacts/production/fool-five-tier-direct-kit-v1",
            "tier_batch_mode": "fool-five-tier-direct-batch-v1",
            "layered_baseline": "production/symbols/fool-layered-asset-baseline-v1.json",
            "layered_status": "user-approved-agentic-visual-baseline",
            "sequence_inscriptions": "production/symbols/fool-agentic-sequence-inscriptions-v2.json",
            "sequence_output_root": "artifacts/production/fool-agentic-sequence-inscriptions-v2/studies",
            "fusion_family": "production/symbols/fool-fusion-family.json",
            "fusion_preservation": "production/symbols/fool-fusion-preservation.json",
            "rank_numerals": "production/symbols/fool-rank-numerals-v1.json",
            "approval_sidecar": "production/approvals/fool-agentic-visual-baseline-v1.json",
            "retirements": "production/retirements/fool-failed-materials-2026-09-14.json",
            "card_prefix": "lotm.fool.s",
            "fusion_artifact_root": "artifacts/production/fool-fusion-",
        }
    base = f"production/symbols/{pathway_id}"
    return {
        "pathway_id": pathway_id,
        "label": label,
        "form": "namespaced",
        "carrier_contract": f"{base}/carrier-execution.json",
        "carrier_schema": "pathway-carrier-execution",
        "rank_contract_type": "rank-numeral-dock",
        "geometry_id": f"{pathway_id}-agentic-mother-v2",
        "native_canvas": [1024, 1536],
        "frame_generator": "foolpipeline5.mother",
        "five_tier_catalog": f"{base}/five-tier-kit.json",
        "five_tier_output": f"artifacts/production/{pathway_id}-five-tier-direct-kit-v1",
        "tier_batch_mode": f"{pathway_id}-five-tier-direct-batch-v1",
        "layered_baseline": f"{base}/layered-asset-baseline.json",
        "layered_status": "user-approved-agentic-visual-baseline",
        "sequence_inscriptions": f"{base}/agentic-sequence-inscriptions.json",
        "sequence_output_root": f"artifacts/production/{pathway_id}-agentic-sequence-inscriptions/studies",
        "fusion_family": f"{base}/fusion-family.json",
        "fusion_preservation": f"{base}/fusion-preservation.json",
        "rank_numerals": f"{base}/rank-numerals.json",
        "approval_sidecar": f"production/approvals/{pathway_id}-agentic-visual-baseline.json",
        "retirements": f"production/retirements/{pathway_id}-failed-materials.json",
        "card_prefix": f"lotm.{pathway_id}.s",
        "fusion_artifact_root": f"artifacts/production/{pathway_id}-fusion-",
    }


def validate_pathway_carrier_contract(root, pathway_id="fool"):
    """Validate the concrete carrier contract consumed by a pathway's pipeline.

    The generic EmblemDock JSON remains the vocabulary for future pathways. The
    current Fool route deliberately uses a fixed RankNumeralDock: the pathway
    crown is baked into the complete Agentic frame and the rank digit is not a
    second fused emblem overlay. This gate binds that decision to measured
    native geometry so the executable route cannot silently fall back to the
    stale, earlier lozenge-gem or free-placement contract.

    `pathway_id` selects which pathway's route is bound; the assertions below
    are unchanged, they now compare against the declared pathway and its
    declared geometry instead of the literal "fool".
    """
    root = Path(root).resolve()
    ctx = pathway_material_context(root, pathway_id)
    label = ctx["label"]
    contract_rel = ctx["carrier_contract"]
    contract_path = inside(root, contract_rel)
    if not contract_path.is_file():
        raise Invalid(f"{label} carrier execution contract missing: " + contract_rel)
    contract = read(contract_path)
    validate_schema(contract, schema(root, ctx["carrier_schema"]), "$")

    template_records = contract["templates"]
    verify_records(root, [template_records["emblem_dock"], template_records["rank_numeral_dock"]])
    active_frame = contract["active_frame_source"]
    active_frame_path = inside(root, active_frame["path"])
    if not active_frame_path.is_file() or sha(active_frame_path) != active_frame["sha256"]:
        raise Invalid(f"{label} carrier active frame reference is stale")
    try:
        frame_info = cardctl.image_info(active_frame_path)
    except (OSError, cardctl.DataError) as exc:
        raise Invalid(f"{label} carrier active frame is unreadable: " + str(exc)) from exc
    if frame_info["format"] != "PNG" or [frame_info["width"], frame_info["height"]] != ctx["native_canvas"]:
        raise Invalid(f"{label} carrier active frame must be a native {ctx['native_canvas'][0]}x{ctx['native_canvas'][1]} PNG")

    emblem_template = read(inside(root, template_records["emblem_dock"]["path"]))
    if (emblem_template.get("schema_version") != "1.1.0"
            or emblem_template.get("contract_type") != "emblem-dock"
            or emblem_template.get("status") != "template"):
        raise Invalid("generic EmblemDock template is not the invariant grammar")
    emblem_geometry = emblem_template.get("geometry", {})
    emblem_dock = emblem_geometry.get("dock", {})
    if (emblem_dock.get("mode") != "visual-recess-not-through-hole"
            or emblem_dock.get("through_hole") is not False):
        raise Invalid("generic EmblemDock template permits a through-hole")

    rank_template = read(inside(root, template_records["rank_numeral_dock"]["path"]))
    rank_dock = rank_template.get("dock", {})
    if (rank_template.get("schema_version") != "1.0.0"
            or rank_template.get("contract_type") != ctx["rank_contract_type"]
            or rank_template.get("geometry_id") != ctx["geometry_id"]
            or rank_dock.get("status") != "reserved-empty"
            or rank_dock.get("shape") != "round"
            or rank_template.get("numeral_asset", {}).get("fusion_with_pathway_crown") is not False):
        raise Invalid(f"{label} rank numeral dock template is stale")

    if contract.get("pathway_id") != pathway_id or contract.get("geometry_id") != ctx["geometry_id"]:
        raise Invalid(f"{label} carrier identity or geometry is stale")
    if contract.get("canvas", {}).get("native_size") != ctx["native_canvas"]:
        raise Invalid(f"{label} carrier native canvas is stale")

    route = contract["route"]
    if (route.get("emblem_dock_mode") != "rank-numeral-dock-current-route"
            or route.get("pathway_crown") != "baked-into-frame-core"
            or route.get("rank_numeral") != "independent-simple-art-digit"
            or route.get("sequence_name") != "agentic-complete-frame"
            or route.get("through_hole") is not False
            or route.get("standalone_emblem_overlay") is not False):
        raise Invalid(f"{label} carrier route is stale or enables a duplicate emblem")

    anchors = contract["anchors"]
    expected_rects = {
        "pathway_mark": ([50, 584, 84, 300], [50, 600, 84, 268]),
        "pathway_crown": ([350, 0, 330, 260], [350, 0, 330, 260]),
        "right_sequence_zone": ([878, 584, 108, 300], [890, 600, 84, 268]),
        "name_surface": ([224, 1216, 576, 136], [240, 1228, 544, 112]),
    }
    for key, (rect, safe_rect) in expected_rects.items():
        value = anchors.get(key, {})
        if value.get("rect_design") != rect or value.get("safe_rect_design") != safe_rect:
            raise Invalid(f"{label} carrier anchor is stale: {key}")
    rank_value = anchors["rank_numeral_dock"]
    if (rank_value.get("center_design") != [512, 136]
            or rank_value.get("safe_rect_design") != [466, 88, 92, 96]):
        raise Invalid(f"{label} rank numeral dock anchor is stale")
    gem = anchors["gem_slot"]
    if (gem.get("shape") != "regular-equilateral-hexagon"
            or gem.get("center_design") != [512, 1421]
            or gem.get("visible_size_design") != [132, 114]
            or gem.get("name_clearance_design") != 12):
        raise Invalid(f"{label} carrier gem slot is stale")

    if contract["protected_regions"] != {
        "pathway_crown": "mother-crown-protected",
        "rank_numeral": "rank-numeral-safe",
        "right_sequence_zone": "right-sequence-zone",
        "name_surface": "name-surface",
        "gem_slot": "gem-slot",
        "outside_edit_domain": "outside-edit-domain",
    }:
        raise Invalid(f"{label} carrier protected-region mapping is stale")

    if contract["mask_policy"] != {
        "generated_by": ctx["frame_generator"],
        "coordinate_space": "native-canvas",
        "alpha_policy": "straight-RGBA",
        "no_crop_reassembly": True,
    }:
        raise Invalid(f"{label} carrier mask policy is stale")
    thresholds = contract["thresholds"]
    if (thresholds.get("geometry_displacement_max_px") != 0
            or thresholds.get("outside_edit_domain_pixels_max") != 0
            or thresholds.get("zone_center_error_max_native_px") != 1
            or thresholds.get("protected_region_intersections_max") != 0):
        raise Invalid(f"{label} carrier zero-drift thresholds are stale")

    return {
        "passed": True,
        "status": "passed",
        "contract": contract_rel,
        "contract_sha256": sha(contract_path),
        "geometry_id": contract["geometry_id"],
        "emblem_dock_mode": route["emblem_dock_mode"],
        "through_hole": route["through_hole"],
        "gem_slot": gem,
        "thresholds": thresholds,
        "active_frame_source": active_frame["path"],
        "limitation": "当前愚者路线已执行固定 RankNumeralDock；通用 EmblemDock 模板仅提供非穿透结构语法，不代表所有途径已完成嵌座生产。",
    }


def validate_fool_carrier_contract(root):
    """Thin wrapper: keep the Fool route reachable through the generic entry."""
    return validate_pathway_carrier_contract(root, "fool")


def _read_wav_format(path):
    try:
        with wave.open(str(path), "rb") as audio:
            info = {
                "channels": audio.getnchannels(),
                "sample_rate": audio.getframerate(),
                "bits": audio.getsampwidth() * 8,
                "frames": audio.getnframes(),
                "duration_seconds": audio.getnframes() / audio.getframerate(),
                "compression": audio.getcomptype(),
            }
    except (OSError, wave.Error) as exc:
        raise Invalid("WAV is not decodable: " + str(path)) from exc
    if (info["channels"] != 1 or info["sample_rate"] != 24000
            or info["bits"] != 16 or info["frames"] <= 0
            or info["compression"] != "NONE"):
        raise Invalid("WAV format must be 24kHz Int16 mono PCM: " + str(path))
    return info


def validate_fool_audio_package(root):
    """Validate the two current Fool card packages and their App resources.

    This is intentionally stricter than a narrative check: every approved line
    must have exactly one measured WAV, and the installed fixture may contain no
    unrelated card art or audio. Audrey is checked separately by
    validate_external_audrey_assets and is deliberately outside this whitelist.
    """
    root = Path(root).resolve()
    packages = [
        {
            "card_id": "lotm.fool.s09.klein-moretti.tingen-01",
            "narrative": "production/narratives/klein-s09-tingen.json",
            "audio_manifest": "artifacts/lotm.fool.s09/audio-v001/generation.json",
            "audio_root": "artifacts/lotm.fool.s09/audio-v001",
            "voice_profile_id": "dylan",
        },
        {
            "card_id": "lotm.fool.s00.klein-moretti.mr-fool-01",
            "narrative": "production/narratives/mr-fool-s00.json",
            "audio_manifest": "artifacts/lotm.fool.s00/audio-v002/generation.json",
            "audio_root": "artifacts/lotm.fool.s00/audio-v002",
            "voice_profile_id": "uncle_fu",
        },
        {
            "card_id": "lotm.celestial-worthy.primordial-01",
            "narrative": "production/narratives/celestial-worthy.json",
            "audio_manifest": "artifacts/lotm.celestial-worthy/audio-v001/generation.json",
            "audio_root": "artifacts/lotm.celestial-worthy/audio-v001",
            "voice_profile_id": "celestial-worthy",
        },
        {
            "card_id": "lotm.god-almighty.primordial-01",
            "narrative": "production/narratives/god-almighty.json",
            "audio_manifest": "artifacts/lotm.god-almighty/audio-v001/generation.json",
            "audio_root": "artifacts/lotm.god-almighty/audio-v001",
            "voice_profile_id": "god-almighty",
        },
        {
            "card_id": "lotm.mother-goddess-depravity.primordial-01",
            "narrative": "production/narratives/mother-goddess-depravity.json",
            "audio_manifest": "artifacts/lotm.mother-goddess-depravity/audio-v001/generation.json",
            "audio_root": "artifacts/lotm.mother-goddess-depravity/audio-v001",
            "voice_profile_id": "mother-goddess-depravity",
        },
        {
            "card_id": "lotm.eternal-darkness.primordial-01",
            "narrative": "production/narratives/eternal-darkness.json",
            "audio_manifest": "artifacts/lotm.eternal-darkness/audio-v001/generation.json",
            "audio_root": "artifacts/lotm.eternal-darkness/audio-v001",
            "voice_profile_id": "eternal-darkness",
        },
        {
            "card_id": "lotm.father-of-demons.primordial-01",
            "narrative": "production/narratives/father-of-demons.json",
            "audio_manifest": "artifacts/lotm.father-of-demons/audio-v001/generation.json",
            "audio_root": "artifacts/lotm.father-of-demons/audio-v001",
            "voice_profile_id": "father-of-demons",
        },
        {
            "card_id": "lotm.destruction-calamity.primordial-01",
            "narrative": "production/narratives/destruction-calamity.json",
            "audio_manifest": "artifacts/lotm.destruction-calamity/audio-v001/generation.json",
            "audio_root": "artifacts/lotm.destruction-calamity/audio-v001",
            "voice_profile_id": "destruction-calamity",
        },
        {
            "card_id": "lotm.embodiment-of-disorder.primordial-01",
            "narrative": "production/narratives/embodiment-of-disorder.json",
            "audio_manifest": "artifacts/lotm.embodiment-of-disorder/audio-v001/generation.json",
            "audio_root": "artifacts/lotm.embodiment-of-disorder/audio-v001",
            "voice_profile_id": "embodiment-of-disorder",
        },
        {
            "card_id": "lotm.demon-of-knowledge.primordial-01",
            "narrative": "production/narratives/demon-of-knowledge.json",
            "audio_manifest": "artifacts/lotm.demon-of-knowledge/audio-v001/generation.json",
            "audio_root": "artifacts/lotm.demon-of-knowledge/audio-v001",
            "voice_profile_id": "demon-of-knowledge",
        },
        {
            "card_id": "lotm.key-of-light.primordial-01",
            "narrative": "production/narratives/key-of-light.json",
            "audio_manifest": "artifacts/lotm.key-of-light/audio-v001/generation.json",
            "audio_root": "artifacts/lotm.key-of-light/audio-v001",
            "voice_profile_id": "key-of-light",
        },
    ]
    card_reports = []
    audio_records = []
    for package in packages:
        narrative_path = inside(root, package["narrative"])
        pack = validate_narrative(root, read(narrative_path), ready_for_audio=True)
        if pack["identity"]["cardID"] != package["card_id"]:
            raise Invalid("audio narrative identity disagrees: " + package["card_id"])
        expected_digests = {
            narrative_digest(pack, entry): entry["id"] for entry in pack["entries"]
        }
        manifest_path = inside(root, package["audio_manifest"])
        manifest = read(manifest_path)
        if manifest.get("card_id") != package["card_id"]:
            raise Invalid("audio manifest card identity disagrees: " + package["card_id"])
        if manifest.get("voice_profile_id") != package["voice_profile_id"]:
            raise Invalid("audio manifest voice disagrees: " + package["card_id"])
        service = manifest.get("service", {})
        if (service.get("base_url") != "http://127.0.0.1:8201"
                or service.get("response_format") != "wav"
                or service.get("language") != "zh"):
            raise Invalid("audio manifest service contract is stale: " + package["card_id"])
        files = manifest.get("files", [])
        if len(files) != 6:
            raise Invalid("audio manifest must contain six files: " + package["card_id"])
        seen_digests = set()
        seen_names = set()
        for item in files:
            resource_name = item.get("resource_name", "")
            if not re.fullmatch(r"[a-z0-9-]+", resource_name):
                raise Invalid("invalid audio resource name: " + resource_name)
            if resource_name in seen_names:
                raise Invalid("duplicate audio resource name: " + resource_name)
            seen_names.add(resource_name)
            text_digest = item.get("text_digest")
            if text_digest not in expected_digests:
                raise Invalid("audio text digest is not bound to narrative: " + resource_name)
            if text_digest in seen_digests:
                raise Invalid("duplicate audio text binding: " + resource_name)
            seen_digests.add(text_digest)
            rel = f'{package["audio_root"]}/{resource_name}.wav'
            path = inside(root, rel)
            if not path.is_file() or sha(path) != item.get("sha256"):
                raise Invalid("audio file hash is stale: " + rel)
            fmt = _read_wav_format(path)
            if abs(fmt["duration_seconds"] - float(item.get("duration_seconds", -1))) > 0.02:
                raise Invalid("audio duration record is stale: " + rel)
            audio_records.append({
                "card_id": package["card_id"],
                "resource_name": resource_name,
                "path": rel,
                "sha256": item["sha256"],
                "format": fmt,
            })
        if seen_digests != set(expected_digests):
            raise Invalid("audio manifest does not cover every narrative line: " + package["card_id"])
        audio_root = inside(root, package["audio_root"])
        actual_names = {path.stem for path in audio_root.glob("*.wav")}
        if actual_names != seen_names:
            raise Invalid("audio directory contains an orphan or missing WAV: " + package["card_id"])
        card_reports.append({
            "card_id": package["card_id"],
            "voice_profile_id": package["voice_profile_id"],
            "file_count": len(files),
        })

    expected_card_art = {
        "fool-s00-card-agentic-v1-v001": "artifacts/production/fool-s00-card-agentic-v1/v001/raw.png",
        "fool-s09-card-name-edit-v1-v001": "artifacts/production/fool-s09-card-name-edit-v1/v001/raw.png",
        "celestial-worthy-card-v1-v001": "artifacts/production/celestial-worthy-card-v1/v001/raw.png",
        "god-almighty-card-v1-v001": "artifacts/production/god-almighty-card-v1/v001/raw.png",
        "mother-goddess-depravity-card-v1-v001": "artifacts/production/mother-goddess-depravity-card-v1/v001/raw.png",
        "eternal-darkness-card-v1-v001": "artifacts/production/eternal-darkness-card-v1/v001/raw.png",
        "father-of-demons-card-v1-v001": "artifacts/production/father-of-demons-card-v1/v001/raw.png",
        "destruction-calamity-card-v1-v001": "artifacts/production/destruction-calamity-card-v1/v001/raw.png",
        "embodiment-of-disorder-card-v1-v001": "artifacts/production/embodiment-of-disorder-card-v1/v001/raw.png",
        "demon-of-knowledge-card-v1-v001": "artifacts/production/demon-of-knowledge-card-v1/v001/raw.png",
        "key-of-light-card-v1-v001": "artifacts/production/key-of-light-card-v1/v001/raw.png",
    }
    card_art_root = inside(root, "apps/LotmCardStudio/Resources/CardArt")
    card_art_names = sorted(path.stem for path in card_art_root.glob("*.png"))
    if card_art_names != sorted(expected_card_art):
        raise Invalid("App CardArt whitelist does not match the registered card art")
    for name, source_rel in expected_card_art.items():
        app_path = card_art_root / (name + ".png")
        source_path = inside(root, source_rel)
        if sha(app_path) != sha(source_path):
            raise Invalid("App card art disagrees with current Fool source: " + name)

    expected_audio_names = sorted(item["resource_name"] for item in audio_records)
    app_audio_root = inside(root, "apps/LotmCardStudio/Resources/Audio")
    app_audio_names = sorted(path.stem for path in app_audio_root.glob("*.wav"))
    if app_audio_names != expected_audio_names:
        raise Invalid("App Audio whitelist contains an orphan or missing WAV")
    for item in audio_records:
        app_path = app_audio_root / (item["resource_name"] + ".wav")
        if sha(app_path) != item["sha256"]:
            raise Invalid("App audio disagrees with production audio: " + item["resource_name"])

    return {
        "status": "passed",
        "card_count": len(card_reports),
        "cards": card_reports,
        "audio_file_count": len(audio_records),
        "app": {
            "card_art_count": len(card_art_names),
            "card_art_names": card_art_names,
            "audio_file_count": len(app_audio_names),
            "audio_resource_names": app_audio_names,
        },
        "limitation": "校验资源完整性、绑定摘要和安装包白名单；不替代真人试听、事实复核或视觉批准。",
    }


def validate_fool_materials(root):
    """Validate the retained Fool visual baseline after recoverable cleanup.

    This gate intentionally reads only the current baseline catalogs. Historical
    catalogs may retain provenance paths to files in Trash, but they must not be
    treated as active production inputs.
    """
    root = Path(root).resolve()
    audrey_preservation = validate_external_audrey_assets(root)
    carrier_contract = validate_fool_carrier_contract(root)
    audio_package = validate_fool_audio_package(root)
    tier_order = ["low", "mid", "saint", "angel", "true-god"]
    expected_mapping = {
        "low": [9, 8],
        "mid": [7, 6, 5],
        "saint": [4, 3],
        "angel": [2, 1],
        "true-god": [0],
    }

    def required_file(rel, label):
        path = inside(root, rel)
        if not path.is_file():
            raise Invalid(f"{label} missing: {rel}")
        return path

    def checked_image(rel, label, expected_size=None):
        path = required_file(rel, label)
        try:
            info = cardctl.image_info(path)
        except (OSError, cardctl.DataError) as exc:
            raise Invalid(f"{label} unreadable: {rel}: {exc}") from exc
        if info["format"] != "PNG":
            raise Invalid(f"{label} must be PNG: {rel}")
        if expected_size and [info["width"], info["height"]] != list(expected_size):
            raise Invalid(f"{label} has wrong native size: {rel}")
        return path, info

    catalog_rel = "production/symbols/fool-five-tier-kit.json"
    catalog_path = required_file(catalog_rel, "Fool five-tier catalog")
    catalog = read(catalog_path)
    if catalog.get("pathway_id") != "fool":
        raise Invalid("current five-tier catalog is not for the Fool pathway")
    if catalog.get("status") != "official-agentic-visual-material-baseline":
        raise Invalid("current five-tier catalog is not the official visual baseline")
    if catalog.get("sequence_mapping") != expected_mapping:
        raise Invalid("current five-tier sequence mapping is stale or non-bijective")
    if catalog.get("resolution_policy", {}).get("native_source_is_canonical") is not True:
        raise Invalid("native source is not canonical")
    if catalog.get("resolution_policy", {}).get("intermediate_2k_count") != 0:
        raise Invalid("current five-tier policy permits an intermediate 2K stage")
    if catalog.get("resolution_policy", {}).get("final_card_only_sampling") is not True:
        raise Invalid("final-only sampling policy is not enabled")

    output_rel = catalog.get("active_output")
    if output_rel != "artifacts/production/fool-five-tier-direct-kit-v1":
        raise Invalid("current five-tier output is not the direct native kit")
    output = inside(root, output_rel)
    manifest_record = catalog.get("active_manifest")
    if not isinstance(manifest_record, dict):
        raise Invalid("active five-tier manifest record missing")
    verify_records(root, [manifest_record])
    require_visual_approval_sidecar(root, manifest_record["path"], required_file)
    manifest = read(required_file(manifest_record["path"], "active five-tier manifest"))
    if manifest.get("mode") != "fool-five-tier-direct-batch-v1":
        raise Invalid("active five-tier manifest is not the direct Agentic batch")
    if manifest.get("direct_agentic_sources") is not True:
        raise Invalid("active five-tier manifest is not direct Agentic source")
    if manifest.get("color_transform") != "none":
        raise Invalid("active five-tier manifest contains a color transform")
    if manifest.get("geometry_id") != "fool-agentic-mother-v2":
        raise Invalid("active five-tier geometry is stale")
    if manifest.get("no_cross_product_variants") is not True:
        raise Invalid("active five-tier manifest permits cross-product variants")
    if manifest.get("status") not in NATIVE_BASELINE_STATUSES:
        raise Invalid("active five-tier manifest is not a native Agentic material baseline")
    if manifest.get("native_frame_hashes", {}).keys() != set(tier_order):
        raise Invalid("active five-tier manifest does not contain exactly five native frames")
    if manifest.get("gem_slot", {}).get("mode") != "embedded-in-direct-tier-frame-no-synthetic-overlay":
        raise Invalid("active five-tier gem contract is not embedded in the complete frame")
    if manifest.get("gem_slot", {}).get("variant_count") != 5:
        raise Invalid("active five-tier gem count is not five")

    layered_rel = "production/symbols/fool-layered-asset-baseline-v1.json"
    layered = read(required_file(layered_rel, "active Fool layered-asset baseline"))
    if layered.get("pathway_id") != "fool" or layered.get("status") != "user-approved-agentic-visual-baseline":
        raise Invalid("active Fool layered-asset baseline is stale")
    graph = layered.get("asset_graph", {})
    reusable_graph = graph.get("reusable_materials", {})
    if reusable_graph.get("catalog") != catalog_rel or reusable_graph.get("catalog_sha256") != sha(catalog_path):
        raise Invalid("layered-asset reusable-material catalog is stale")
    frame_graph = graph.get("quality_frames", {})
    if (frame_graph.get("catalog") != catalog_rel
            or frame_graph.get("manifest") != manifest_record["path"]
            or frame_graph.get("manifest_sha256") != manifest_record["sha256"]
            or frame_graph.get("native_output") != output_rel
            or frame_graph.get("geometry_id") != manifest["geometry_id"]):
        raise Invalid("layered-asset quality-frame pointer is stale")
    frame_rows = frame_graph.get("tiers", [])
    if [row.get("id") for row in frame_rows] != tier_order:
        raise Invalid("layered-asset quality-frame order is stale")
    for row in frame_rows:
        tier = row["id"]
        expected_rel = f"{output_rel}/frame-{tier}-native.png"
        if (row.get("path") != expected_rel
                or row.get("sha256") != manifest["native_frame_hashes"].get(tier)
                or row.get("sequences") != expected_mapping[tier]):
            raise Invalid(f"layered-asset {tier} frame pointer is stale")
    sequence_graph = graph.get("sequence_frames", {})
    sequence_rel = "production/symbols/fool-agentic-sequence-inscriptions-v2.json"
    if (sequence_graph.get("catalog") != sequence_rel
            or sequence_graph.get("catalog_sha256") != sha(inside(root, sequence_rel))
            or sequence_graph.get("output_root") != "artifacts/production/fool-agentic-sequence-inscriptions-v2/studies"):
        raise Invalid("layered-asset sequence-frame pointer is stale")
    fusion_graph = graph.get("fusion_reference", {})
    if (fusion_graph.get("catalog") != "production/symbols/fool-fusion-family.json"
            or fusion_graph.get("role") != "historical-reference-only"):
        raise Invalid("layered-asset fusion reference is stale")
    layered_policy = layered.get("resolution_policy", {})
    if (layered_policy.get("native_canvas") != [1024, 1536]
            or layered_policy.get("intermediate_2k_count") != 0
            or layered_policy.get("final_sampling") != "only-after-complete-card-approval"
            or layered_policy.get("no_local_2k_repair") is not True
            or layered_policy.get("no_crop_reassembly") is not True):
        raise Invalid("layered-asset resolution policy is stale")
    if (layered.get("acceptance", {}).get("formal_release_approved") is not False
            or layered.get("historical_boundary", {}).get("superseded") is None):
        raise Invalid("layered-asset acceptance boundary is stale")
    layered_sidecar = layered.get("acceptance", {}).get("approval_sidecar", {})
    if not isinstance(layered_sidecar, dict) or not layered_sidecar.get("path"):
        raise Invalid("layered-asset approval sidecar binding is missing")
    verify_records(root, [layered_sidecar])

    reusable_materials = catalog.get("retained_reusable_materials", {})
    material_entries = reusable_materials.get("entries", [])
    if reusable_materials.get("status") != "retained-reference-assets":
        raise Invalid("retained reusable material catalog is missing or stale")
    if reusable_materials.get("embedded_in_active_frames") is not False:
        raise Invalid("retained reusable materials cannot be treated as frame overlays")
    if len(material_entries) != 5 or {item.get("id") for item in material_entries} != {
            "material-fool-veil", "material-gold", "material-high-filament",
            "material-sacred-slate", "material-silver-flat"}:
        raise Invalid("retained reusable material catalog must contain exactly five inputs")
    for item in material_entries:
        rel = item.get("path", "")
        material_path, material_info = checked_image(rel, f"retained material {item.get('id', '')}", (1024, 1536))
        if sha(material_path) != item.get("sha256"):
            raise Invalid(f"retained material hash is stale: {rel}")
        if item.get("size_px") != [material_info["width"], material_info["height"]]:
            raise Invalid(f"retained material size record is stale: {rel}")
        if item.get("status") != "retained-reference":
            raise Invalid(f"retained material status is invalid: {rel}")
        receipt_rel = rel.removesuffix("/raw.png") + "/receipt.json"
        receipt = read(required_file(receipt_rel, f"retained material receipt {item.get('id', '')}"))
        raw = receipt.get("raw", {})
        if raw.get("path") != rel or raw.get("sha256") != item.get("sha256"):
            raise Invalid(f"retained material receipt disagrees with catalog: {rel}")

    native_files = []
    for tier in tier_order:
        rel = f"{output_rel}/frame-{tier}-native.png"
        path, info = checked_image(rel, f"native {tier} frame", (1024, 1536))
        expected_digest = manifest["native_frame_hashes"][tier]
        if sha(path) != expected_digest:
            raise Invalid(f"native {tier} frame hash is stale")
        native_files.append(rel)

    intermediate_2k_files = []
    if output.is_dir():
        for path in output.rglob("*.png"):
            info = cardctl.image_info(path)
            if [info["width"], info["height"]] == [2048, 3072]:
                intermediate_2k_files.append(path.relative_to(root).as_posix())
    if intermediate_2k_files:
        raise Invalid("intermediate 2K files remain in active five-tier output: " + ", ".join(intermediate_2k_files))

    sidecar_rel = "production/approvals/fool-agentic-visual-baseline-v1.json"
    sidecar = read(required_file(sidecar_rel, "visual baseline sidecar"))
    approved = sidecar.get("approved_assets", {})
    mother = approved.get("mother_frame", {})
    mother_path, mother_info = checked_image(mother.get("path", ""), "approved mother source", (1024, 1536))
    if sha(mother_path) != mother.get("sha256"):
        raise Invalid("approved mother source hash is stale")
    if sidecar.get("material_status", {}).get("native_source_is_canonical") is not True:
        raise Invalid("visual baseline sidecar does not mark native sources canonical")
    sidecar_tiers = approved.get("five_tier_frames", {})
    if sidecar_tiers.get("manifest_path") != manifest_record["path"]:
        raise Invalid("sidecar manifest path disagrees with active kit")
    if sidecar_tiers.get("manifest_sha256") != manifest_record["sha256"]:
        raise Invalid("sidecar manifest hash disagrees with active kit")
    contact_rel = sidecar_tiers.get("contact_sheet_path", "")
    contact_path, _ = checked_image(contact_rel, "approved five-tier contact sheet")
    if sha(contact_path) != sidecar_tiers.get("contact_sheet_sha256"):
        raise Invalid("approved five-tier contact sheet hash is stale")
    sidecar_paths = sidecar_tiers.get("native_source_paths", {})
    sidecar_hashes = sidecar_tiers.get("native_source_sha256", {})
    for tier in tier_order:
        expected_rel = f"{output_rel}/frame-{tier}-native.png"
        if sidecar_paths.get(tier) != expected_rel:
            raise Invalid(f"sidecar native {tier} path disagrees with active kit")
        if sidecar_hashes.get(tier) != manifest["native_frame_hashes"][tier]:
            raise Invalid(f"sidecar native {tier} hash disagrees with active kit")

    sequence_catalog = read(required_file(sequence_rel, "current sequence catalog"))
    if sequence_catalog.get("stage") != "agentic-complete-frame-baseline":
        raise Invalid("current sequence catalog is not the complete-frame Agentic baseline")
    sequence_entries = sequence_catalog.get("entries", [])
    if len(sequence_entries) != 10 or {e.get("digit") for e in sequence_entries} != set(range(10)):
        raise Invalid("current sequence catalog does not contain exactly ten digits")
    sequence_outputs = []
    for entry in sorted(sequence_entries, key=lambda item: item["digit"]):
        digit = entry["digit"]
        if entry.get("sequence_id") != f"lotm.fool.s{digit:02d}":
            raise Invalid(f"sequence {digit} identity is stale")
        if entry.get("tier") != visual_quality(root, digit)["id"]:
            raise Invalid(f"sequence {digit} tier disagrees with quality configuration")
        candidate = entry.get("candidate_output", {})
        rel = candidate.get("path", "")
        path, info = checked_image(rel, f"sequence {digit} candidate", (1024, 1536))
        if sha(path) != candidate.get("sha256"):
            raise Invalid(f"sequence {digit} candidate hash is stale")
        if candidate.get("status") != "user-approved-agentic-baseline":
            raise Invalid(f"sequence {digit} candidate is not the approved Agentic baseline")
        sequence_outputs.append(rel)

    fusion_rel = "production/symbols/fool-fusion-family.json"
    fusion = read(required_file(fusion_rel, "current fusion catalog"))
    if fusion.get("current_user_approval", {}).get("digits") != list(range(10)):
        raise Invalid("current fusion approval does not cover all ten digits")
    fusion_entries = fusion.get("entries", [])
    if len(fusion_entries) != 10 or [e.get("digit") for e in fusion_entries] != list(range(10)):
        raise Invalid("current fusion catalog is not ordered one-to-one")
    emblem_by_digit = {item["digit"]: item for item in catalog.get("emblem_inputs", [])}
    retained_runs = {}
    fusion_outputs = []
    for entry in fusion_entries:
        digit = entry["digit"]
        if entry.get("retention") != "keep":
            raise Invalid(f"fusion {digit} is not marked retained")
        if not (entry.get("art_review", {}).get("status", "").startswith("user-approved-")):
            raise Invalid(f"fusion {digit} has no current visual approval")
        raw_rel = entry.get("raw", "")
        raw_path, _ = checked_image(raw_rel, f"fusion {digit}")
        if sha(raw_path) != emblem_by_digit.get(digit, {}).get("sha256"):
            raise Invalid(f"fusion {digit} disagrees with five-tier emblem input")
        expected_rel = emblem_by_digit.get(digit, {}).get("path")
        if raw_rel != expected_rel:
            raise Invalid(f"fusion {digit} path disagrees with five-tier emblem input")
        match = re.fullmatch(r"artifacts/production/fool-fusion-(\d)/(v\d{3})/raw\.png", raw_rel)
        if not match or int(match.group(1)) != digit:
            raise Invalid(f"fusion {digit} path does not identify its digit and run")
        parent = inside(root, f"artifacts/production/fool-fusion-{digit}")
        runs = sorted(p.name for p in parent.iterdir() if p.is_dir() and re.fullmatch(r"v\d{3}", p.name)) if parent.is_dir() else []
        if runs != [match.group(2)]:
            raise Invalid(f"fusion {digit} must retain exactly one versioned run; found {runs}")
        retained_runs[str(digit)] = match.group(2)
        fusion_outputs.append(raw_rel)

    numerals_rel = "production/symbols/fool-rank-numerals-v1.json"
    numerals = read(required_file(numerals_rel, "standalone numeral catalog"))
    if numerals.get("status") != "retired-standalone-numerals":
        raise Invalid("standalone numerals are still marked active")
    retirement = numerals.get("retirement", {})
    if retirement.get("status") != "moved-to-trash" or retirement.get("preserved_replacement") != fusion_rel:
        raise Invalid("standalone numeral retirement does not point to the fusion family")

    preservation = read(required_file("production/symbols/fool-fusion-preservation.json", "fusion preservation ledger"))
    for item in preservation.get("preserved", []):
        path, _ = checked_image(item["path"], f"preserved fusion {item['digit']}")
        if sha(path) != item.get("sha256") or item.get("retention") != "keep":
            raise Invalid(f"preserved fusion record is stale: {item.get('digit')}")
    for item in preservation.get("retired_versions", []):
        if item.get("status") != "moved-to-trash":
            raise Invalid(f"retired fusion record is not recoverably retired: {item.get('digit')}")
        if inside(root, item["path"]).exists():
            raise Invalid(f"retired fusion file still exists: {item['path']}")

    cleanup_rel = "production/retirements/fool-failed-materials-2026-09-14.json"
    cleanup = read(required_file(cleanup_rel, "cleanup ledger"))
    if cleanup.get("status") != "moved-to-trash" or cleanup.get("recoverability") != "macOS Trash; restore manually if user reverses the decision":
        raise Invalid("cleanup ledger does not describe recoverable Trash cleanup")
    moved = cleanup.get("moved_to_trash", [])
    moved_paths = [item.get("path") for item in moved]
    if len(moved_paths) != len(set(moved_paths)):
        raise Invalid("cleanup ledger contains duplicate moved paths")
    for rel in moved_paths:
        if inside(root, rel).exists():
            raise Invalid("cleanup ledger path still exists: " + rel)

    return {
        "passed": True,
        "status": "passed",
        "active_five_tier_output": output_rel,
        "layered_asset_baseline": layered_rel,
        "retained_reusable_material_count": len(material_entries),
        "tier_count": len(native_files),
        "sequence_count": len(sequence_outputs),
        "fusion_digit_count": len(fusion_outputs),
        "retained_fusion_runs": retained_runs,
        "intermediate_2k_count": len(intermediate_2k_files),
        "standalone_numeral_status": numerals["status"],
        "active_fusion_catalog": fusion_rel,
        "carrier_contract": carrier_contract,
        "audio_package": audio_package,
        "audrey_external_preservation": audrey_preservation,
        "retired_path_count": len(moved_paths),
        "limitation": "Validates current records, paths, hashes and native dimensions; visual approval remains represented by the recorded user baseline.",
    }


def _decode_png_rows(path):
    """Decode the small 8-bit RGB/RGBA PNG subset needed for native audits."""
    try:
        info = cardctl.image_info(path)
    except (OSError, cardctl.DataError) as exc:
        raise Invalid("PNG pixel audit cannot read image: " + str(exc)) from exc
    if info["format"] != "PNG":
        raise Invalid("PNG pixel audit requires PNG input")
    data = Path(path).read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise Invalid("PNG pixel audit has invalid signature")
    offset = 8
    width = height = depth = color = interlace = None
    compressed = []
    while offset < len(data):
        if offset + 12 > len(data):
            raise Invalid("PNG pixel audit has truncated chunk")
        length = struct.unpack(">I", data[offset:offset + 4])[0]
        kind = data[offset + 4:offset + 8]
        start = offset + 8
        end = start + length
        if end + 4 > len(data):
            raise Invalid("PNG pixel audit has truncated payload")
        chunk = data[start:end]
        if kind == b"IHDR":
            if len(chunk) != 13:
                raise Invalid("PNG pixel audit has invalid IHDR")
            width, height, depth, color, _, _, interlace = struct.unpack(">IIBBBBB", chunk)
        elif kind == b"IDAT":
            compressed.append(chunk)
        elif kind == b"IEND":
            break
        offset = end + 4
    if width != info["width"] or height != info["height"] or depth != 8 or interlace != 0:
        raise Invalid("PNG pixel audit supports only non-interlaced 8-bit PNG")
    if color not in (2, 6) or not compressed:
        raise Invalid("PNG pixel audit supports only RGB/RGBA PNG")
    channels = 3 if color == 2 else 4
    stride = width * channels
    try:
        decoded = zlib.decompress(b"".join(compressed))
    except zlib.error as exc:
        raise Invalid("PNG pixel audit compressed data is invalid") from exc
    row_size = stride + 1
    if len(decoded) != row_size * height:
        raise Invalid("PNG pixel audit scanline length is invalid")

    def paeth(a, b, c):
        estimate = a + b - c
        pa, pb, pc = abs(estimate - a), abs(estimate - b), abs(estimate - c)
        if pa <= pb and pa <= pc:
            return a
        if pb <= pc:
            return b
        return c

    rows = []
    previous = bytearray(stride)
    cursor = 0
    for _ in range(height):
        filter_type = decoded[cursor]
        source = decoded[cursor + 1:cursor + row_size]
        cursor += row_size
        row = bytearray(stride)
        for index, value in enumerate(source):
            left = row[index - channels] if index >= channels else 0
            up = previous[index]
            upper_left = previous[index - channels] if index >= channels else 0
            if filter_type == 0:
                estimate = 0
            elif filter_type == 1:
                estimate = left
            elif filter_type == 2:
                estimate = up
            elif filter_type == 3:
                estimate = (left + up) // 2
            elif filter_type == 4:
                estimate = paeth(left, up, upper_left)
            else:
                raise Invalid("PNG pixel audit encountered unknown filter")
            row[index] = (value + estimate) & 0xFF
        rows.append(bytes(row))
        previous = row
    return width, height, channels, rows


def _compare_png_pixels(left_path, right_path, protected_rect):
    left = _decode_png_rows(left_path)
    right = _decode_png_rows(right_path)
    if left[:3] != right[:3]:
        raise Invalid("PNG pixel audit inputs differ in dimensions or channel type")
    width, height, channels = left[:3]
    x0, y0, w, h = [int(value) for value in protected_rect]
    x1, y1 = x0 + w, y0 + h
    if x0 < 0 or y0 < 0 or w < 0 or h < 0 or x1 > width or y1 > height:
        raise Invalid("PNG pixel audit protected rectangle is out of bounds")
    changed = 0
    changed_inside = 0
    changed_outside = 0
    min_x, min_y = width, height
    max_x = max_y = -1
    for y, (a_row, b_row) in enumerate(zip(left[3], right[3])):
        for x in range(width):
            start = x * channels
            if a_row[start:start + channels] == b_row[start:start + channels]:
                continue
            changed += 1
            min_x, max_x = min(min_x, x), max(max_x, x)
            min_y, max_y = min(min_y, y), max(max_y, y)
            if x0 <= x < x1 and y0 <= y < y1:
                changed_inside += 1
            else:
                changed_outside += 1
    bbox = None if changed == 0 else [min_x, min_y, max_x + 1, max_y + 1]
    return {
        "changed_pixels": changed,
        "changed_ratio": changed / (width * height),
        "changed_inside_name_surface": changed_inside,
        "changed_outside_name_surface": changed_outside,
        "changed_bbox": bbox,
        "name_surface_rect": [x0, y0, w, h],
    }


CARD_MANIFEST_STATUSES = {"candidate-pending-user-visual-review", "user-visually-approved"}
CARD_APPROVAL_STATUSES = {"pending", "approved"}
NONSEQUENCE_APPROVAL_RECORD = "production/cards/fool-nonsequence-card-approvals-v1.json"


def validate_fool_nonsequence_card_approvals(root, manifest_rel=NONSEQUENCE_APPROVAL_RECORD):
    """Validate the nine non-sequence (序列之上) cards' user approval record.

    These cards have no task, receipt or sequence slot, so they are tracked by a
    dedicated aggregate record binding each native card, its immutable
    provenance, and the human approval sidecar by hash. The human sidecar — not
    any machine-written status string — is the approval authority, and no
    release deliverable may be claimed while final sampling has not run.
    """
    root = Path(root).resolve()
    manifest_path = inside(root, manifest_rel)
    if not manifest_path.is_file():
        raise Invalid("non-sequence card approval record missing: " + manifest_rel)
    manifest = read(manifest_path)
    if manifest.get("schema_version") != "1.0.0" or manifest.get("kind") != "card_approval_aggregate":
        raise Invalid("non-sequence card approval record schema is stale")
    if manifest.get("status") != "user-visually-approved":
        raise Invalid("non-sequence card approval record status is invalid")
    if manifest.get("sequence_slots") is not False:
        raise Invalid("non-sequence card approval record must not claim sequence slots")
    if manifest.get("formal_release_approved") is not False:
        raise Invalid("non-sequence card approval record cannot claim formal release")
    policy = manifest.get("native_canvas_policy", {})
    if (policy.get("source_is_canonical") is not True
            or policy.get("intermediate_2k_count") != 0
            or policy.get("final_sampling_count") != 0):
        raise Invalid("non-sequence card native canvas policy is stale")

    sidecar_ref = manifest.get("approval_sidecar", {})
    if not isinstance(sidecar_ref, dict) or not sidecar_ref.get("path"):
        raise Invalid("non-sequence card approval sidecar reference is missing")
    verify_records(root, [sidecar_ref])
    sidecar = read(inside(root, sidecar_ref["path"]))
    if (sidecar.get("kind") != "visual_approval_sidecar"
            or sidecar.get("visual_approved") is not True
            or sidecar.get("release_approved") is not False
            or sidecar.get("sampling_executed") is not False):
        raise Invalid("non-sequence card approval sidecar contract is stale")
    sidecar_assets = {entry.get("card_id"): entry
                      for entry in sidecar.get("approved_assets", {}).get("nonsequence_cards", [])}

    cards = manifest.get("cards", [])
    if len(cards) != 9:
        raise Invalid("non-sequence card approval record must contain exactly nine cards")
    card_ids = [item.get("card_id") for item in cards]
    if any(not isinstance(cid, str) or not cid for cid in card_ids):
        raise Invalid("non-sequence card identity is missing")
    if len(card_ids) != len(set(card_ids)):
        raise Invalid("non-sequence card approval record contains duplicate cards")
    if any("sequence" in item for item in cards):
        raise Invalid("non-sequence card approval record must not declare a sequence slot")

    candidate_manifest = read(inside(root, "production/cards/fool-card-candidates-v1.json"))
    sequence_ids = {item.get("card_id") for item in candidate_manifest.get("cards", [])}
    if set(card_ids) & sequence_ids:
        raise Invalid("non-sequence card approval record overlaps the sequence manifest")

    native_sizes = {}
    for item in cards:
        card_id = item["card_id"]
        slug = card_id.split(".")[1] if len(card_id.split(".")) > 1 else ""
        slot_id = item.get("slot_id", "")
        if card_id != f"lotm.{slug}.primordial-01" or slot_id != f"lotm.{slug}":
            raise Invalid("non-sequence card slot identity is stale: " + card_id)
        path_rel = item.get("path", "")
        path = inside(root, path_rel)
        if not path.is_file() or sha(path) != item.get("sha256"):
            raise Invalid("non-sequence card art hash is stale: " + card_id)
        try:
            info = cardctl.image_info(path)
        except (OSError, cardctl.DataError) as exc:
            raise Invalid("non-sequence card art is unreadable: " + card_id) from exc
        if info["format"] != "PNG" or [info["width"], info["height"]] != [1024, 1536]:
            raise Invalid("non-sequence card art must be a native 1024x1536 PNG: " + card_id)
        if item.get("size_px") != [1024, 1536]:
            raise Invalid("non-sequence card size record is stale: " + card_id)
        provenance_rel = item.get("provenance", "")
        provenance_path = inside(root, provenance_rel)
        if not provenance_path.is_file() or sha(provenance_path) != item.get("provenance_sha256"):
            raise Invalid("non-sequence card provenance hash is stale: " + card_id)
        provenance = read(provenance_path)
        if provenance.get("card_id") != card_id or provenance.get("slot_id") != slot_id:
            raise Invalid("non-sequence card provenance identity disagrees: " + card_id)
        if provenance.get("status") != "candidate-pending-user-visual-approval":
            raise Invalid("non-sequence card provenance is not an ingest-time candidate record: " + card_id)
        approval = item.get("user_visual_approval", {})
        if approval.get("status") != "approved":
            raise Invalid("non-sequence card is not user-approved: " + card_id)
        if not (str(approval.get("by") or "").strip() and str(approval.get("reference") or "").strip()):
            raise Invalid("non-sequence card approval lacks evidence: " + card_id)
        asset = sidecar_assets.get(card_id)
        if not asset or asset.get("sha256") != item.get("sha256"):
            raise Invalid("non-sequence card approval is not bound to the human sidecar: " + card_id)
        if item.get("formal_release_approved") is not False:
            raise Invalid("non-sequence card cannot claim formal release: " + card_id)
        native_sizes[card_id] = item.get("size_px")

    return {
        "passed": True,
        "status": "passed",
        "manifest": manifest_rel,
        "card_count": len(cards),
        "card_ids": card_ids,
        "native_canvas_sizes": native_sizes,
        "approval_sidecar": sidecar_ref["path"],
        "formal_release_approved": False,
        "limitation": "Binds native art, immutable provenance and the human approval sidecar; it does not claim a 2K/4K deliverable or formal release.",
    }


def validate_fool_cards(root, manifest_rel="production/cards/fool-card-candidates-v1.json"):
    """Validate the current Fool target-card candidates without approving them.

    The card manifest is deliberately separate from the five-tier material gate:
    a valid frame library does not prove that a target card, its identity, or its
    narrative package is present. This check verifies the current candidate
    records, their ingested receipts, native dimensions, and pending status. It
    does not attempt to replace human visual or canon review.
    """
    root = Path(root).resolve()
    audrey_preservation = validate_external_audrey_assets(root)
    carrier_contract = validate_fool_carrier_contract(root)
    manifest_path = inside(root, manifest_rel)
    if not manifest_path.is_file():
        raise Invalid("Fool card candidate manifest missing: " + manifest_rel)
    manifest = read(manifest_path)
    if manifest.get("schema_version") != "1.0.0":
        raise Invalid("Fool card candidate manifest schema is stale")
    if manifest.get("status") not in CARD_MANIFEST_STATUSES:
        raise Invalid("Fool card candidate manifest status is invalid")
    policy = manifest.get("native_canvas_policy", {})
    if policy.get("source_is_canonical") is not True:
        raise Invalid("Fool card candidates must use the native source as canonical")
    if policy.get("intermediate_2k_count") != 0:
        raise Invalid("Fool card candidates contain an intermediate 2K stage")
    if policy.get("final_sampling_count") != 0:
        raise Invalid("candidate manifest claims final sampling before approval")
    if policy.get("final_sampling_required_after_approval") is not True:
        raise Invalid("candidate manifest does not require final sampling after approval")

    visual_review_ref = manifest.get("visual_review", {})
    if not isinstance(visual_review_ref, dict) or not visual_review_ref.get("path"):
        raise Invalid("Fool card visual review reference is missing")
    verify_records(root, [visual_review_ref])
    visual_review = read(inside(root, visual_review_ref["path"]))
    if (visual_review.get("schema_version") != "1.0.0"
            or visual_review.get("status") not in CARD_MANIFEST_STATUSES
            or visual_review.get("next_gate", {}).get("formal_release_approved") is not False):
        raise Invalid("Fool card visual review status is stale")
    review_cards = visual_review.get("cards", [])
    if len(review_cards) != 2:
        raise Invalid("Fool card visual review must contain S09 and S00")
    review_by_id = {item.get("card_id"): item for item in review_cards}
    if len(review_by_id) != len(review_cards):
        raise Invalid("Fool card visual review contains duplicate cards")

    sidecar_ref = manifest.get("approval_sidecar", {})
    if not isinstance(sidecar_ref, dict) or not sidecar_ref.get("path"):
        raise Invalid("card candidate approval sidecar reference is missing")
    verify_records(root, [sidecar_ref])
    sidecar = read(inside(root, sidecar_ref["path"]))
    if (sidecar.get("kind") != "visual_approval_sidecar"
            or sidecar.get("visual_approved") is not True
            or sidecar.get("release_approved") is not False
            or sidecar.get("sampling_executed") is not False):
        raise Invalid("card visual approval sidecar contract is stale")
    sidecar_assets = {}
    for bucket in ("sequence_cards", "nonsequence_cards"):
        for entry in sidecar.get("approved_assets", {}).get(bucket, []):
            sidecar_assets[entry.get("card_id")] = entry

    expected_ids = [
        "lotm.fool.s09.klein-moretti.tingen-01",
        "lotm.fool.s00.klein-moretti.mr-fool-01",
    ]
    cards = manifest.get("cards", [])
    if len(cards) != len(expected_ids) or [item.get("card_id") for item in cards] != expected_ids:
        raise Invalid("current Fool card manifest must contain S09 then S00 exactly once")
    for item in cards:
        review_item = review_by_id.get(item.get("card_id"))
        if not review_item:
            raise Invalid("Fool card visual review is missing: " + item.get("card_id", ""))
        source = review_item.get("source", {})
        if (source.get("path") != item.get("path")
                or source.get("sha256") != item.get("sha256")
                or source.get("size_px") != item.get("size_px")):
            raise Invalid("Fool card visual review source disagrees: " + item.get("card_id", ""))
        approval = review_item.get("user_visual_approval", {})
        if approval.get("status") not in CARD_APPROVAL_STATUSES:
            raise Invalid("Fool card visual review approval status is invalid: " + item.get("card_id", ""))
        if approval.get("status") == "approved":
            if not (str(approval.get("by") or "").strip()
                    and str(approval.get("reference") or "").strip()):
                raise Invalid("approved card review needs approval evidence: " + item.get("card_id", ""))
            bound = sidecar_assets.get(item.get("card_id"))
            if not bound or bound.get("sha256") != item.get("sha256"):
                raise Invalid("card review approval is not bound to the human sidecar: " + item.get("card_id", ""))

    name_contract = read(inside(root, "production/templates/fool-mother-frame-interface-v1.json"))
    name_surface = name_contract.get("name_surface", {})
    name_surface_rect = name_surface.get("rect_design")
    if not isinstance(name_surface_rect, list) or len(name_surface_rect) != 4:
        raise Invalid("Fool name surface geometry is missing")

    native_sizes = {}
    local_edit_status = None
    changed_ratio = None
    changed_outside_name = None
    recomputed_changed_pixels = None
    for item in cards:
        card_id = item.get("card_id", "")
        path_rel = item.get("path", "")
        path = inside(root, path_rel)
        if not path.is_file():
            raise Invalid("card candidate missing: " + path_rel)
        actual_hash = sha(path)
        if actual_hash != item.get("sha256"):
            raise Invalid("card candidate hash is stale: " + path_rel)
        try:
            info = cardctl.image_info(path)
        except (OSError, cardctl.DataError) as exc:
            raise Invalid("card candidate unreadable: " + path_rel + ": " + str(exc)) from exc
        if info["format"] != "PNG":
            raise Invalid("card candidate must be PNG: " + path_rel)
        if item.get("size_px") != [info["width"], info["height"]]:
            raise Invalid("card candidate size record is stale: " + path_rel)
        if [info["width"], info["height"]] != [1024, 1536]:
            raise Invalid("current Fool card candidate must remain native 1024x1536: " + path_rel)
        if abs(info["width"] / info["height"] - 2 / 3) > .04 * (2 / 3):
            raise Invalid("card candidate aspect is not 2:3: " + path_rel)

        sequence = item.get("sequence")
        if sequence not in (0, 9) or item.get("slot_id") != f"lotm.fool.s{sequence:02d}":
            raise Invalid("card candidate sequence identity is stale: " + card_id)
        if item.get("quality_tier") != visual_quality(root, sequence)["id"]:
            raise Invalid("card candidate quality tier is stale: " + card_id)
        source_rel = f"pathways/fool/sequences/{sequence:02d}/card.json"
        source = read(inside(root, source_rel))
        if source.get("card_id") != item.get("slot_id") or source.get("name_zh") != item.get("sequence_name"):
            raise Invalid("card candidate sequence name disagrees with source: " + card_id)

        task_rel = item.get("task", "")
        task = read(inside(root, task_rel))
        validate_task(root, task)
        spec = task.get("spec", {})
        if task.get("task_id") != Path(task_rel).stem:
            raise Invalid("card candidate task path/id disagrees: " + card_id)
        if spec.get("card_id") != card_id or spec.get("slot_id") != item.get("slot_id"):
            raise Invalid("card candidate task identity disagrees: " + card_id)
        protagonist = spec.get("protagonist", {})
        if protagonist.get("name_zh") != item.get("character_name"):
            raise Invalid("card candidate character name disagrees: " + card_id)
        if protagonist.get("name_status") != item.get("identity_name_status"):
            raise Invalid("card candidate identity status disagrees: " + card_id)
        if task.get("narrative", {}).get("path") != item.get("narrative"):
            raise Invalid("card candidate narrative path disagrees: " + card_id)

        receipt_rel = item.get("receipt", "")
        receipt = read(inside(root, receipt_rel))
        if receipt.get("task_id") != task.get("task_id"):
            raise Invalid("card candidate receipt task disagrees: " + card_id)
        raw = receipt.get("raw", {})
        if raw.get("path") != path_rel or raw.get("sha256") != item.get("sha256"):
            raise Invalid("card candidate receipt disagrees: " + card_id)
        if receipt.get("approval", {}).get("status") != "pending":
            raise Invalid("card candidate is not pending approval: " + card_id)
        if item.get("visual_status") not in CARD_MANIFEST_STATUSES:
            raise Invalid("card candidate visual status is invalid: " + card_id)
        approval = item.get("user_visual_approval", {})
        if approval.get("status") not in CARD_APPROVAL_STATUSES:
            raise Invalid("card candidate approval status is invalid: " + card_id)
        if approval.get("status") == "approved":
            bound = sidecar_assets.get(card_id)
            if not bound or bound.get("sha256") != item.get("sha256"):
                raise Invalid("card candidate approval is not sidecar-bound: " + card_id)
        if manifest.get("status") == "user-visually-approved" and approval.get("status") != "approved":
            raise Invalid("approved card manifest requires approved cards: " + card_id)
        if item.get("formal_release_approved") is not False:
            raise Invalid("card candidate cannot be formally released yet: " + card_id)
        native_sizes[f"s{sequence:02d}"] = item["size_px"]

        audit = item.get("local_edit_audit")
        if sequence == 9:
            if not isinstance(audit, dict):
                raise Invalid("S09 local edit audit missing")
            target = inside(root, audit.get("target", ""))
            if not target.is_file() or sha(target) != audit.get("target_sha256"):
                raise Invalid("S09 local edit target is stale")
            pixel_diff = _compare_png_pixels(target, path, name_surface_rect)
            recorded_diff = {
                "changed_pixels": audit.get("changed_pixels"),
                "changed_ratio": audit.get("changed_ratio"),
                "changed_inside_name_surface": audit.get("changed_inside_name_surface"),
                "changed_outside_name_surface": audit.get("changed_pixels_outside_name_surface"),
                "changed_bbox": audit.get("changed_bbox"),
                "name_surface_rect": audit.get("name_surface_rect"),
            }
            if recorded_diff != pixel_diff:
                raise Invalid("S09 pixel audit does not match recomputed PNG diff")
            changed_ratio = pixel_diff["changed_ratio"]
            changed_outside_name = pixel_diff["changed_outside_name_surface"]
            recomputed_changed_pixels = pixel_diff["changed_pixels"]
            if changed_outside_name <= 0:
                raise Invalid("S09 local edit audit must record outside-name changes")
            local_edit_status = audit.get("status")
            if local_edit_status != "rejected-global-rerender":
                raise Invalid("S09 local edit audit falsely claims zero drift")

    if manifest.get("formal_release_approved") is not False:
        raise Invalid("Fool card candidate manifest cannot be formally released")
    nonsequence_approvals = validate_fool_nonsequence_card_approvals(root)
    final_sampling = validate_fool_finalization_manifest(root)
    return {
        "passed": True,
        "status": "passed",
        "manifest": manifest_rel,
        "candidate_count": len(cards),
        "card_ids": expected_ids,
        "native_canvas_sizes": native_sizes,
        "s09_local_edit_status": local_edit_status,
        "s09_changed_ratio": changed_ratio,
        "s09_changed_pixels_outside_name_surface": changed_outside_name,
        "s09_recomputed_changed_pixels": recomputed_changed_pixels,
        "visual_review": {
            "status": visual_review["status"],
            "manifest": visual_review_ref["path"],
            "card_count": len(review_cards),
        },
        "final_sampling": final_sampling,
        "nonsequence_approvals": nonsequence_approvals,
        "carrier_contract": carrier_contract,
        "audrey_external_preservation": audrey_preservation,
        "formal_release_approved": manifest["formal_release_approved"],
        "limitation": "Validates current candidate records, receipts, hashes and native dimensions; visual, canon, rights and user approval remain separate gates.",
    }


FINAL_SAMPLING_PROFILES = {
    "standard": {"size_px": [2048, 3072]},
    "collector": {"size_px": [4096, 6144]},
}
FINAL_SAMPLING_MANIFEST = "production/cards/fool-final-sampling-v1.json"


def _finalization_card(manifest, card_id):
    cards = manifest.get("cards", [])
    matches = [item for item in cards if item.get("card_id") == card_id]
    if len(matches) != 1:
        raise Invalid("final sampling card must occur exactly once: " + card_id)
    return matches[0]


def validate_fool_finalization_manifest(root, manifest_rel=FINAL_SAMPLING_MANIFEST):
    """Validate the approval queue that guards one direct final resize."""
    root = Path(root).resolve()
    manifest_path = inside(root, manifest_rel)
    if not manifest_path.is_file():
        raise Invalid("Fool final sampling manifest missing: " + manifest_rel)
    manifest = read(manifest_path)
    if manifest.get("schema_version") != "1.0.0":
        raise Invalid("Fool final sampling manifest schema is stale")
    if manifest.get("status") not in {
        "pending-user-visual-approval", "partially-approved", "approved-for-final-sampling"
    }:
        raise Invalid("Fool final sampling manifest status is invalid")
    if manifest.get("formal_release_approved") is not False:
        raise Invalid("final sampling manifest cannot claim formal release")

    candidate_ref = manifest.get("candidate_manifest", {})
    if not isinstance(candidate_ref, dict) or not candidate_ref.get("path"):
        raise Invalid("final sampling candidate manifest reference is missing")
    candidate_path = inside(root, candidate_ref["path"])
    if (not candidate_path.is_file()
            or sha(candidate_path) != candidate_ref.get("sha256")):
        raise Invalid("final sampling candidate manifest hash is stale")
    candidate_manifest = read(candidate_path)
    if candidate_manifest.get("status") not in CARD_MANIFEST_STATUSES:
        raise Invalid("final sampling candidate manifest status is invalid")
    candidate_cards = candidate_manifest.get("cards", [])
    candidate_by_id = {item.get("card_id"): item for item in candidate_cards}
    if len(candidate_by_id) != len(candidate_cards):
        raise Invalid("final sampling candidate manifest contains duplicate cards")

    policy = manifest.get("policy", {})
    if policy.get("native_canvas") != [1024, 1536]:
        raise Invalid("final sampling native canvas must be 1024x1536")
    if policy.get("allowed_profiles") != FINAL_SAMPLING_PROFILES:
        raise Invalid("final sampling profile policy is stale")
    if policy.get("crop_count_before_final") != 0:
        raise Invalid("final sampling forbids crop before final")
    if policy.get("intermediate_2k_count") != 0:
        raise Invalid("intermediate 2K count must be zero before final sampling")
    if policy.get("final_resample_count_per_output") != 1:
        raise Invalid("final sampling must be exactly one transform per output")
    if policy.get("source_must_be_complete_native_card") is not True:
        raise Invalid("final sampling source must be a complete native card")

    cards = manifest.get("cards", [])
    if not isinstance(cards, list) or not cards:
        raise Invalid("final sampling manifest has no cards")
    card_ids = [item.get("card_id") for item in cards]
    if any(not isinstance(card_id, str) or not card_id for card_id in card_ids):
        raise Invalid("final sampling card identity is missing")
    if len(card_ids) != len(set(card_ids)):
        raise Invalid("final sampling manifest contains duplicate cards")

    approval_statuses = {}
    for item in cards:
        candidate_item = candidate_by_id.get(item.get("card_id"))
        if not candidate_item:
            raise Invalid("final sampling card is not a current candidate: " + item.get("card_id", ""))
        source_record = item.get("source_native", {})
        path_rel = source_record.get("path", "")
        if (candidate_item.get("path") != path_rel
                or candidate_item.get("sha256") != source_record.get("sha256")
                or candidate_item.get("size_px") != source_record.get("size_px")):
            raise Invalid("final sampling source disagrees with current candidate: " + item.get("card_id", ""))
        source = inside(root, path_rel)
        if not source.is_file():
            raise Invalid("final sampling source missing: " + path_rel)
        if source_record.get("sha256") != sha(source):
            raise Invalid("final sampling source hash is stale: " + path_rel)
        if source_record.get("size_px") != [1024, 1536]:
            raise Invalid("final sampling source record is not native 1024x1536: " + path_rel)
        if source_record.get("role") != "complete-native-card":
            raise Invalid("final sampling source is not a complete native card: " + path_rel)
        try:
            info = cardctl.image_info(source)
        except (OSError, cardctl.DataError) as exc:
            raise Invalid("final sampling source is unreadable: " + path_rel + ": " + str(exc)) from exc
        if info["format"] != "PNG" or [info["width"], info["height"]] != [1024, 1536]:
            raise Invalid("final sampling source must be a native PNG: " + path_rel)

        approval = item.get("user_visual_approval", {})
        status = approval.get("status")
        if status not in {"pending", "approved"}:
            raise Invalid("final sampling approval status is invalid: " + item["card_id"])
        if status == "approved":
            if not (str(approval.get("by") or "").strip()
                    and str(approval.get("reference") or "").strip()):
                raise Invalid("approved final sampling needs approval evidence: " + item["card_id"])
        approval_statuses[item["card_id"]] = status

    if manifest.get("sampling_executed") is not False:
        raise Invalid("final sampling must not report executed sampling before a receipt exists")
    if manifest.get("status") == "approved-for-final-sampling" and set(approval_statuses.values()) != {"approved"}:
        raise Invalid("approved final sampling requires every card to be user-approved")

    return {
        "passed": True,
        "status": "passed",
        "manifest": manifest_rel,
        "manifest_status": manifest.get("status"),
        "sampling_executed": manifest.get("sampling_executed"),
        "card_count": len(cards),
        "candidate_manifest": candidate_ref["path"],
        "approval_statuses": approval_statuses,
        "allowed_profiles": FINAL_SAMPLING_PROFILES,
        "intermediate_2k_count": 0,
    }


def validate_final_sample(root, receipt_rel):
    """Verify a final receipt proves one direct native-to-target transform."""
    root = Path(root).resolve()
    receipt_path = inside(root, receipt_rel)
    receipt = read(receipt_path)
    if receipt.get("schema_version") != "1.0.0" or receipt.get("kind") != "final-card-sample":
        raise Invalid("final sample receipt schema is invalid")
    profile = receipt.get("profile")
    if profile not in FINAL_SAMPLING_PROFILES:
        raise Invalid("final sample profile is invalid")
    manifest_record = receipt.get("manifest", {})
    manifest_rel = manifest_record.get("path", "")
    manifest_path = inside(root, manifest_rel)
    if (not manifest_path.is_file()
            or sha(manifest_path) != manifest_record.get("sha256")):
        raise Invalid("final sample manifest hash is stale")
    manifest = read(manifest_path)
    validate_fool_finalization_manifest(root, manifest_rel)
    card_id = receipt.get("card_id", "")
    manifest_card = _finalization_card(manifest, card_id)
    if manifest_card.get("user_visual_approval") != receipt.get("user_visual_approval"):
        raise Invalid("final sample receipt approval disagrees with manifest")
    source_record = receipt.get("source_native", {})
    source = inside(root, source_record.get("path", ""))
    if not source.is_file() or sha(source) != source_record.get("sha256"):
        raise Invalid("final sample source hash is stale")
    if (manifest_card.get("source_native", {}).get("path") != source_record.get("path")
            or manifest_card.get("source_native", {}).get("sha256") != source_record.get("sha256")):
        raise Invalid("final sample source disagrees with manifest")
    if source_record.get("size_px") != [1024, 1536] or source_record.get("role") != "complete-native-card":
        raise Invalid("final sample source is not a complete native card")
    source_info = cardctl.image_info(source)
    if source_info["format"] != "PNG" or [source_info["width"], source_info["height"]] != [1024, 1536]:
        raise Invalid("final sample source must remain native 1024x1536")

    final_record = receipt.get("final", {})
    final = inside(root, final_record.get("path", ""))
    if not final.is_file() or sha(final) != final_record.get("sha256"):
        raise Invalid("final sample output hash is stale")
    expected_size = FINAL_SAMPLING_PROFILES[profile]["size_px"]
    if final_record.get("size_px") != expected_size:
        raise Invalid("final sample output record has wrong size")
    final_info = cardctl.image_info(final)
    if final_info["format"] != "PNG" or [final_info["width"], final_info["height"]] != expected_size:
        raise Invalid("final sample output has wrong dimensions")
    if "sRGB" not in final_info.get("color_tags", []):
        raise Invalid("final sample output must carry an sRGB profile")
    recorded_color_tags = final_record.get("color_tags", [])
    if "sRGB" not in recorded_color_tags:
        raise Invalid("final sample receipt is missing the sRGB profile record")

    processing = receipt.get("processing", {})
    if (processing.get("operation") != "single-full-canvas-resample"
            or processing.get("source_size_px") != [1024, 1536]
            or processing.get("target_size_px") != expected_size
            or processing.get("crop_count_before_final") != 0
            or processing.get("intermediate_2k_count") != 0
            or processing.get("final_resample_count") != 1):
        raise Invalid("final sample processing chain is not a single direct native transform")
    approval = receipt.get("user_visual_approval", {})
    if (approval.get("status") != "approved"
            or not str(approval.get("by") or "").strip()
            or not str(approval.get("reference") or "").strip()):
        raise Invalid("final sample receipt lacks user visual approval")
    if receipt.get("formal_release_approved") is not False:
        raise Invalid("final sample cannot claim formal release")
    return {
        "passed": True,
        "status": "passed",
        "receipt": receipt_rel,
        "card_id": receipt.get("card_id"),
        "profile": profile,
        "source_native_size": [1024, 1536],
        "final_size": expected_size,
        "intermediate_2k_count": 0,
        "final_resample_count": 1,
        "formal_release_approved": False,
    }


def finalize_fool_card(root, manifest_rel, card_id, profile, out_rel):
    """Sample one approved complete native Fool card exactly once."""
    root = Path(root).resolve()
    if profile not in FINAL_SAMPLING_PROFILES:
        raise Invalid("unsupported final sampling profile: " + str(profile))
    manifest_report = validate_fool_finalization_manifest(root, manifest_rel)
    manifest = read(inside(root, manifest_rel))
    item = _finalization_card(manifest, card_id)
    approval = item.get("user_visual_approval", {})
    if approval.get("status") != "approved":
        raise Invalid("final sampling requires user visual approval")
    policy = manifest["policy"]
    expected_size = policy["allowed_profiles"][profile]["size_px"]
    if expected_size != FINAL_SAMPLING_PROFILES[profile]["size_px"]:
        raise Invalid("final sampling profile differs from canonical policy")

    source_record = item["source_native"]
    source = inside(root, source_record["path"])
    sampler = shutil.which("sips")
    if not sampler:
        raise Invalid("final sampling requires macOS sips")
    out = new_output(root, out_rel, "artifacts/production")
    out.mkdir(parents=True)
    final_path = out / "final.png"
    try:
        subprocess.run([
            sampler, "-z", str(expected_size[1]), str(expected_size[0]),
            str(source), "--out", str(final_path)
        ], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    except subprocess.CalledProcessError as exc:
        detail = (exc.stderr or exc.stdout or "").strip()
        raise Invalid("final sampler failed" + (": " + detail if detail else "")) from exc
    if not final_path.is_file():
        raise Invalid("final sampler did not produce final.png")
    final_info = cardctl.image_info(final_path)

    receipt_rel = (out / "receipt.json").relative_to(root).as_posix()
    receipt = {
        "schema_version": "1.0.0",
        "kind": "final-card-sample",
        "card_id": card_id,
        "profile": profile,
        "manifest": {"path": manifest_rel, "sha256": sha(inside(root, manifest_rel))},
        "source_native": {
            **record(root, source),
            "size_px": [1024, 1536],
            "role": "complete-native-card",
        },
        "final": {
            **record(root, final_path),
            "size_px": expected_size,
            "color_tags": final_info.get("color_tags", []),
        },
        "processing": {
            "operation": "single-full-canvas-resample",
            "tool": "sips",
            "source_size_px": [1024, 1536],
            "target_size_px": expected_size,
            "crop_count_before_final": 0,
            "intermediate_2k_count": 0,
            "final_resample_count": 1,
        },
        "user_visual_approval": approval,
        "formal_release_approved": False,
    }
    write(out / "receipt.json", receipt)
    result = validate_final_sample(root, receipt_rel)
    result["manifest_status"] = manifest.get("status")
    result["manifest_card_count"] = manifest_report["card_count"]
    return result


def narrative_digest(pack, entry):
    """Bind exact text AND identity, attribution, evidence and spoiler boundary."""
    payload = {"identity": pack["identity"], "entry": {
        k: v for k, v in entry.items() if k not in {"contentDigest", "review"}}}
    return hashlib.sha256(json.dumps(payload, ensure_ascii=False, sort_keys=True,
                                    separators=(",", ":"), allow_nan=False).encode("utf-8")).hexdigest()


def validate_narrative(root, pack, ready_for_audio=False):
    validate_schema(pack, schema(root, "card-narrative"))
    entries = pack["entries"]
    if len({e["id"] for e in entries}) != len(entries):
        raise Invalid("duplicate narrative entry id")
    if {e["kind"] for e in entries} != {"greeting", "catchphrase", "story"}:
        raise Invalid("narrative requires greeting, catchphrase and story, or explicit draft gaps")
    for entry in entries:
        verify_records(root, entry["evidenceRefs"])
        if entry["kind"] == "story" and not (entry["title"] or "").strip():
            raise Invalid("story requires a chapter title")
        if not entry["text"].strip() and not (entry["gap"] or "").strip():
            raise Invalid("empty narrative requires an explicit gap")
        if entry["text"].strip() and entry["sourceKind"] != "original" and not entry["evidenceRefs"]:
            raise Invalid("canon/interpretation text requires located evidence")
        digest = narrative_digest(pack, entry)
        if entry["contentDigest"] is not None and entry["contentDigest"] != digest:
            raise Invalid("narrative content digest is stale: " + entry["id"])
        review = entry["review"]
        if review["status"] == "approved":
            if (not entry["text"].strip() or entry["gap"] is not None
                    or entry["contentDigest"] != digest or review["approvedDigest"] != digest
                    or not (review["by"] or "").strip() or not (review["reference"] or "").strip()):
                raise Invalid("narrative approval lacks current text/digest/evidence: " + entry["id"])
        elif ready_for_audio:
            raise Invalid("unapproved narrative cannot enter audio production: " + entry["id"])
    return pack


def task_dependencies(root, task):
    """Non-image contracts are tracked separately from actual image attachments."""
    deps = [record(root, root / rel) for rel in (
        "tools/production.py", "production/schemas/task.schema.json",
        "docs/production-sop-v3.md", "docs/pathway-carrier-sop.md",
        "docs/card-narrative-contract.md", "config/quality-color-tokens.json",
        "config/sequence-hierarchy.json", f".agents/skills/lotm-{task['kind']}/SKILL.md")]
    deps.extend(task["references"])
    deps.extend(task.get("contracts", []))
    if "narrative" in task:
        deps.append(task["narrative"])
        deps.append(record(root, root / "production/schemas/card-narrative.schema.json"))
        pack = read(inside(root, task["narrative"]["path"]))
        for entry in pack["entries"]:
            deps.extend(entry["evidenceRefs"])
    if task["kind"] == "subject":
        deps.append(record(root, inside(root, task["spec"]["semantic_source"])))
        deps.extend(task["spec"]["protagonist"]["evidence_refs"])
    return deps


def validate_task(root, task):
    validate_schema(task, schema(root, "task"))
    needed = {"foundation": "material", "subject": "slot_id"}
    if task["kind"] == "hierarchy":
        if "tier" not in task["spec"] and "stage" not in task["spec"]:
            raise Invalid("hierarchy task needs tier or stage")
        if task["spec"].get("stage") not in {None, "mother", "tiers", "sequences"}:
            raise Invalid("unknown hierarchy stage")
    elif needed[task["kind"]] not in task["spec"]:
        raise Invalid("kind and spec disagree")
    if task["kind"] == "hierarchy":
        for region in task["spec"]["clear_regions"]:
            validate_rect(region)
    verify_records(root, task["references"])
    verify_records(root, task.get("contracts", []))
    if "quality" in task:
        quality = task["quality"]
        if visual_quality(root, quality["sequence"])["id"] != quality["visual_tier"]:
            raise Invalid("visual quality differs from configured sequence mapping")
        if task["kind"] == "hierarchy" and task["spec"].get("tier") is not None and task["spec"]["tier"] != quality["visual_tier"]:
            raise Invalid("hierarchy tier differs from visual quality")
    elif task["kind"] == "hierarchy" and task["spec"].get("tier") in {"saint", "angel"}:
        raise Invalid("five-tier hierarchy requires explicit quality input")
    if "narrative" in task:
        if task["kind"] != "subject":
            raise Invalid("narrative belongs to a subject task")
        verify_records(root, [task["narrative"]])
        pack = validate_narrative(root, read(inside(root, task["narrative"]["path"])))
        identity, spec = pack["identity"], task["spec"]
        if (identity["cardID"], identity["slotID"], identity["characterID"], identity["name"]) != (
                spec["card_id"], spec["slot_id"], spec["character_id"], spec["protagonist"]["name_zh"]):
            raise Invalid("narrative and subject identity disagree")
    if task["kind"] == "subject":
        spec = task["spec"]
        protagonist = spec["protagonist"]
        if protagonist["kind"] == "character" and not spec["character_id"]:
            raise Invalid("named character requires stable character_id")
        if protagonist["kind"] == "archetype" and spec["character_id"] is not None:
            raise Invalid("archetype must not impersonate a named character")
        verify_records(root, protagonist["evidence_refs"])
        if protagonist["kind"] == "character" and task["mode"] == "production":
            if protagonist["name_status"] != "verified" or not protagonist["evidence_refs"]:
                raise Invalid("production protagonist name needs verified evidence")
        source = read(inside(root, spec["semantic_source"]))
        if source["card_id"] != spec["slot_id"]:
            raise Invalid("slot and semantic source disagree")
        if "quality" in task and task["quality"]["sequence"] != source["sequence"]:
            raise Invalid("quality and subject sequence disagree")
        if task["mode"] == "production":
            report = cardctl.check_repository(root, "design", spec["slot_id"])
            if not report["passed"]:
                raise Invalid("design gate failed: " + str([e["code"] for e in report["errors"]]))


def compile_task(root, task_rel, out_rel):
    task_path = inside(root, task_rel)
    task = read(task_path)
    validate_task(root, task)
    out = new_output(root, out_rel, "generated/production")
    deps = [record(root, task_path)] + task_dependencies(root, task)
    fingerprint = None
    if task["kind"] == "subject":
        source = inside(root, task["spec"]["semantic_source"])
        fingerprint = cardctl.design_fingerprint(root, source)
    prompt = task["prompt"]
    out.mkdir(parents=True)
    write(out / "task.json", task)
    (out / "prompt.txt").write_text(prompt + "\n", encoding="utf-8")
    write(out / "snapshot.json", {"dependencies": deps, "design_fingerprint": fingerprint,
          "task_sha256": sha(out / "task.json"), "prompt_sha256": sha(out / "prompt.txt")})
    return out


def check_snapshot(root, directory):
    snap = read(directory / "snapshot.json")
    task = read(directory / "task.json")
    verify_records(root, snap["dependencies"])
    if sha(directory / "task.json") != snap["task_sha256"] or sha(directory / "prompt.txt") != snap["prompt_sha256"]:
        raise Invalid("compiled task/prompt changed")
    validate_task(root, task)
    recorded = {(d["path"], d["sha256"]) for d in snap["dependencies"]}
    required = {(d["path"], d["sha256"]) for d in task_dependencies(root, task)}
    if not required <= recorded:
        raise Invalid("compiled snapshot omits required current contract dependencies")
    if task["kind"] == "subject":
        if cardctl.design_fingerprint(root, inside(root, task["spec"]["semantic_source"])) != snap["design_fingerprint"]:
            raise Invalid("semantic design dependencies changed")
    return task, snap


def ingest(root, compiled_rel, raw_path, call_rel, run):
    compiled = inside(root, compiled_rel)
    task, snap = check_snapshot(root, compiled)
    call = read(inside(root, call_rel))
    validate_schema(call, schema(root, "call"))
    if call["attachments"] != task["references"]:
        raise Invalid("actual attachment ledger must match declared references and roles")
    if call["prompt"] != task["prompt"]:
        raise Invalid("actual prompt differs from compiled task")
    if not cardctl.valid_date(call["created_at"]):
        raise Invalid("invalid generation date")
    if call["attempt"] > task["limits"]["max_attempts"]:
        raise Invalid("attempt limit exceeded")
    prior = root / "artifacts/production" / task["task_id"]
    if not re.fullmatch(r"[a-zA-Z0-9-]+", run):
        raise Invalid("invalid run id")
    raw = Path(raw_path).resolve(strict=True)
    raw_digest = sha(raw)
    reused_run = None
    for previous_path in prior.glob("*/receipt.json"):
        previous = read(previous_path)
        if previous["call"]["attempt"] == call["attempt"]:
            if previous["raw"]["sha256"] != raw_digest or previous["call"] != call:
                raise Invalid("attempt already registered for different output/call")
            reused_run = previous_path.relative_to(root).as_posix()
    info = cardctl.image_info(raw)
    if info["format"] != "PNG":
        raise Invalid("ingest currently requires PNG")
    a, b = task["output"]["aspect"]
    info["requested_aspect"] = [a, b]
    info["aspect_matches"] = abs(info["width"] / info["height"] - a / b) <= .04 * a / b
    out = new_output(root, f"artifacts/production/{task['task_id']}/{run}", "artifacts/production")
    out.mkdir(parents=True)
    shutil.copy2(raw, out / "raw.png")
    shutil.copy2(compiled / "prompt.txt", out / "prompt.txt")
    write(out / "task.json", task)
    write(out / "call.json", call)
    write(out / "snapshot.json", snap)
    receipt = {"schema_version": "1.0.0", "kind": task["kind"], "mode": task["mode"],
               "task_id": task["task_id"], "run_id": run, "task": task,
               "compiled": out.relative_to(root).as_posix(), "snapshot": snap,
               "reused_run": reused_run,
               "raw": record(root, out / "raw.png"), "raw_info": info, "call": call,
               "approval": {"status": "pending", "by": None, "reference": None},
               "rights_status": "unknown", "rights_reference": None,
               "created_at": datetime.now(timezone.utc).isoformat()}
    write(out / "receipt.json", receipt)
    return out


def check_asset(root, rel):
    receipt = read(inside(root, rel))
    verify_records(root, [receipt["raw"]])
    task, snap = check_snapshot(root, inside(root, receipt["compiled"]))
    if receipt["task"] != task or receipt["snapshot"] != snap:
        raise Invalid("asset and compiled snapshot disagree")
    if receipt["mode"] != task["mode"] or receipt["kind"] != task["kind"]:
        raise Invalid("asset kind/mode mismatch")
    validate_schema(receipt["call"], schema(root, "call"))
    if receipt["call"]["attachments"] != task["references"]:
        raise Invalid("asset attachment mismatch")
    if receipt["call"]["prompt"] != task["prompt"]:
        raise Invalid("asset prompt mismatch")
    return receipt


def validate_rect(rect):
    if len(rect) != 4 or any(type(v) not in (float, int) or not math.isfinite(v) for v in rect):
        raise Invalid("invalid rectangle")
    x, y, w, h = rect
    if min(x, y) < 0 or min(w, h) <= 0 or x+w > 1000 or y+h > 1500:
        raise Invalid("rectangle outside 1000x1500 canvas")


def validate_shape(shape):
    validate_rect(shape["rect"])
    if shape["kind"] not in ("rect", "ellipse", "path", "text"):
        raise Invalid("unsupported vector kind")
    for key in ("fill", "stroke"):
        if key in shape and not re.fullmatch(r"#[0-9a-fA-F]{6}|none", shape[key]):
            raise Invalid("invalid color")
    if shape["kind"] == "text":
        if not shape.get("text", "").strip() or not shape.get("font") or not 1 <= shape.get("size", 0) <= 300:
            raise Invalid("text requires text/font/size")
    if shape["kind"] == "path":
        cmds = shape.get("commands", [])
        if not cmds or not cmds[0] or cmds[0][0] != "M":
            raise Invalid("path must begin with M")
        for c in cmds:
            if not c or c[0] not in {"M", "L", "C", "Z"} or len(c) != {"M":3,"L":3,"C":7,"Z":1}[c[0]]:
                raise Invalid("unsupported path command")
            if any(type(v) not in (int, float) or not math.isfinite(v) for v in c[1:]):
                raise Invalid("invalid path coordinate")
            if any(v < 0 or v > (1000 if i % 2 == 0 else 1500) for i, v in enumerate(c[1:])):
                raise Invalid("path outside canvas")


def vector_svg(shapes):
    parts = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1500">']
    for s in shapes:
        x,y,w,h = s["rect"]
        style = f'fill="{s.get("fill","none")}" stroke="{s.get("stroke","none")}" stroke-width="{s.get("line_width",1)}"'
        if s["kind"] == "rect":
            parts.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" {style}/>')
        elif s["kind"] == "ellipse":
            parts.append(f'<ellipse cx="{x+w/2}" cy="{y+h/2}" rx="{w/2}" ry="{h/2}" {style}/>')
        elif s["kind"] == "path":
            d = " ".join(" ".join(map(str,c)) for c in s["commands"])
            parts.append(f'<path d="{d}" {style}/>')
    parts.append("</svg>")
    return "\n".join(parts)


def nameplate_shape(subject, layout):
    if set(layout) != {"rect","font","size","fill","align"}:
        raise Invalid("nameplate takes layout only; text comes from protagonist identity")
    if layout["size"] < 32:
        raise Invalid("protagonist name must be a primary readable component")
    name = subject["protagonist"]["name_zh"]
    if not name.strip():
        raise Invalid("protagonist name missing")
    shape = {"kind":"text", **layout, "text":name}
    validate_shape(shape)
    return shape


def compose(root, manifest_rel, out_rel):
    manifest_path = inside(root, manifest_rel)
    manifest = read(manifest_path)
    validate_schema(manifest, schema(root, "composition"))
    verify_records(root, manifest["vector_assets"])
    source_card = read(cardctl.resolve_card(root, manifest["slot_id"]))
    hierarchy = read(root / read(root/"config/project.json")["sequence_hierarchy_path"])
    tier_code = next(row["tier_id"] for row in hierarchy["sequence_levels"]
                     if row["sequence"] == source_card["sequence"])
    expected_tier = {"low_sequence":"low","mid_sequence":"mid","high_sequence":"high","true_god":"true-god"}[tier_code]
    shapes = []
    mark_found = False
    tier_found = False
    deps = [record(root, manifest_path), record(root, root/"config/project.json"),
            record(root, root/"tools/production.py"), record(root, root/"tools/render/compose.swift"),
            record(root, root/"production/schemas/composition.schema.json")]
    for asset in manifest["vector_assets"]:
        vector = read(inside(root, asset["path"]))
        if "sequence" in vector:
            if vector["sequence"] != source_card["sequence"] or vector.get("pathway_id") != source_card["pathway_id"]:
                raise Invalid("vector mark identity differs from card slot")
            mark_found = True
        if "tier" in vector:
            if vector["tier"] != expected_tier:
                raise Invalid("vector tier differs from sequence hierarchy")
            tier_found = True
        if manifest["mode"] == "production" and vector.get("status") != "approved":
            raise Invalid("production vector asset unapproved")
        if manifest["mode"] == "production":
            approval = vector.get("approval", {})
            if not approval.get("by") or not approval.get("reference"):
                raise Invalid("production vector approval has no evidence")
        shapes.extend(vector["shapes"])
        deps.append(asset)
    shapes += manifest["shapes"]
    for s in shapes:
        validate_schema(s, schema(root,"composition")["properties"]["shapes"]["items"])
        validate_shape(s)
    layers = []
    subjects = []
    for layer in manifest["layers"]:
        validate_rect(layer["rect"])
        receipt = check_asset(root, layer["receipt"])
        deps.append(record(root, inside(root, layer["receipt"])))
        deps.append(receipt["raw"])
        if receipt["kind"] == "subject":
            subjects.append(receipt["task"]["spec"])
        if receipt["kind"] == "hierarchy" and receipt["task"]["spec"]["tier"] != expected_tier:
            raise Invalid("hierarchy raster asset tier mismatch")
        if manifest["mode"] == "production" and receipt["mode"] != "production":
            raise Invalid("production composition contains concept asset")
        layers.append({**layer, "path": str(inside(root, receipt["raw"]["path"]))})
    if len(subjects) != 1 or subjects[0]["card_id"] != manifest["card_id"] or subjects[0]["slot_id"] != manifest["slot_id"]:
        raise Invalid("composition requires one matching subject identity")
    if not mark_found or not tier_found:
        raise Invalid("composition requires matching composite mark and tier vectors")
    shapes.append(nameplate_shape(subjects[0], manifest["nameplate"]))
    if manifest["mode"] == "concept":
        shapes.append({"kind":"text","rect":[160,1448,680,24],"fill":"#bac1cc",
                       "text":"概念样卡 · 未经正式批准","font":"Songti SC","size":14,"align":"center"})
    cfg = read(root/"config/project.json")
    profile = cfg["delivery_profiles"][manifest["profile"]]
    request = {"width":profile["width"],"height":profile["height"],
               "background":manifest["background"],"layers":layers,"shapes":shapes}
    out = new_output(root, out_rel, "artifacts/production")
    binary_dir = inside(root,"generated/production/bin")
    binary_dir.mkdir(parents=True,exist_ok=True)
    source = root/"tools/render/compose.swift"
    binary = binary_dir/("compose-"+sha(source)[:16])
    if not binary.exists():
        subprocess.run(["swiftc","-O",str(source),"-o",str(binary)],check=True,timeout=180)
    out.mkdir(parents=True)
    write(out/"manifest.json",manifest)
    write(out/"request.json",request)
    (out/"vectors.svg").write_text(vector_svg(shapes),encoding="utf-8")
    try:
        subprocess.run([str(binary),str(out/"request.json"),str(out)],check=True,timeout=120)
        final = cardctl.image_info(out/"final.png")
        if (final["width"],final["height"]) != (profile["width"],profile["height"]):
            raise Invalid("renderer dimensions mismatch")
        receipt = {"mode":manifest["mode"],"manifest":record(root,out/"manifest.json"),
                   "dependencies":deps, "final":record(root,out/"final.png"),
                   "preview":record(root,out/"preview.png"),"image_info":final,
                   "created_at":datetime.now(timezone.utc).isoformat(),
                   "processing":["artwork resampling","target-size vectors","target-size text","sRGB composition"],
                   "declared_native":False,"renderer":read(out/"renderer.json")}
        receipt["output_records"] = [record(root,out/f) for f in
            ("request.json","vectors.svg","renderer.json")]
        review = read(root/"templates/review.json")
        source = cardctl.resolve_card(root,manifest["slot_id"])
        review.update(card_id=manifest["card_id"],
                      design_fingerprint=cardctl.design_fingerprint(root,source),
                      image_sha256=receipt["final"]["sha256"])
        write(out/"review.json",review)
        receipt["output_records"].append(record(root,out/"review.json"))
        write(out/"render-receipt.json",receipt)
    except Exception as exc:
        write(out/"failure.json",{"error":str(exc),"status":"failed"})
        raise
    return out


def require_release_mode(manifest):
    if manifest.get("mode") != "production":
        raise Invalid("concept cannot pass release")


def gate(root, directory_rel, release=False):
    out = inside(root, directory_rel)
    receipt = read(out/"render-receipt.json")
    verify_records(root, receipt["dependencies"]+[receipt["manifest"],receipt["final"],receipt["preview"]]+receipt["output_records"])
    manifest = read(out/"manifest.json")
    validate_schema(manifest,schema(root,"composition"))
    final = cardctl.image_info(inside(root,receipt["final"]["path"]))
    profile = read(root/"config/project.json")["delivery_profiles"][manifest["profile"]]
    if final["format"] != "PNG" or (final["width"],final["height"]) != (profile["width"],profile["height"]) or not final.get("color_tags"):
        raise Invalid("final format/size/color metadata invalid")
    raw_assets = []
    protagonist = None
    for layer in manifest["layers"]:
        asset = check_asset(root,layer["receipt"])
        raw_assets.append(asset["raw"])
        if asset["kind"] == "subject":
            protagonist = asset["task"]["spec"]
        if release:
            require_release_mode(asset)
            ap = asset["approval"]
            if ap.get("status") != "approved" or not ap.get("by") or not ap.get("reference"):
                raise Invalid("asset lacks human approval")
            if asset.get("rights_status") != "cleared" or not asset.get("rights_reference"):
                raise Invalid("asset rights not recorded")
    if protagonist is None:
        raise Invalid("protagonist missing")
    expected_nameplate = nameplate_shape(protagonist, manifest["nameplate"])
    request = read(out/"request.json")
    if expected_nameplate not in request["shapes"]:
        raise Invalid("protagonist nameplate missing from rendered request")
    if not any(entry.get("text") == expected_nameplate["text"] for entry in receipt["renderer"]["fonts"]):
        raise Invalid("protagonist name not typeset by renderer")
    if release:
        require_release_mode(manifest)
        source = cardctl.resolve_card(root,manifest["slot_id"])
        report = cardctl.check_repository(root,"design",manifest["slot_id"])
        if not report["passed"]:
            raise Invalid("canonical design gate failed: "+str([e["code"] for e in report["errors"]]))
        projected = copy.deepcopy(read(source))
        projected["card_id"] = manifest["card_id"]
        projected["delivery_profile"] = manifest["profile"]
        projected["production"] = {
            "stage":"approved", "artifact":receipt["final"],
            "generation":{"tool":{"name":"Agent Skills + native compositor","model":None},
                          "created_at":receipt["created_at"],"raw_assets":raw_assets,
                          "processing":[{"operation":"composite","description":"Layer manifest and native render receipt"}],
                          "declared_native":False},
            "review_file":(out/"review.json").relative_to(root).as_posix()}
        errors = []
        assets = {a["id"]:a for a in read(root/"references/manifest.json")["assets"]}
        cardctl.validate_release(root,source,projected,assets,errors,manifest["card_id"])
        if errors:
            raise Invalid("card release gate failed: "+str([e["code"] for e in errors]))
    return {"passed":True,"level":"release" if release else "composition",
            "mode":manifest["mode"],"image_info":receipt["image_info"],
            "limitation":"Checks integrity and records; visual/semantic approval remains separate."}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command",required=True)
    c=sub.add_parser("compile");c.add_argument("task");c.add_argument("--out",required=True)
    c=sub.add_parser("ingest");c.add_argument("compiled");c.add_argument("raw");c.add_argument("call");c.add_argument("--run",required=True)
    c=sub.add_parser("compose");c.add_argument("manifest");c.add_argument("--out",required=True)
    c=sub.add_parser("gate");c.add_argument("directory");c.add_argument("--release",action="store_true")
    c=sub.add_parser("finalize");c.add_argument("manifest");c.add_argument("--card-id",required=True);c.add_argument("--profile",choices=sorted(FINAL_SAMPLING_PROFILES),required=True);c.add_argument("--out",required=True)
    c=sub.add_parser("check-final-sample");c.add_argument("receipt")
    c=sub.add_parser("check-content");c.add_argument("path");c.add_argument("--ready-for-audio",action="store_true")
    sub.add_parser("check-fool-materials")
    sub.add_parser("check-fool-carrier")
    sub.add_parser("check-fool-audio")
    sub.add_parser("check-fool-cards")
    sub.add_parser("check-fool-nonsequence-cards")
    args=parser.parse_args()
    try:
        if args.command=="compile": result=compile_task(ROOT,args.task,args.out)
        elif args.command=="ingest": result=ingest(ROOT,args.compiled,args.raw,args.call,args.run)
        elif args.command=="compose": result=compose(ROOT,args.manifest,args.out)
        elif args.command=="check-content":
            pack = validate_narrative(ROOT, read(inside(ROOT, args.path)), args.ready_for_audio)
            result = {"passed": True, "level": "text-approval" if args.ready_for_audio else "content-structure",
                      "card_id": pack["identity"]["cardID"],
                      "pending": [e["id"] for e in pack["entries"] if e["review"]["status"] != "approved"],
                      "digests": {e["id"]: narrative_digest(pack, e) for e in pack["entries"]},
                      "limitation": "No factual certification, audio generation, voice authorization or App import performed."}
        elif args.command=="check-fool-materials":
            result = validate_fool_materials(ROOT)
        elif args.command=="check-fool-carrier":
            result = validate_fool_carrier_contract(ROOT)
        elif args.command=="check-fool-audio":
            result = validate_fool_audio_package(ROOT)
        elif args.command=="check-fool-cards":
            result = validate_fool_cards(ROOT)
        elif args.command=="check-fool-nonsequence-cards":
            result = validate_fool_nonsequence_card_approvals(ROOT)
        elif args.command=="finalize":
            result = finalize_fool_card(ROOT, args.manifest, args.card_id, args.profile, args.out)
        elif args.command=="check-final-sample":
            result = validate_final_sample(ROOT, args.receipt)
        else: result=gate(ROOT,args.directory,args.release)
        print(json.dumps(result if isinstance(result,dict) else {"output":str(result.relative_to(ROOT))},ensure_ascii=False,indent=2))
        return 0
    except (Invalid,cardctl.DataError,OSError,ValueError,KeyError,TypeError,subprocess.SubprocessError) as exc:
        print(json.dumps({"passed":False,"error":str(exc)},ensure_ascii=False),file=sys.stderr)
        return 2


if __name__=="__main__":
    raise SystemExit(main())
