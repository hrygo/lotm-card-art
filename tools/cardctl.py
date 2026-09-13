#!/usr/bin/env python3
"""Model-neutral LOTM card workflow. Python 3.10+, standard library only.

This checks records, references and image container metadata. It does NOT certify
novel facts, artistic quality, human identity, or what the pixels communicate.
"""
from __future__ import annotations
import argparse
from collections import Counter
from datetime import datetime
import hashlib
import json
from pathlib import Path
import re
import struct
import sys
import zlib
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DIMS = ('identity', 'acting', 'abilities', 'potion', 'ascension', 'limitations')
DIM_LABELS = dict(zip(DIMS, ('身份', '扮演', '能力', '魔药', '晋升', '限制')))
PATH_IDS = ('fool', 'error', 'door', 'visionary', 'sun', 'tyrant', 'white-tower',
            'hanged-man', 'darkness', 'death', 'twilight-giant', 'demoness',
            'red-priest', 'hermit', 'paragon', 'wheel-of-fortune', 'mother',
            'moon', 'black-emperor', 'justiciar', 'chained', 'abyss')
CHANNELS = ('text', 'emblem', 'object', 'action', 'composition', 'material',
            'lighting', 'border', 'negative_space', 'state_change')
STATES = ('unresearched', 'supported', 'partial', 'documented_absence', 'not_applicable')
STAGES = ('scaffold', 'research', 'directed', 'rendered', 'reviewed', 'approved')
CHECK_NAMES = ('canon', 'six_dimensions', 'readability', 'art_direction', 'composition',
               'sequence_distinction', 'text', 'image_integrity', 'color', 'rights')
HEX64 = re.compile(r'^[a-f0-9]{64}$')

class DataError(ValueError):
    """A useful user-facing validation error rather than an unhandled traceback."""

def nonblank(value: Any) -> bool:
    return isinstance(value, str) and bool(value.strip())

def pairs_no_duplicates(pairs):
    data = {}
    for k, v in pairs:
        if k in data:
            raise DataError(f'JSON存在重复键: {k}')
        data[k] = v
    return data

def load_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding='utf-8'), object_pairs_hook=pairs_no_duplicates,
                          parse_constant=lambda x: (_ for _ in ()).throw(DataError(f'非法JSON常量: {x}')))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise DataError(f'无法读取JSON {path}: {exc}') from exc

def write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

def safe_path(root: Path, rel: str, *, must_exist: bool = True) -> Path:
    if not nonblank(rel) or Path(rel).is_absolute() or '..' in Path(rel).parts:
        raise DataError(f'路径必须是仓库内相对路径: {rel!r}')
    p = (root / rel).resolve()
    if not p.is_relative_to(root.resolve()):
        raise DataError(f'路径或符号链接越出仓库: {rel}')
    if must_exist and not p.is_file():
        raise DataError(f'文件不存在: {rel}')
    return p

def digest_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open('rb') as f:
        for block in iter(lambda: f.read(1024 * 1024), b''):
            h.update(block)
    return h.hexdigest()

def valid_date(value: Any) -> bool:
    if not nonblank(value):
        return False
    try:
        datetime.fromisoformat(value.replace('Z', '+00:00'))
        return True
    except ValueError:
        return False

def resolve_card(root: Path, selector: str) -> Path:
    m = re.fullmatch(r'([a-z][a-z-]*):([0-9]{1,2})', selector)
    if not m:
        m2 = re.fullmatch(r'lotm\.([a-z][a-z-]*)\.s([0-9]{2})', selector)
        if not m2:
            raise DataError('卡牌选择器应为 fool:09 或 lotm.fool.s09')
        slug, seq = m2.group(1), int(m2.group(2))
    else:
        slug, seq = m.group(1), int(m.group(2))
    if slug not in PATH_IDS or seq not in range(10):
        raise DataError(f'未知途径或序列: {selector}')
    return safe_path(root, f'pathways/{slug}/sequences/{seq:02d}/card.json')

def issue(errors: list[dict], code: str, where: str, message: str) -> None:
    errors.append({'code': code, 'where': where, 'message': message})

def require_keys(obj: Any, required: tuple | list, errors: list, where: str) -> bool:
    if not isinstance(obj, dict):
        issue(errors, 'object.type', where, '必须是对象')
        return False
    for key in required:
        if key not in obj:
            issue(errors, 'field.missing', where, f'缺少字段 {key}')
    return all(k in obj for k in required)

def context_paths(root: Path, card_path: Path, config: dict | None = None) -> list[Path]:
    config = config or load_json(root / 'config/project.json')
    slug = card_path.parent.parent.parent.name
    rels = ['AGENTS.md', 'pathways/AGENTS.md', f'pathways/{slug}/AGENTS.md',
            'config/project.json', 'catalog/pathways.json', 'sources/registry.json',
            'references/manifest.json', f'pathways/{slug}/direction.json',
            f'pathways/{slug}/canon.json'] + config['design_document_paths']
    return list(dict.fromkeys([safe_path(root, r) for r in rels] + [card_path]))

def design_fingerprint(root: Path, card_path: Path) -> str:
    """Ignores production bookkeeping but binds all design/rule/evidence inputs."""
    root = root.resolve()
    card_path = card_path.resolve()
    h = hashlib.sha256()
    for p in sorted(context_paths(root, card_path), key=lambda x: x.relative_to(root).as_posix()):
        rel = p.relative_to(root).as_posix()
        if p == card_path:
            c = load_json(p)
            c.pop('production', None)
            data = json.dumps(c, ensure_ascii=False, sort_keys=True, separators=(',', ':')).encode('utf-8')
        else:
            data = p.read_bytes()
        h.update(rel.encode('utf-8') + b'\0' + hashlib.sha256(data).digest())
    return h.hexdigest()

