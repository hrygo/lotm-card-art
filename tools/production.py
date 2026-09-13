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
import subprocess
import sys
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


def inside(root, rel):
    if not isinstance(rel, str) or not rel or Path(rel).is_absolute():
        raise Invalid("expected nonempty repository-relative path")
    path = (root / rel).resolve()
    if not path.is_relative_to(root.resolve()):
        raise Invalid("path escapes repository: " + rel)
    return path


def record(root, path):
    return {"path": path.resolve().relative_to(root.resolve()).as_posix(), "sha256": sha(path)}


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


def validate_task(root, task):
    validate_schema(task, schema(root, "task"))
    needed = {"foundation": "material", "hierarchy": "tier", "subject": "slot_id"}
    if needed[task["kind"]] not in task["spec"]:
        raise Invalid("kind and spec disagree")
    if task["kind"] == "hierarchy":
        for region in task["spec"]["clear_regions"]:
            validate_rect(region)
    verify_records(root, task["references"])
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
        if task["mode"] == "production":
            report = cardctl.check_repository(root, "design", spec["slot_id"])
            if not report["passed"]:
                raise Invalid("design gate failed: " + str([e["code"] for e in report["errors"]]))


def compile_task(root, task_rel, out_rel):
    task_path = inside(root, task_rel)
    task = read(task_path)
    validate_task(root, task)
    out = new_output(root, out_rel, "generated/production")
    deps = [record(root, task_path)]
    deps.extend(task["references"])
    deps += [record(root, root / rel) for rel in (
        "tools/production.py", "production/schemas/task.schema.json", "docs/production-sop.md",
        f".agents/skills/lotm-{task['kind']}/SKILL.md")]
    fingerprint = None
    if task["kind"] == "subject":
        source = inside(root, task["spec"]["semantic_source"])
        deps.append(record(root, source))
        deps.extend(task["spec"]["protagonist"]["evidence_refs"])
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
        write(out/"render-receipt.json",receipt)
        review = read(root/"templates/review.json")
        source = cardctl.resolve_card(root,manifest["slot_id"])
        review.update(card_id=manifest["card_id"],
                      design_fingerprint=cardctl.design_fingerprint(root,source),
                      image_sha256=receipt["final"]["sha256"])
        write(out/"review.json",review)
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
    args=parser.parse_args()
    try:
        if args.command=="compile": result=compile_task(ROOT,args.task,args.out)
        elif args.command=="ingest": result=ingest(ROOT,args.compiled,args.raw,args.call,args.run)
        elif args.command=="compose": result=compose(ROOT,args.manifest,args.out)
        else: result=gate(ROOT,args.directory,args.release)
        print(json.dumps(result if isinstance(result,dict) else {"output":str(result.relative_to(ROOT))},ensure_ascii=False,indent=2))
        return 0
    except (Invalid,cardctl.DataError,OSError,ValueError,KeyError,TypeError,subprocess.SubprocessError) as exc:
        print(json.dumps({"passed":False,"error":str(exc)},ensure_ascii=False),file=sys.stderr)
        return 2


if __name__=="__main__":
    raise SystemExit(main())
