#!/usr/bin/env python3
"""Strict, offline material-study compositor; never a formal release route."""
from __future__ import annotations

import argparse
import copy
import json
from pathlib import Path
import re
import subprocess
from typing import Any

import production as p

ROOT = p.ROOT


def keys(value: dict, required: set, optional: set = frozenset()) -> None:
    """Reject missing or misspelled boundary fields."""
    if not isinstance(value, dict) or required - value.keys() or value.keys() - required - optional:
        raise p.Invalid('missing/unknown material fields')


def numeric(value: Any, lo: float, hi: float) -> None:
    p.validate_schema(value, {'type': 'number', 'minimum': lo, 'maximum': hi})


def rect(value: Any, anchors: dict) -> list:
    if isinstance(value, str):
        if value not in anchors:
            raise p.Invalid('unknown anchor: ' + value)
        value = anchors[value]
    p.validate_schema(value, {'type': 'array', 'minItems': 4, 'maxItems': 4})
    p.validate_rect(value)
    return copy.deepcopy(value)


def shapes(value: Any, anchors: dict, root: Path) -> list:
    p.validate_schema(value, {'type': 'array', 'minItems': 1, 'maxItems': 200})
    result = copy.deepcopy(value)
    for shape in result:
        shape['rect'] = rect(shape.get('rect'), anchors)
        p.validate_schema(shape, p.schema(root, 'composition')['properties']['shapes']['items'])
        p.validate_shape(shape)
    return result


def reference(root: Path, ref: dict, deps: list) -> Any:
    keys(ref, {'path', 'sha256'})
    p.verify_records(root, [ref])
    deps.append(ref)
    return p.read(p.inside(root, ref['path']))


def compile_recipe(root: Path, recipe: dict) -> tuple[dict, list]:
    """Resolve immutable asset references and design anchors into renderer input."""
    root = root.resolve()
    keys(recipe, {'version', 'mode', 'id', 'profile', 'background', 'anchors', 'nodes'}, {'identity'})
    if recipe['version'] != '2.0.0' or recipe['mode'] != 'material-study':
        raise p.Invalid('v2 currently requires material-study')
    if not isinstance(recipe['id'], str) or not re.fullmatch(r'[a-z][a-z0-9-]*', recipe['id']):
        raise p.Invalid('invalid study id')
    if not isinstance(recipe['background'], str) or not re.fullmatch(r'#[a-fA-F0-9]{6}|none', recipe['background']):
        raise p.Invalid('invalid background')
    cfg = p.read(root / 'config/project.json')
    if recipe['profile'] not in cfg['delivery_profiles']:
        raise p.Invalid('invalid profile')
    profile = cfg['delivery_profiles'][recipe['profile']]
    deps = [p.record(root, root / path) for path in (
        'config/project.json', 'tools/materialctl.py', 'tools/production.py',
        'tools/render/materials.swift', 'production/schemas/composition.schema.json')]
    anchors = recipe['anchors']
    if not isinstance(anchors, dict):
        raise p.Invalid('anchors must be an object')
    for value in anchors.values():
        rect(value, {})
    p.validate_schema(recipe['nodes'], {'type': 'array', 'minItems': 1, 'maxItems': 100})
    nodes, ids = [], set()
    for original in recipe['nodes']:
        keys(original, {'id'}, {'receipt', 'vector', 'shapes', 'rect', 'fit', 'opacity',
              'blend', 'mask', 'feather', 'brightness', 'saturation', 'shadow'})
        node = copy.deepcopy(original)
        if not isinstance(node['id'], str) or not re.fullmatch(r'[a-z][a-z0-9-]*', node['id']):
            raise p.Invalid('invalid node id')
        if node['id'] in ids:
            raise p.Invalid('duplicate node id')
        ids.add(node['id'])
        if len({'receipt', 'vector', 'shapes'} & node.keys()) != 1:
            raise p.Invalid('node requires exactly one source')
        for key, default, lo, hi in [('opacity', 1, 0, 1), ('feather', 0, 0, 40),
                                     ('brightness', 0, -.5, .5), ('saturation', 1, 0, 2)]:
            numeric(node.get(key, default), lo, hi)
            node.setdefault(key, default)
        if node.get('blend', 'normal') not in ('normal', 'multiply', 'screen', 'soft-light'):
            raise p.Invalid('invalid blend')
        node.setdefault('blend', 'normal')
        if 'shadow' in node:
            keys(node['shadow'], {'x', 'y', 'blur', 'opacity'})
            for key, lo, hi in [('x', -30, 30), ('y', -30, 30), ('blur', 0, 40), ('opacity', 0, 1)]:
                numeric(node['shadow'][key], lo, hi)
        if 'receipt' in node:
            receipt = p.check_asset(root, node['receipt'])
            deps += [p.record(root, p.inside(root, node['receipt'])), receipt['raw']]
            node['path'] = p.inside(root, receipt['raw']['path']).relative_to(root).as_posix()
            node['rect'] = rect(node.get('rect'), anchors)
            if node.get('fit', 'cover') not in ('cover', 'contain'):
                raise p.Invalid('invalid fit')
            node.setdefault('fit', 'cover')
            del node['receipt']
        else:
            if 'rect' in node or 'fit' in node:
                raise p.Invalid('vector node does not take raster geometry')
            if 'vector' in node:
                vector = reference(root, node.pop('vector'), deps)
                node['shapes'] = vector['shapes']
            node['shapes'] = shapes(node['shapes'], anchors, root)
        if 'mask' in node:
            mask = reference(root, node['mask'], deps)
            keys(mask, {'id', 'version', 'status', 'scope', 'shapes'})
            node['mask'] = shapes(mask['shapes'], anchors, root)
            if any(s['kind'] == 'text' for s in node['mask']):
                raise p.Invalid('mask cannot contain text')
        elif node['feather']:
            raise p.Invalid('feather requires explicit mask')
        nodes.append(node)
    # Diagnostic label and core identity are protected from subsequent materials.
    nodes.append({'id': '__study', 'shapes': [{'kind': 'text', 'rect': [100, 1460, 800, 28],
        'text': '物料试装 · 非正式卡牌', 'font': 'Songti SC', 'size': 16,
        'fill': '#909ba8', 'align': 'center'}]})
    if 'identity' in recipe:
        identity = recipe['identity']
        keys(identity, {'layout'}, {'subject_receipt', 'test_name'})
        if len({'subject_receipt', 'test_name'} & identity.keys()) != 1:
            raise p.Invalid('identity requires one authoritative source')
        if 'subject_receipt' in identity:
            asset = p.check_asset(root, identity['subject_receipt'])
            if asset['kind'] != 'subject':
                raise p.Invalid('identity requires subject asset')
            deps.append(p.record(root, p.inside(root, identity['subject_receipt'])))
            subject = asset['task']['spec']
        else:
            if not isinstance(identity['test_name'], str):
                raise p.Invalid('test_name requires text')
            subject = {'protagonist': {'name_zh': identity['test_name']}}
        layout = copy.deepcopy(identity['layout'])
        layout['rect'] = rect(layout.get('rect'), anchors)
        nodes.append({'id': '__identity', 'shapes': [p.nameplate_shape(subject, layout)]})
    return {'width': profile['width'], 'height': profile['height'],
            'background': recipe['background'], 'nodes': nodes}, deps