def image_info(path: Path) -> dict:
    """Validate PNG container/CRCs (not pixels), or read JPEG SOF dimensions.

    A successful result is NOT a visual or full raster-decoder integrity review.
    """
    with path.open('rb') as f:
        head = f.read(8)
        if head == b'\x89PNG\r\n\x1a\n':
            width = height = None
            idat = False
            ended = False
            tags = []
            chunks = 0
            while True:
                header = f.read(8)
                if not header:
                    break
                if len(header) != 8:
                    raise DataError('PNG块头损坏')
                length, kind = struct.unpack('>I4s', header)
                if length > 256 * 1024 * 1024:
                    raise DataError('PNG块异常过大')
                data = f.read(length)
                crc_bytes = f.read(4)
                if len(data) != length or len(crc_bytes) != 4:
                    raise DataError('PNG块被截断')
                expected = struct.unpack('>I', crc_bytes)[0]
                actual = zlib.crc32(data, zlib.crc32(kind)) & 0xffffffff
                if actual != expected:
                    raise DataError('PNG CRC不匹配')
                if chunks == 0 and kind != b'IHDR':
                    raise DataError('PNG首块不是IHDR')
                if kind == b'IHDR':
                    if width is not None or length != 13:
                        raise DataError('PNG IHDR重复或损坏')
                    width, height, depth, color, comp, filt, interlace = struct.unpack('>IIBBBBB', data)
                    if not width or not height or comp != 0 or filt != 0 or interlace not in (0, 1):
                        raise DataError('PNG IHDR参数非法')
                    valid_depths = {0:(1,2,4,8,16), 2:(8,16), 3:(1,2,4,8), 4:(8,16), 6:(8,16)}
                    if color not in valid_depths or depth not in valid_depths[color]:
                        raise DataError('PNG位深/色彩类型不合法')
                elif kind == b'IDAT':
                    idat = idat or length > 0
                elif kind in (b'sRGB', b'iCCP'):
                    tags.append(kind.decode('ascii'))
                elif kind == b'IEND':
                    if length != 0 or f.read(1):
                        raise DataError('PNG IEND损坏或存在尾随内容')
                    ended = True
                    break
                chunks += 1
            if not (width and height and idat and ended):
                raise DataError('PNG缺少图像数据或结尾')
            return {'format':'PNG', 'width':width, 'height':height, 'color_tags':tags,
                    'inspection':'container_crc_and_dimensions_only'}
        if head[:2] == b'\xff\xd8':
            f.seek(2)
            sof = {0xc0,0xc1,0xc2,0xc3,0xc5,0xc6,0xc7,0xc9,0xca,0xcb,0xcd,0xce,0xcf}
            while True:
                b = f.read(1)
                if not b:
                    break
                if b != b'\xff':
                    continue
                while b == b'\xff':
                    b = f.read(1)
                if not b:
                    break
                marker = b[0]
                if marker in (0xd9, 0xda):
                    break
                if marker in (0x01, 0xd8) or 0xd0 <= marker <= 0xd7:
                    continue
                size = f.read(2)
                if len(size) != 2:
                    break
                length = struct.unpack('>H', size)[0]
                if length < 2:
                    raise DataError('JPEG段长度非法')
                data = f.read(length - 2)
                if len(data) != length - 2:
                    raise DataError('JPEG被截断')
                if marker in sof and len(data) >= 6:
                    height, width = struct.unpack('>HH', data[1:5])
                    if width and height:
                        return {'format':'JPEG', 'width':width, 'height':height,
                                'inspection':'sof_dimensions_only'}
            raise DataError('JPEG没有可读取的尺寸')
    raise DataError('仅支持PNG最终图、PNG/JPEG原始图的尺寸检查')

def check_asset(root: Path, record: Any, errors: list, where: str) -> dict | None:
    if not require_keys(record, ('path', 'sha256'), errors, where):
        return None
    if not isinstance(record.get('sha256'), str) or not HEX64.fullmatch(record['sha256']):
        issue(errors, 'asset.hash_format', where, '需要小写64位SHA256')
    try:
        p = safe_path(root, record['path'])
        if digest_file(p) != record['sha256']:
            issue(errors, 'asset.hash_mismatch', where, '文件摘要与记录不一致')
        return image_info(p)
    except (DataError, OSError) as exc:
        issue(errors, 'asset.invalid', where, str(exc))
        return None

def _cached_canon(root: Path, slug: str, ctx: dict | None) -> Any:
    """Return the pathway canon, reusing the context cache when injected."""
    if ctx is None:
        return load_json(root / f'pathways/{slug}/canon.json')
    canons = ctx.setdefault('canons', {})
    if slug not in canons:
        canons[slug] = load_json(root / f'pathways/{slug}/canon.json')
    return canons[slug]


def validate_card(root: Path, card_path: Path, level: str = 'scaffold', ctx: dict | None = None) -> list[dict]:
    root = root.resolve()
    card_path = card_path.resolve()
    errors: list[dict] = []
    where = card_path.relative_to(root).as_posix()
    c = load_json(card_path)
    fields = ('schema_version','card_id','pathway_id','sequence','name_zh','name_status','work_scope',
              'revision','delivery_profile','semantics','cues','composition','production')
    if not require_keys(c, fields, errors, where):
        return errors
    config = ctx['config'] if ctx else load_json(root / 'config/project.json')
    if c['schema_version'] != '0.3.0':
        issue(errors, 'version.invalid', where, '不支持的schema_version')
    slug, seq = c['pathway_id'], c['sequence']
    expected_slug = card_path.parent.parent.parent.name
    expected_seq = card_path.parent.name
    if slug not in PATH_IDS or type(seq) is not int or seq not in range(10):
        issue(errors, 'card.identity', where, '途径/序列字段非法')
        return errors
    if slug != expected_slug or f'{seq:02d}' != expected_seq or c['card_id'] != f'lotm.{slug}.s{seq:02d}':
        issue(errors, 'card.identity', where, 'ID、目录和序列不一致')
    if c['name_zh'] is not None and not nonblank(c['name_zh']):
        issue(errors, 'card.name_type', where, '名称必须为非空文本或null')
    if c['name_status'] not in ('unfilled','seed_unverified','verified'):
        issue(errors, 'card.name_status', where, '名称状态不合法')
    if type(c['revision']) is not int or c['revision'] < 1:
        issue(errors, 'card.revision', where, 'revision必须为正整数')
    if c['work_scope'] != config['work_scope']:
        issue(errors, 'card.work_scope', where, '作品范围与当前项目不一致')
    if c['delivery_profile'] not in config['delivery_profiles']:
        issue(errors, 'card.profile', where, '未知交付档位')
    sem = c['semantics']
    if not isinstance(sem, dict) or set(sem) != set(DIMS):
        issue(errors, 'semantics.six_required', where, '必须且只能有六个规定维度')
        return errors
    cue_map: dict[str, dict] = {}
    if not isinstance(c['cues'], list):
        issue(errors, 'cue.type', where, 'cues必须为数组')
        return errors
    for cue in c['cues']:
        if not require_keys(cue, ('id','channel','meaning','implementation','region','decode_mode','exact_text','legend_ref'), errors, where):
            continue
        cid = cue['id']
        if not nonblank(cid) or not re.fullmatch(r'[a-z][a-z0-9_-]*', cid):
            issue(errors, 'cue.id', where, 'cue ID必须为ASCII小写稳定ID')
            continue
        if cid in cue_map:
            issue(errors, 'cue.duplicate', where, f'重复cue {cid}')
        cue_map[cid] = cue
        if cue['channel'] not in CHANNELS:
            issue(errors, 'cue.channel', where, f'未知载体 {cue["channel"]}')
        if cue['decode_mode'] not in ('literal','conventional','project_legend','metaphoric'):
            issue(errors, 'cue.decode', where, f'未知解码方式 {cid}')
        region = cue['region']
        if (not isinstance(region, dict) or set(region) != {'x','y','w','h'} or
            any(type(v) not in (int,float) for v in region.values())):
            issue(errors, 'cue.region', where, f'位置格式错误 {cid}')
        elif (region['x'] < 0 or region['y'] < 0 or region['w'] <= 0 or region['h'] <= 0 or
              region['x'] + region['w'] > 1.000001 or region['y'] + region['h'] > 1.000001):
            issue(errors, 'cue.region', where, f'位置超出卡面 {cid}')
        if cue['channel'] == 'text' and not nonblank(cue['exact_text']):
            issue(errors, 'cue.exact_text', where, f'文字载体缺少精确文案 {cid}')
        if cue['channel'] != 'text' and cue['exact_text'] is not None:
            issue(errors, 'cue.text_channel', where, f'精确文字应单独作为text cue {cid}')
        if cue['decode_mode'] == 'project_legend':
            try:
                safe_path(root, cue['legend_ref'])
            except DataError as exc:
                issue(errors, 'cue.legend', where, str(exc))
    all_refs = []
    for d in DIMS:
        entry = sem[d]
        if not require_keys(entry, ('knowledge_state','intent','claim_refs','fidelity','carrier_ids','readback',
                                    'misreading_guard','gap_note','research_question'), errors, where+':'+d):
            continue
        if entry['knowledge_state'] not in STATES:
            issue(errors, 'semantics.state', where+':'+d, '未知知识状态')
        if entry['fidelity'] not in ('exact','summary','evocation'):
            issue(errors, 'semantics.fidelity', where+':'+d, '未知表达精度')
        if not isinstance(entry['claim_refs'], list) or not all(nonblank(x) for x in entry['claim_refs']):
            issue(errors, 'semantics.claim_refs', where+':'+d, 'claim_refs必须为文本数组')
        if not isinstance(entry['carrier_ids'], list) or not all(nonblank(x) for x in entry['carrier_ids']):
            issue(errors, 'semantics.carriers', where+':'+d, 'carrier_ids必须为文本数组')
            continue
        if len(set(entry['carrier_ids'])) != len(entry['carrier_ids']):
            issue(errors, 'semantics.duplicate_carrier', where+':'+d, '载体引用不能重复凑数')
        for cid in entry['carrier_ids']:
            if cid not in cue_map:
                issue(errors, 'cue.dangling', where+':'+d, f'找不到载体 {cid}')
        all_refs.extend(entry['carrier_ids'])
    # Reusing an event is allowed; claiming one generic cue explains all six is not.
    if all(isinstance(sem[d], dict) and sem[d].get('carrier_ids') for d in DIMS) and len(set(all_refs)) == 1:
        issue(errors, 'semantics.generic_all_six', where, '不得让同一笼统载体成为六维唯一解释')
    for cid in cue_map:
        if cid not in all_refs:
            issue(errors, 'cue.unassigned', where, f'cue未关联任何语义维度: {cid}；装饰请写composition而非假语义')
    comp = c['composition']
    if not require_keys(comp, ('layout','hero_event','why_this_sequence','focal_hierarchy','art_direction_note','reference_ids','exactness_note'), errors, where):
        return errors
    if comp['layout'] not in ('scene','icon','ritual','conceptual'):
        issue(errors, 'composition.layout', where, '未知构图家族')
    if not isinstance(comp['focal_hierarchy'], list) or not all(nonblank(x) for x in comp['focal_hierarchy']):
        issue(errors, 'composition.hierarchy', where, '视觉层级必须为文本数组')
    if not isinstance(comp['reference_ids'], list) or not all(nonblank(x) for x in comp['reference_ids']):
        issue(errors, 'composition.references', where, '参考ID必须为文本数组')
    prod = c['production']
    if not require_keys(prod, ('stage','artifact','generation','review_file'), errors, where):
        return errors
    if prod['stage'] not in STAGES:
        issue(errors, 'production.stage', where, '未知生产阶段')
    # Validate named claims and reference IDs even in scaffold mode.
    canon = _cached_canon(root, slug, ctx)
    claims = {cl['id']:cl for cl in canon.get('claims', []) if isinstance(cl,dict) and nonblank(cl.get('id'))}
    if len(claims) != len(canon.get('claims', [])):
        issue(errors, 'claim.duplicate_or_invalid', where, '断言ID重复或缺失')
    sources_registry = ctx['sources'] if ctx else load_json(root / 'sources/registry.json')
    sources_list = sources_registry.get('sources', [])
    sources = {x['id']:x for x in sources_list if isinstance(x,dict) and nonblank(x.get('id'))}
    if len(sources) != len(sources_list):
        issue(errors, 'source.duplicate_or_invalid', where, '来源ID重复或缺失')
    assets_manifest = ctx['assets'] if ctx else load_json(root / 'references/manifest.json')
    assets_list = assets_manifest.get('assets', [])
    assets = {x['id']:x for x in assets_list if isinstance(x,dict) and nonblank(x.get('id'))}
    if len(assets) != len(assets_list):
        issue(errors, 'reference.duplicate_or_invalid', where, '参考ID重复或缺失')
    for d in DIMS:
        for ref in sem[d].get('claim_refs', []) if isinstance(sem[d].get('claim_refs'),list) else []:
            if ref not in claims:
                issue(errors, 'claim.dangling', where+':'+d, f'断言不存在: {ref}')
    for ref in comp.get('reference_ids', []) if isinstance(comp.get('reference_ids'),list) else []:
        if ref not in assets:
            issue(errors, 'reference.dangling', where, f'参考图不存在: {ref}')
    wants_design = level in ('design','release') or prod['stage'] in ('directed','rendered','reviewed','approved')
    if not wants_design or errors:
        return errors
    validate_design(root, c, claims, sources, assets, errors, where, ctx)
    wants_release = level == 'release' or prod['stage'] == 'approved'
    if wants_release and not errors:
        validate_release(root, card_path, c, assets, errors, where, ctx)
    return errors