def render(root: Path, recipe_rel: str, out_rel: str) -> Path:
    """Validate, render and bind every artifact without overwriting past runs."""
    root = root.resolve()
    path = p.inside(root, recipe_rel)
    recipe = p.read(path)
    request, deps = compile_recipe(root, recipe)
    deps.append(p.record(root, path))
    out = p.new_output(root, out_rel, 'artifacts/production')
    binary_dir = p.inside(root, 'generated/production/bin')
    binary_dir.mkdir(parents=True, exist_ok=True)
    source = root / 'tools/render/materials.swift'
    binary = binary_dir / ('materials-' + p.sha(source)[:16])
    if not binary.exists():
        subprocess.run(['swiftc', str(source), '-o', str(binary)], check=True, timeout=180)
    out.mkdir(parents=True)
    try:
        p.write(out / 'request.json', request)
        p.write(out / 'recipe.json', recipe)
        subprocess.run([str(binary), str(out / 'request.json'), str(out)], check=True, timeout=180, cwd=root)
        files = ['request.json', 'recipe.json', 'final.png', 'preview.png', 'renderer.json']
        p.write(out / 'receipt.json', {'version': '2.0.0', 'mode': 'material-study',
            'dependencies': deps, 'outputs': [p.record(root, out / f) for f in files],
            'declared_native': False, 'approval': 'pending'})
    except Exception as exc:
        p.write(out / 'failure.json', {'error': str(exc)})
        raise
    return out


def gate(root: Path, out_rel: str, release: bool = False) -> dict:
    """Check current inputs and actual render output; deliberately deny release."""
    root = root.resolve()
    if release:
        raise p.Invalid('material-study cannot pass release')
    out = p.inside(root, out_rel)
    receipt = p.read(out / 'receipt.json')
    if receipt.get('mode') != 'material-study':
        raise p.Invalid('invalid receipt mode')
    p.verify_records(root, receipt['dependencies'] + receipt['outputs'])
    expected = {str((out / name).relative_to(root)) for name in
                ['request.json', 'recipe.json', 'final.png', 'preview.png', 'renderer.json']}
    if {r['path'] for r in receipt['outputs']} != expected:
        raise p.Invalid('incomplete output binding')
    request, _ = compile_recipe(root, p.read(out / 'recipe.json'))
    if request != p.read(out / 'request.json'):
        raise p.Invalid('resolved request mismatch')
    info = p.cardctl.image_info(out / 'final.png')
    if (info['width'], info['height']) != (request['width'], request['height']) or 'sRGB' not in info['color_tags']:
        raise p.Invalid('invalid size/color')
    preview = p.cardctl.image_info(out / 'preview.png')
    if (preview['width'], preview['height']) != (360, 540):
        raise p.Invalid('invalid preview size')
    metadata = p.read(out / 'renderer.json')
    texts = [s['text'] for n in request['nodes'] for s in n.get('shapes', []) if s['kind'] == 'text']
    if texts != [f['text'] for f in metadata['fonts']]:
        raise p.Invalid('text render ledger mismatch')
    return {'passed': True, 'level': 'material-composition', 'mode': 'material-study',
            'image_info': info, 'visual_approval': 'pending', 'declared_native': False}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    run = sub.add_parser('render'); run.add_argument('recipe'); run.add_argument('--out', required=True)
    check = sub.add_parser('gate'); check.add_argument('directory'); check.add_argument('--release', action='store_true')
    args = parser.parse_args()
    try:
        result = ({'output': str(render(ROOT, args.recipe, args.out).relative_to(ROOT))}
                  if args.command == 'render' else gate(ROOT, args.directory, args.release))
        print(json.dumps(result, ensure_ascii=False, indent=2))
    except (ValueError, KeyError, TypeError, OSError, subprocess.SubprocessError) as exc:
        print(json.dumps({'passed': False, 'error': str(exc)}, ensure_ascii=False))
        raise SystemExit(2)


if __name__ == '__main__':
    main()