def validate_design(root, c, claims, sources, assets, errors, where, ctx=None):
    if not nonblank(c['name_zh']) or c['name_status'] != 'verified':
        issue(errors, 'design.name_unverified', where, '中文序列名尚未核验')
    if not nonblank(c['composition']['hero_event']) or not nonblank(c['composition']['why_this_sequence']):
        issue(errors, 'design.hero_event', where, '主事件与本序列不可替代性尚未设计')
    if not c['composition']['focal_hierarchy']:
        issue(errors, 'design.hierarchy', where, '缺少视觉层级')
    cue_map = {q['id']:q for q in c['cues']}
    for cue in cue_map.values():
        if not nonblank(cue['meaning']) or not nonblank(cue['implementation']):
            issue(errors, 'design.cue_incomplete', where, f'载体缺少意义或实施描述: {cue["id"]}')
    for d in DIMS:
        e = c['semantics'][d]
        loc = where+':'+d
        if e['knowledge_state'] == 'unresearched':
            issue(errors, 'design.unresearched', loc, '该维度尚未研究')
        if not e['claim_refs']:
            issue(errors, 'design.evidence_missing', loc, '事实或经确认缺口必须有断言引用')
        if not e['carrier_ids'] or not nonblank(e['intent']) or not nonblank(e['readback']) or not nonblank(e['misreading_guard']):
            issue(errors, 'design.translation_incomplete', loc, '缺少语义、载体、回读或误读边界')
        if e['knowledge_state'] in ('partial','documented_absence','not_applicable') and not nonblank(e['gap_note']):
            issue(errors, 'design.gap_scope', loc, '缺口/不适用需要明确范围与解释')
        valid_claims = [claims[x] for x in e['claim_refs'] if x in claims]
        if e['knowledge_state'] in ('documented_absence','not_applicable'):
            expected = 'absence' if e['knowledge_state']=='documented_absence' else 'not_applicable'
            if not any(cl.get('predicate') == expected for cl in valid_claims):
                issue(errors, 'design.unsupported_absence', loc, '缺少支持否定/未披露判断的专门断言')
        for cl in valid_claims:
            if not require_keys(cl, ('id','assertion_kind','predicate','value','dimensions','sequences','work_scope','source_refs','verification'), errors, loc):
                continue
            if cl['assertion_kind'] not in ('canon','interpretation','knowledge_gap'):
                issue(errors, 'design.assertion_kind', loc, '断言性质必须明确')
            if cl['assertion_kind']=='interpretation' and e['fidelity']=='exact':
                issue(errors, 'design.interpretation_exact', loc, '解释性内容不能冒作精确正典事实')
            if cl['assertion_kind']=='knowledge_gap' and cl['predicate'] not in ('absence','not_applicable'):
                issue(errors, 'design.gap_kind', loc, '知识缺口记录不能充当正面能力断言')
            if d not in cl['dimensions'] or c['sequence'] not in cl['sequences'] or cl['work_scope'] != c['work_scope']:
                issue(errors, 'design.claim_scope', loc, f'断言不适用当前维度/序列/作品: {cl["id"]}')
            verification = cl.get('verification', {})
            if not (verification.get('status')=='verified' and nonblank(verification.get('reviewed_by')) and valid_date(verification.get('reviewed_at'))):
                issue(errors, 'design.claim_unverified', loc, f'断言尚未核验: {cl["id"]}')
            if not nonblank(cl['value']) or not cl['source_refs']:
                issue(errors, 'design.claim_empty', loc, '断言内容或证据为空')
            has_matching_primary = False
            for sr in cl['source_refs']:
                if not isinstance(sr,dict) or sr.get('source_id') not in sources:
                    issue(errors, 'design.source_missing', loc, '断言引用的来源不存在')
                    continue
                source = sources[sr['source_id']]
                if not nonblank(sr.get('locator')) or not nonblank(sr.get('support_note')):
                    issue(errors, 'design.source_locator', loc, '缺少来源定位与支持说明')
                if source.get('retrieval_status') == 'inaccessible':
                    issue(errors, 'design.source_inaccessible', loc, '不可访问来源不能冒作已核验证据')
                if (source.get('kind') in ('primary_chinese','author_statement') and
                    source.get('work_scope') == c['work_scope'] and
                    source.get('retrieval_status') in ('accessible','partial')):
                    has_matching_primary = True
            if not has_matching_primary:
                issue(errors, 'design.primary_required', loc, '缺少当前中文作品范围的一手证据；二手/译本不自动替代')
        if e['fidelity'] == 'exact':
            precise = [cue_map[x] for x in e['carrier_ids'] if x in cue_map and
                       cue_map[x]['channel'] in ('text','emblem') and
                       cue_map[x]['decode_mode'] != 'metaphoric']
            if not precise:
                issue(errors, 'design.exact_carrier', loc, '精确信息需要无歧义文字/编码载体，不能只用氛围')
    identity_claims = [claims[x] for x in c['semantics']['identity']['claim_refs'] if x in claims]
    if not any(cl.get('predicate')=='sequence_name' and cl.get('value')==c['name_zh'] for cl in identity_claims):
        issue(errors, 'design.name_claim', where, '身份缺少与显示名称匹配的序列名断言')
    registry = (ctx['registry'] if ctx else load_json(root/'catalog/pathways.json'))['pathways']
    pathrow = next((x for x in registry if x['id']==c['pathway_id']), {})
    if not any(cl.get('predicate')=='pathway_name' and cl.get('value')==pathrow.get('working_name_zh') for cl in identity_claims):
        issue(errors, 'design.pathway_claim', where, '身份缺少与途径名称匹配的断言')
    if pathrow.get('label_status') != 'verified':
        issue(errors, 'design.pathway_label', where, '途径中文工作标签尚未核验')
    for ref in c['composition']['reference_ids']:
        asset = assets[ref]
        check_asset(root, asset, errors, where+':reference:'+ref)
        approval = asset.get('approval', {})
        if approval.get('status') == 'approved' and not (nonblank(approval.get('reference')) and nonblank(approval.get('by'))):
            issue(errors, 'reference.fake_approval', where, '参考图approved缺少真实批准记录字段')


def validate_release(root, card_path, c, assets, errors, where, ctx=None):
    prod = c['production']
    config = ctx['config'] if ctx else load_json(root/'config/project.json')
    final_info = check_asset(root, prod['artifact'], errors, where+':final')
    if final_info:
        profile = config['delivery_profiles'][c['delivery_profile']]
        if final_info['format'] != 'PNG' or (final_info['width'], final_info['height']) != (profile['width'],profile['height']):
            issue(errors, 'release.dimensions', where, '最终图的格式或真实像素不符合所选档位')
        if not final_info.get('color_tags'):
            issue(errors, 'release.color_metadata', where, '最终PNG缺少sRGB/iCCP元数据，仍需人工确认实际色彩空间')
    gen = prod['generation']
    if require_keys(gen, ('tool','created_at','raw_assets','processing','declared_native'), errors, where+':generation'):
        if not isinstance(gen['tool'],dict) or not nonblank(gen['tool'].get('name')) or not valid_date(gen['created_at']):
            issue(errors, 'release.generation', where, '缺少真实工具名称或生成时间')
        if not isinstance(gen['raw_assets'],list) or not gen['raw_assets']:
            issue(errors, 'release.raw_assets', where, '没有保留实际原始输出')
        else:
            raw_infos = [check_asset(root, r, errors, where+':raw') for r in gen['raw_assets']]
            if (final_info and any(raw_infos) and
                all(not r or (r['width'] < final_info['width'] or r['height'] < final_info['height']) for r in raw_infos) and
                not any(isinstance(p,dict) and p.get('operation') in ('resize','upscale','composite','layout')
                        for p in gen.get('processing',[]) if isinstance(gen.get('processing'),list))):
                issue(errors, 'release.unrecorded_resize', where, '最终图大于原始图，缺少尺寸变换/合成记录')
            if gen['declared_native']:
                if not final_info or not any(r and (r['width'],r['height']) == (final_info['width'],final_info['height']) for r in raw_infos):
                    issue(errors, 'release.false_native', where, '原始图尺寸不支持所宣称的最终原生尺寸')
        if type(gen['declared_native']) is not bool or not isinstance(gen['processing'],list):
            issue(errors, 'release.processing_type', where, '生成处理字段类型错误')
        elif gen['declared_native'] and any(isinstance(p,dict) and p.get('operation') in ('resize','upscale') for p in gen['processing']):
            issue(errors, 'release.false_native', where, '放大/超分后不能宣称原生')
        for p in gen.get('processing', []) if isinstance(gen.get('processing'),list) else []:
            if not isinstance(p,dict) or not nonblank(p.get('operation')) or not nonblank(p.get('description')):
                issue(errors, 'release.processing_detail', where, '处理过程必须记录实际操作与说明')
    for ref in c['composition']['reference_ids']:
        if assets[ref].get('rights_status') != 'cleared':
            issue(errors, 'release.reference_rights', where, '参考素材来源/使用状态尚未清理')
    try:
        review = load_json(safe_path(root, prod['review_file']))
    except (DataError, OSError) as exc:
        issue(errors, 'release.review_missing', where, str(exc))
        return
    if review.get('card_id') != c['card_id'] or review.get('design_fingerprint') != design_fingerprint(root, card_path):
        issue(errors, 'release.stale_design', where, '审核绑定的卡牌或设计摘要已过期')
    if not prod['artifact'] or review.get('image_sha256') != prod['artifact'].get('sha256'):
        issue(errors, 'release.stale_image', where, '审核没有绑定当前最终图像')
    if not nonblank(review.get('reviewed_by')) or not valid_date(review.get('reviewed_at')):
        issue(errors, 'release.reviewer', where, '缺少实际审核者/时间记录')
    checks = review.get('checks', {})
    for key in CHECK_NAMES:
        item = checks.get(key,{}) if isinstance(checks,dict) else {}
        if not isinstance(item,dict) or item.get('status') != 'pass' or not nonblank(item.get('note')):
            issue(errors, 'release.check_not_passed', where+':'+key, '尚未记录实际检查通过及观察说明')
    for d in DIMS:
        item = review.get('semantic_readback', {}).get(d,{})
        cue_ids = set(c['semantics'][d]['carrier_ids'])
        if (item.get('status') != 'pass' or not nonblank(item.get('observation')) or
            not isinstance(item.get('observed_cue_ids'),list) or not item['observed_cue_ids'] or
            not set(item['observed_cue_ids']).issubset(cue_ids)):
            issue(errors, 'release.readback', where+':'+d, '没有当前实图的有效语义回读记录')
    ap = review.get('approval',{})
    if not (ap.get('status')=='approved' and nonblank(ap.get('by')) and valid_date(ap.get('at')) and nonblank(ap.get('reference'))):
        issue(errors, 'release.approval', where, '缺少真实最终批准依据')
    if prod['stage'] != 'approved':
        issue(errors, 'release.stage', where, '尚未进入approved阶段；发布检查不自动批准')


def load_context(root: Path) -> dict:
    """Read shared registries once so a full check does not re-read them per card."""
    return {'config': load_json(root/'config/project.json'),
            'registry': load_json(root/'catalog/pathways.json'),
            'sources': load_json(root/'sources/registry.json'),
            'assets': load_json(root/'references/manifest.json'),
            'canons': {}}


def check_repository(root: Path, level: str='scaffold', selector: str | None=None) -> dict:
    root = root.resolve()
    errors: list[dict] = []
    ctx = load_context(root)
    config = ctx['config']
    registry = ctx['registry']
    rows = registry.get('pathways', [])
    if len(rows)!=22 or {r.get('id') for r in rows if isinstance(r,dict)} != set(PATH_IDS):
        issue(errors, 'registry.pathways', 'catalog/pathways.json', '必须包含22条不重复的目标途径ID')
    if (config.get('pathway_count')!=22 or config.get('expected_cards')!=220 or
        config.get('sequence_order')!=list(range(9,-1,-1)) or config.get('dimensions')!=list(DIMS)):
        issue(errors, 'config.targets', 'config/project.json', '22×10、顺序或六维契约不一致')
    all_cards = sorted((root/'pathways').glob('*/sequences/*/card.json'))
    expected_paths = {f'pathways/{s}/sequences/{n:02d}/card.json' for s in PATH_IDS for n in range(10)}
    actual_paths = {p.relative_to(root).as_posix() for p in all_cards}
    if actual_paths != expected_paths:
        issue(errors, 'inventory.cards', 'pathways/', f'卡位错误：缺少{len(expected_paths-actual_paths)}，多余{len(actual_paths-expected_paths)}')
    required = ['AGENTS.md','pathways/AGENTS.md','sources/registry.json','references/manifest.json'] + config.get('design_document_paths',[])
    for slug in PATH_IDS:
        required.extend([f'pathways/{slug}/AGENTS.md',f'pathways/{slug}/direction.json',f'pathways/{slug}/canon.json'])
    for rel in required:
        try:
            safe_path(root,rel)
        except DataError as exc:
            issue(errors,'dependency.missing',rel,str(exc))
    for slug in PATH_IDS:
        try:
            direction=load_json(root/f'pathways/{slug}/direction.json')
            plans=direction.get('sequence_planning',[])
            if (direction.get('pathway_id')!=slug or direction.get('content_kind')!='art_proposal' or
                direction.get('status') not in ('proposed','approved') or
                len(plans)!=10 or [r.get('sequence') for r in plans]!=list(range(9,-1,-1))):
                issue(errors,'direction.contract',slug,'路径视觉提案身份/性质/十序列规划不匹配')
            canon=load_json(root/f'pathways/{slug}/canon.json')
            ctx['canons'][slug]=canon
            if canon.get('pathway_id')!=slug or not isinstance(canon.get('claims'),list):
                issue(errors,'canon.contract',slug,'断言文件身份/结构不匹配')
        except (DataError,TypeError,AttributeError) as exc:
            issue(errors,'pathway.data',slug,str(exc))
    chains=[]
    for slug in PATH_IDS:
        rels=['AGENTS.md','pathways/AGENTS.md',f'pathways/{slug}/AGENTS.md']
        paths=[root/r for r in rels]
        if all(p.is_file() for p in paths):
            size=sum(p.stat().st_size for p in paths)
            chains.append(size)
            if size > config.get('agent_chain_limit_bytes',32768):
                issue(errors,'agents.chain_size',slug,'指令祖先链超过项目配置字节预算')
    paths=[resolve_card(root,selector)] if selector else all_cards
    checked=0
    for p in paths:
        try:
            errors.extend(validate_card(root,p,level,ctx))
            checked+=1
        except (DataError,TypeError,KeyError,ValueError,AttributeError) as exc:
            issue(errors,'data.invalid',p.relative_to(root).as_posix(),str(exc))
    return {'check_level':level,'scope':selector or 'all','passed':not errors,
            'pathway_count':len(rows),'card_slots_present':len(all_cards),'cards_checked':checked,
            'max_agent_chain_bytes':max(chains,default=0),'errors':errors,
            'limitation':'检查数据和记录，不证明小说设定正确、图像语义可读或实际人工批准。'}


def status(root: Path) -> dict:
    root=root.resolve()
    cards=[load_json(p) for p in (root/'pathways').glob('*/sequences/*/card.json')]
    counts=Counter(c.get('production',{}).get('stage','invalid') for c in cards)
    by_pathway={}
    for c in cards:
        slug=c.get('pathway_id') or 'invalid'
        by_pathway.setdefault(slug,Counter())[c.get('production',{}).get('stage','invalid')]+=1
    actual_images=missing=invalid=0
    for c in cards:
        art=c.get('production',{}).get('artifact')
        if not isinstance(art,dict) or not nonblank(art.get('path')):
            missing+=1
            continue
        try:
            p=safe_path(root,art.get('path'))
        except DataError:
            missing+=1
            continue
        if nonblank(art.get('sha256')) and digest_file(p)==art.get('sha256'):
            actual_images+=1
        else:
            invalid+=1
    return {'pathways':len(load_json(root/'catalog/pathways.json')['pathways']),
            'card_slots':len(cards),'stages':dict(counts),'artifact_files_present':actual_images,
            'artifact_missing':missing,'artifact_invalid':invalid,
            'name_states':dict(Counter(c.get('name_status') for c in cards)),
            'matrix_by_pathway':{slug:{stage:by_pathway.get(slug,Counter()).get(stage,0)
                                       for stage in STAGES} for slug in PATH_IDS},
            'note':'stage为记录状态，不自动证明审核通过；正式成品使用release检查。'}


def build_brief(root: Path, selector: str, draft: bool=False, slim: bool=False) -> Path:
    root=root.resolve()
    card_path=resolve_card(root,selector).resolve()
    # Drafts still require structural integrity. Do not quietly compile malformed data.
    report=check_repository(root,'scaffold' if draft else 'design',selector)
    if not report['passed']:
        codes=', '.join(sorted({x['code'] for x in report['errors']}))
        raise DataError(f'任务单被阻断：{codes}。研究草稿使用--draft，但结构错误仍需修复。')
    c=load_json(card_path)
    sources=load_json(root/'sources/registry.json')
    canon=load_json(root/f'pathways/{c["pathway_id"]}/canon.json')
    claimed_ids={r for d in DIMS for r in c['semantics'][d]['claim_refs']}
    current_claims=[cl for cl in canon['claims'] if cl['id'] in claimed_ids]
    source_ids={r['source_id'] for cl in current_claims for r in cl['source_refs']}
    source_subset=[s for s in sources['sources'] if s['id'] in source_ids]
    reference_subset=[a for a in load_json(root/'references/manifest.json')['assets']
                      if a['id'] in c['composition']['reference_ids']]
    config=load_json(root/'config/project.json')
    hierarchy=load_json(root/config['sequence_hierarchy_path'])
    rank=next((row for row in hierarchy['sequence_levels'] if row['sequence']==c['sequence']),None)
    if rank is None:
        raise DataError(f'层级配置缺少序列{c["sequence"]}映射')
    pathrow=next(r for r in load_json(root/'catalog/pathways.json')['pathways'] if r['id']==c['pathway_id'])
    out=safe_path(root, f'generated/{c["card_id"]}', must_exist=False)
    out.mkdir(parents=True,exist_ok=True)
    for filename in ('task.md','art-brief.md','overlay-copy.json','semantic-checklist.md','dependencies.json'):
        safe_path(root, f'generated/{c["card_id"]}/{filename}', must_exist=False)
    mode='DRAFT / RESEARCH — 禁止作为已核验最终出图任务' if draft else 'DESIGN-CHECKED / 尚未出图或批准'
    summary=[f'# {c["card_id"]} · 单卡任务',f'\n状态：**{mode}**',
             f'工作身份：{pathrow["working_name_zh"]} · 序列{c["sequence"]} · {c["name_zh"] or "名称待核验"} · {rank["specific_label_zh"]}',
             '\n此任务是执行Agent上下文，不是假定图像工具自动读取的API请求。',
             '\n## 六维表达计划']
    for d in DIMS:
        e=c['semantics'][d]
        summary += [f'\n### {DIM_LABELS[d]} / {e["knowledge_state"]}',
                    f'- 拟表达：{e["intent"] or "待研究，不编造"}',
                    f'- 精度：{e["fidelity"]}；载体：{", ".join(e["carrier_ids"]) or "未设计"}',
                    f'- 回读：{e["readback"] or "未定义"}',
                    f'- 防误读：{e["misreading_guard"] or "未定义"}',
                    f'- 待核问题：{e["research_question"]}']
    summary += ['\n## 当前卡数据\n```json',json.dumps(c,ensure_ascii=False,indent=2),'```',
                '\n## 当前引用断言（仅限此卡）\n```json',json.dumps(current_claims,ensure_ascii=False,indent=2),'```',
                '\n## 相关来源与可访问范围\n```json',json.dumps(source_subset,ensure_ascii=False,indent=2),'```',
                '\n## 当前参考资产（元数据不是已传递的图像附件）\n```json',
                json.dumps(reference_subset,ensure_ascii=False,indent=2),'```',
                '\n## 必须传递的规则与途径方向']
    actualpaths=context_paths(root,card_path,config)
    # Include actual rule text and direction, but not the other 219 cards or full canon.
    for p in actualpaths:
        rel=p.relative_to(root).as_posix()
        if slim and p.suffix=='.md':
            continue
        if p.suffix=='.md' or rel.endswith('/direction.json') or rel=='config/project.json':
            summary += [f'\n---\n### 来源文件：{rel}\n',p.read_text(encoding='utf-8')]
    summary += ['\n## 参考附件提醒',
                '仅使用reference_ids登记的真实资产；执行Agent必须通过当前工具支持的附件方式传入。',
                '没有附件时不得声称已参考旧图；本任务单不是授权，也不自动发生收费调用。']
    (out/'task.md').write_text('\n'.join(summary)+'\n',encoding='utf-8')
    art=[f'# {c["card_id"]} · 插画转译任务',f'\n{mode}',
         '\n一图一牌；六维语义完整、形式自由；插画与精确文字可分层。',
         f'\n主事件：{c["composition"]["hero_event"] or "待核验和设计；不得自行补能力/材料/仪式。"}',
         f'构图：{c["composition"]["layout"]}',
         '\n## 非文字载体\n```json',
         json.dumps([q for q in c['cues'] if q['channel']!='text'],ensure_ascii=False,indent=2),'```',
         '\n执行时同时读取task.md中的事实、限制和路径语言；本文不是完整独立的API提示。']
    (out/'art-brief.md').write_text('\n'.join(art)+'\n',encoding='utf-8')
    write_json(out/'overlay-copy.json',{'card_id':c['card_id'],'draft':draft,
                'text_cues':[q for q in c['cues'] if q['channel']=='text']})
    checklist=['# 实图六维回读清单','\n当前未观察图片；以下为待执行检查，不是通过记录。']
    for d in DIMS:
        checklist += [f'\n## {DIM_LABELS[d]}',f'计划：{c["semantics"][d]["readback"] or "待定义"}',
                      '实际观察：未执行。\n结果：not_run。']
    (out/'semantic-checklist.md').write_text('\n'.join(checklist)+'\n',encoding='utf-8')
    write_json(out/'dependencies.json',{'card_id':c['card_id'],'draft':draft,
            'design_fingerprint':design_fingerprint(root,card_path),
            'files':[{'path':p.relative_to(root).as_posix(),'sha256':digest_file(p)} for p in actualpaths],
            'note':'文件摘要为本次快照；设计摘要排除card的production流程字段。'})
    return out


def verify_manifest(root: Path) -> dict:
    root=root.resolve()
    p=root/'SHA256SUMS'
    if not p.is_file():
        raise DataError('尚无SHA256SUMS文件')
    errors=[]; n=0; seen=set()
    for line in p.read_text(encoding='utf-8').splitlines():
        if not line.strip():
            continue
        try:
            h,rel=line.split('  ',1)
            if not HEX64.fullmatch(h) or rel in seen:
                raise DataError('摘要格式错误或重复路径')
            seen.add(rel)
            actual=digest_file(safe_path(root,rel))
            if actual!=h:
                issue(errors,'manifest.mismatch',rel,'内容已变更')
            n+=1
        except (ValueError,DataError) as exc:
            issue(errors,'manifest.invalid',line,str(exc))
    return {'passed':not errors,'files_checked':n,'errors':errors,
            'note':'只验证列出的交付文件；运行新增的generated/缓存不在清单内。'}


def main(argv=None) -> int:
    root=ROOT.resolve()
    parser=argparse.ArgumentParser(description=__doc__)
    sub=parser.add_subparsers(dest='command',required=True)
    p=sub.add_parser('check',help='三级门槛检查，失败返回非零')
    p.add_argument('--level',choices=('scaffold','design','release'),default='scaffold')
    p.add_argument('--card',help='fool:09 或 lotm.fool.s09')
    p.add_argument('--json-out',help='将报告保存到仓库内相对路径')
    sub.add_parser('status',help='实际卡位与记录状态')
    sub.add_parser('next',help='找到生产顺序中尚未批准的第一张卡，不自动出图')
    p=sub.add_parser('brief',help='编译任务单；不会调用图像API')
    p.add_argument('--card',required=True); p.add_argument('--draft',action='store_true')
    p.add_argument('--slim',action='store_true',help='精简任务单：不内联design/规则全文，仅本卡、途径方向与引用清单')
    p=sub.add_parser('fingerprint',help='打印当前设计依赖摘要')
    p.add_argument('--card',required=True)
    sub.add_parser('verify-manifest',help='验证交付文件摘要')
    args=parser.parse_args(argv)
    try:
        if args.command=='check':
            report=check_repository(root,args.level,args.card)
            if args.json_out:
                target=safe_path(root,args.json_out,must_exist=False)
                if not target.is_relative_to(root/'reports'):
                    raise DataError('--json-out仅允许写reports/目录，避免覆盖源文件')
                write_json(target,report)
            print(json.dumps(report,ensure_ascii=False,indent=2))
            return 0 if report['passed'] else 2
        if args.command=='status':
            print(json.dumps(status(root),ensure_ascii=False,indent=2)); return 0
        if args.command=='next':
            rows=sorted(load_json(root/'catalog/pathways.json')['pathways'],key=lambda r:r['production_order'])
            order=load_json(root/'config/project.json')['sequence_order']
            for r in rows:
                for n in order:
                    p=resolve_card(root,f'{r["id"]}:{n:02d}'); c=load_json(p)
                    if c['production']['stage']!='approved':
                        print(json.dumps({'card':f'{r["id"]}:{n:02d}','card_id':c['card_id'],
                              'stage':c['production']['stage'],'path':p.relative_to(root).as_posix()},ensure_ascii=False,indent=2))
                        return 0
            print('记录中全部approved；交付前仍须执行全量release检查。'); return 0
        if args.command=='brief':
            out=build_brief(root,args.card,args.draft,args.slim)
            print(out.relative_to(root).as_posix()); return 0
        if args.command=='fingerprint':
            print(design_fingerprint(root,resolve_card(root,args.card))); return 0
        if args.command=='verify-manifest':
            result=verify_manifest(root)
            print(json.dumps(result,ensure_ascii=False,indent=2))
            return 0 if result['passed'] else 2
    except (DataError,OSError,KeyError,TypeError,ValueError) as exc:
        print(f'ERROR: {exc}',file=sys.stderr); return 2
    return 1

if __name__=='__main__':
    sys.exit(main())
