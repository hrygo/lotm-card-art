#!/usr/bin/env python3
"""Project the global design tokens onto the two consumers. Python 3.10+, standard library only.

事实源是 `config/design-tokens.json`；本工具只做投影与漂移检查：

  generate  写出 `DesignTokens.generated.swift`（客户端）与 `design/figma-kit/tokens.js`（Figma 生成器数据）
  check     校验两份投影没有漂移，并扫描客户端源码里是否又出现设计字面量
  baseline  重写未刻度类别的冻结登记（`config/design-token-baseline.json`）

它不判断设计好不好，也不代替 Figma 里跑一遍生成器：`check` 只能证明两边数值一致、
代码没有绕过 token 新写字面量。

扫描分两类：有 token 刻度的类别（字号、内边距、间距、圆角、描边、相等价的 size）
出现字面量即失败；还没有刻度的类别（不透明度、阴影/模糊半径、位移、其它结构尺寸）
按 `config/design-token-baseline.json` 冻结——出现基线外的新取值即失败，删减则放行。
冻结不是「允许」：它是让每个未刻度数字都必须在评审里显式登记一次，直到为它定义刻度。
"""
from __future__ import annotations
import argparse
from collections import Counter
import json
from pathlib import Path
import re
import sys
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
TOKENS_PATH = ROOT / 'config' / 'design-tokens.json'
SWIFT_PATH = ROOT / 'apps' / 'WorldOfMysteries' / 'Sources' / 'WorldOfMysteriesFeatures' / 'DesignTokens.generated.swift'
KIT_PATH = ROOT / 'design' / 'figma-kit' / 'tokens.js'
BASELINE_PATH = ROOT / 'config' / 'design-token-baseline.json'
FEATURE_DIR = ROOT / 'apps' / 'WorldOfMysteries' / 'Sources' / 'WorldOfMysteriesFeatures'

SWIFT_HEADER = '''// 由 tools/design_tokens.py 生成，请勿手改。
// 事实源：config/design-tokens.json ｜ 合同说明：design/design-tokens.md
import SwiftUI
'''

KIT_HEADER = '''// 由 tools/design_tokens.py 从 config/design-tokens.json 生成，请勿手改。
// Figma 生成器（main.js）在运行时读取这些常量；不要在这里补值。
'''


class TokenError(ValueError):
    """面向使用者的校验错误，而不是未处理的 traceback。"""


def load_tokens() -> dict[str, Any]:
    try:
        data = json.loads(TOKENS_PATH.read_text(encoding='utf-8'))
    except FileNotFoundError as exc:  # pragma: no cover - 仓库内必然存在
        raise TokenError(f'缺少 token 事实源: {TOKENS_PATH}') from exc
    except json.JSONDecodeError as exc:
        raise TokenError(f'{TOKENS_PATH} 不是合法 JSON: {exc}') from exc
    return data


def camel(name: str) -> str:
    """a.b-c → aBc；第一段保持原样。"""
    parts = re.split(r'[.\-]', name)
    head, tail = parts[0], parts[1:]
    return head + ''.join(p[:1].upper() + p[1:] for p in tail)


def swift_ident(name: str) -> str:
    """数字段补前缀，避免出现非法的标识符。"""
    if name.isdigit():
        return 's' + name
    return camel(name)


def fmt(value: float) -> str:
    text = f'{value:.6f}'.rstrip('0').rstrip('.')
    return text if text else '0'


def resolve_color(name: str, colors: dict[str, Any], seen: tuple[str, ...] = ()) -> tuple[float, float, float, float]:
    if name in seen:
        raise TokenError(f'颜色引用成环: {" -> ".join(seen + (name,))}')
    entry = colors.get(name)
    if entry is None:
        raise TokenError(f'颜色引用了不存在的 token: {name}')
    if 'ref' in entry:
        r, g, b, a = resolve_color(entry['ref'], colors, seen + (name,))
    elif 'r' in entry and 'g' in entry and 'b' in entry:
        r, g, b = entry['r'], entry['g'], entry['b']
        a = entry.get('alpha', 1)
    else:
        raise TokenError(f'颜色 token 缺少 ref 或 r/g/b: {name}')
    return r, g, b, a


def build_swift(tokens: dict[str, Any]) -> str:
    colors: dict[str, Any] = tokens['color']
    lines = [SWIFT_HEADER, '/// 全局设计 token（`config/design-tokens.json` 的 Swift 投影）。', 'public enum DesignTokens {']

    lines.append('    /// 原始色板与语义色。引用型 token 通过 opacity 保持与事实源一致的叠加关系。')
    lines.append('    public enum Palette {')
    for name in sorted(colors):
        entry = colors[name]
        ident = swift_ident(name)
        alpha = entry.get('alpha', 1)
        if 'ref' in entry:
            base = swift_ident(entry['ref'])
            body = f'Palette.{base}' if alpha == 1 else f'Palette.{base}.opacity({fmt(alpha)})'
            lines.append(f'        public static let {ident} = {body}')
        else:
            r, g, b, a = resolve_color(name, colors)
            body = f'SwiftUI.Color(red: {fmt(r)}, green: {fmt(g)}, blue: {fmt(b)})'
            if a != 1:
                body = f'{body}.opacity({fmt(a)})'
            lines.append(f'        public static let {ident} = {body}')
    lines.append('    }')

    for group, prefix, ctype, comment in (
        ('space', 's', 'CGFloat', '间距刻度；数值即取值，不做二次归一。'),
        ('radius', 'r', 'CGFloat', '圆角；具名项是结构语义（卡片 / 面板 / 抽屉 / 芯片 / 侧栏条）。'),
        ('stroke', '', 'CGFloat', '描边宽度。'),
    ):
        lines.append('')
        lines.append(f'    /// {comment}')
        lines.append(f'    public enum {group.capitalize()} {{')
        for name, value in tokens[group].items():
            ident = prefix + name if prefix and name.isdigit() else camel(name)
            lines.append(f'        public static let {ident}: {ctype} = {fmt(float(value))}')
        lines.append('    }')

    lines.append('')
    lines.append('    /// 字号；取值为事实源里的实际使用值。')
    lines.append('    public enum FontSize {')
    for name, value in tokens['type']['size'].items():
        lines.append(f'        public static let s{name}: CGFloat = {fmt(float(value))}')
    lines.append('    }')

    lines.append('')
    lines.append('    /// 结构性尺寸（窗口、侧栏、命中区）。')
    lines.append('    public enum Size {')
    for name, value in tokens['size'].items():
        lines.append(f'        public static let {camel(name)}: CGFloat = {fmt(float(value))}')
    lines.append('    }')

    lines.append('')
    lines.append('    /// 动效时长与弹簧参数（Figma 里只能记说明，真实动效以代码为准）。')
    lines.append('    public enum MotionDuration {')
    for name, value in tokens['motion']['duration'].items():
        lines.append(f'        public static let ms{name}: Double = {fmt(float(value))}')
    lines.append('    }')

    lines.append('    public enum MotionSpring {')
    for name, spec in tokens['motion']['spring'].items():
        ident = camel(name)
        lines.append(
            f'        public static var {ident}: Spring '
            f'{{ SwiftUI.Spring(response: {fmt(float(spec["response"]))}, '
            f'dampingRatio: {fmt(float(spec["dampingFraction"]))}) }}'
        )
    lines.append('    }')

    lines.append('}')
    return '\n'.join(lines) + '\n'


def build_kit(tokens: dict[str, Any]) -> str:
    colors: dict[str, Any] = tokens['color']
    flat: list[list[Any]] = []
    for name in sorted(colors):
        r, g, b, a = resolve_color(name, colors)
        flat.append(['color/' + name.replace('.', '/'), [round(r, 6), round(g, 6), round(b, 6), round(a, 6)]])
    numbers: list[list[Any]] = []
    for group in ('space', 'radius', 'stroke'):
        for name, value in tokens[group].items():
            ident = 's' + name if name.isdigit() else name
            numbers.append([f'{group}/{ident}', value])
    for name, value in tokens['type']['size'].items():
        numbers.append([f'font/size/{name}', value])
    for name, value in tokens['size'].items():
        numbers.append([f'size/{name}', value])
    for name, value in tokens['type']['lineHeight'].items():
        numbers.append([f'font/lineHeight/{name}', value])

    payload = {
        'colors': flat,
        'numbers': numbers,
        'weights': tokens['type']['weight'],
        'designs': tokens['type']['design'],
    }
    body = 'const TOKEN_DATA = ' + json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=False) + ';\n'
    return KIT_HEADER + body


# 数字字面量：至少要有一位整数位，避免把 `.infinity` 这类写成 `\.\d` 的东西当成数值。
NUM = r'(\d+(?:\.\d+)?)'

LITERAL_RULES = (
    ('字号', re.compile(r'\.font\(\.system\(size:\s*' + NUM)),
    ('内边距', re.compile(r'\.padding\(\s*' + NUM + r'\s*\)')),
    ('轴内边距', re.compile(r'\.padding\(\.(?:horizontal|vertical|top|bottom|leading|trailing),\s*' + NUM + r'\s*\)')),
    ('堆叠间距', re.compile(r'spacing:\s*' + NUM)),
    ('弹性间距', re.compile(r'Spacer\(\s*minLength:\s*' + NUM)),
    ('圆角', re.compile(r'cornerRadius:\s*' + NUM)),
    # `RoundedRectangle(cornerRadius:)` 与 `.cornerRadius(_)` 是同一件事的两种写法，都要认。
    ('圆角', re.compile(r'\.cornerRadius\(\s*' + NUM)),
    ('描边', re.compile(r'lineWidth:\s*' + NUM)),
)
ALLOWED_LITERALS = {'0'}

# 结构性尺寸走另一条判据：只有当字面量**已经等于**某个 size token 时才判错——这是
# 「token 存在却没用」的漂移。要求所有局部尺寸都 token 化是另一回事：那需要先定义
# 尺寸刻度，属于设计决策，不由脚本发明。
STRUCTURAL_ARG = re.compile(
    r'\b(width|height|minWidth|minHeight|maxWidth|maxHeight):\s*' + NUM
)
STRUCTURAL_LABELS = {
    'width': '宽度',
    'height': '高度',
    'minWidth': '最小宽',
    'minHeight': '最小高',
    'maxWidth': '最大宽',
    'maxHeight': '最大高',
}

# 还没有 token 刻度的类别：不透明度、阴影/模糊半径、位移。给它们定刻度是设计决策，
# 不由脚本凭空发明；但「没人管」会造成新的手写字面量无声混入，所以按
# `config/design-token-baseline.json` 冻结：基线外的新取值一律失败，删减放行。
FROZEN_RULES = (
    ('不透明度', re.compile(r'\.opacity\(\s*' + NUM + r'\s*\)')),
    ('阴影半径', re.compile(r'\.shadow\([^)]*radius:\s*' + NUM)),
    ('模糊半径', re.compile(r'\.blur\(\s*radius:\s*' + NUM)),
    ('位移', re.compile(r'\.offset\(\s*[xy]:\s*' + NUM)),
)
STRUCTURAL_CLASS = '结构性尺寸'
FROZEN_CLASSES = tuple(label for label, _ in FROZEN_RULES) + (STRUCTURAL_CLASS,)


def feature_files() -> list[Path]:
    return [path for path in sorted(FEATURE_DIR.glob('*.swift')) if path.name != SWIFT_PATH.name]


def label_of(path: Path) -> str:
    """报告里用仓库相对路径；测试注入临时目录时退回文件名。"""
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        return path.name


def scan_sources(
    tokens: dict[str, Any], features: list[Path] | None = None
) -> tuple[list[str], dict[str, Counter[str]]]:
    """扫描客户端源码：返回（有刻度类别的违规, 未刻度类别的取值计数）。"""
    problems: list[str] = []
    frozen: dict[str, Counter[str]] = {label: Counter() for label in FROZEN_CLASSES}
    sizes = {float(value): name for name, value in tokens['size'].items()}
    for path in (feature_files() if features is None else features):
        text = path.read_text(encoding='utf-8')
        if 'SwiftUI.Color(red:' in text or 'Color(red:' in text or 'Color(white:' in text:
            for lineno, line in enumerate(text.splitlines(), 1):
                if re.search(r'\bColor\((red|white):', line):
                    problems.append(f'{label_of(path)}:{lineno}: 直接写了颜色字面量，请用 DesignTokens.Palette')
        for label, rule in LITERAL_RULES:
            for match in rule.finditer(text):
                if match.group(1) in ALLOWED_LITERALS:
                    continue
                lineno = text[:match.start()].count('\n') + 1
                problems.append(f'{label_of(path)}:{lineno}: {label}字面量 {match.group(1)}，请用 DesignTokens')
        for match in STRUCTURAL_ARG.finditer(text):
            field, raw = match.group(1), match.group(2)
            name = sizes.get(float(raw))
            if name is None:
                frozen[STRUCTURAL_CLASS][raw] += 1
                continue
            lineno = text[:match.start()].count('\n') + 1
            problems.append(
                f'{label_of(path)}:{lineno}: {STRUCTURAL_LABELS[field]}字面量 {raw} 等于 size.{name}，'
                f'请用 DesignTokens.Size.{name}'
            )
        for label, rule in FROZEN_RULES:
            for match in rule.finditer(text):
                if match.group(1) in ALLOWED_LITERALS:
                    continue
                frozen[label][match.group(1)] += 1
    return (problems, frozen)


def scan_literals(
    tokens: dict[str, Any],
    features: list[Path] | None = None,
    baseline: dict[str, dict[str, int]] | None = None,
) -> tuple[list[str], list[str]]:
    """在 `scan_sources` 之上叠加冻结基线：基线外的新取值算失败，删减放行。"""
    problems, frozen = scan_sources(tokens, features)
    allowed_classes = {} if baseline is None else baseline
    notes = []
    for label in FROZEN_CLASSES:
        counts = frozen[label]
        if not counts:
            continue
        allowed = allowed_classes.get(label, {})
        for value, count in sorted(counts.items()):
            registered = allowed.get(value, 0)
            if count > registered:
                problems.append(
                    f'{label}字面量 {value} 未登记（{count} 处，基线 {registered} 处）：'
                    f'这些类别还没有 token 刻度，新增取值须显式登记（python3 tools/design_tokens.py baseline）'
                )
        top = '、'.join(f'{value}×{count}' for value, count in counts.most_common(3))
        notes.append(f'{label} {sum(counts.values())} 处 / {len(counts)} 个取值（冻结内；最多 {top}）')
    return (problems, notes)


def load_baseline() -> dict[str, dict[str, int]]:
    try:
        data = json.loads(BASELINE_PATH.read_text(encoding='utf-8'))
    except FileNotFoundError as exc:
        raise TokenError(
            f'缺少冻结基线 {BASELINE_PATH.relative_to(ROOT)}（运行 python3 tools/design_tokens.py baseline）'
        ) from exc
    except json.JSONDecodeError as exc:
        raise TokenError(f'{BASELINE_PATH.relative_to(ROOT)} 不是合法 JSON: {exc}') from exc
    classes = data.get('classes')
    if not isinstance(classes, dict):
        raise TokenError(f'{BASELINE_PATH.relative_to(ROOT)} 缺少 classes 字段')
    return classes


def write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding='utf-8')


# Figma 侧的语义文字样式（type/*）是手写表，不是生成物；这里保证它不自己发明数值。
TEXT_STYLE_ROW = re.compile(
    r'\[\s*"(type/[A-Za-z]+)"\s*,\s*([0-9]+)\s*,\s*"([a-z]+)"\s*,\s*([0-9]+)\s*,'
)


def scan_text_styles(
    tokens: dict[str, Any], main_path: Path | None = None
) -> tuple[list[str], int]:
    path = KIT_PATH.parent / 'main.js' if main_path is None else main_path
    if not path.exists():
        return ([f'缺少 Figma 生成器 {label_of(path)}'], 0)
    rows = TEXT_STYLE_ROW.findall(path.read_text(encoding='utf-8'))
    if not rows:
        return ([f'{label_of(path)} 里找不到 type/* 文字样式定义'], 0)
    sizes = {int(key) for key in tokens['type']['size']}
    weights = set(tokens['type']['weight'])
    line_heights = set(tokens['type']['lineHeight'].values())
    problems: list[str] = []
    for name, size, weight, line_height in rows:
        if int(size) not in sizes:
            problems.append(f'{name} 字号 {size} 不在 config 的 type.size 里')
        if weight not in weights:
            problems.append(f'{name} 字重 {weight} 不在 config 的 type.weight 里')
        if int(line_height) not in line_heights:
            problems.append(f'{name} 行高 {line_height} 不在 config 的 type.lineHeight 里')
    return (problems, len(rows))


def command_generate(_: argparse.Namespace) -> int:
    tokens = load_tokens()
    write(SWIFT_PATH, build_swift(tokens))
    write(KIT_PATH, build_kit(tokens))
    print(f'[ok] Swift  {SWIFT_PATH.relative_to(ROOT)}')
    print(f'[ok] Figma  {KIT_PATH.relative_to(ROOT)}')
    return 0


def command_baseline(_: argparse.Namespace) -> int:
    tokens = load_tokens()
    _, frozen = scan_sources(tokens)
    classes = {
        label: {value: count for value, count in sorted(counts.items())}
        for label, counts in frozen.items()
        if counts
    }
    payload = {
        'role': (
            '未刻度设计字面量的冻结登记。这些类别还没有 token 刻度；新增取值会被 '
            'tools/design_tokens.py check 拦下，删减放行。改这份文件必须显式重跑 baseline 并在评审里说明——'
            '它不是批准，只是把未刻度的数字留在可见处。'
        ),
        'source': 'tools/design_tokens.py',
        'scope': 'apps/WorldOfMysteries/Sources/WorldOfMysteriesFeatures/*.swift',
        'classes': classes,
    }
    write(BASELINE_PATH, json.dumps(payload, ensure_ascii=False, indent=2) + '\n')
    print(
        f'[ok] 冻结基线已重写：{BASELINE_PATH.relative_to(ROOT)}'
        f'（{len(classes)} 类 / {sum(len(values) for values in classes.values())} 个取值）'
    )
    return 0


def command_check(_: argparse.Namespace) -> int:
    tokens = load_tokens()
    baseline = load_baseline()
    failures: list[str] = []
    for path, expected in ((SWIFT_PATH, build_swift(tokens)), (KIT_PATH, build_kit(tokens))):
        if not path.exists():
            failures.append(f'缺少投影文件 {path.relative_to(ROOT)}（运行 generate）')
        elif path.read_text(encoding='utf-8') != expected:
            failures.append(f'{path.relative_to(ROOT)} 与 config/design-tokens.json 不一致（运行 generate）')
    literal_problems, frozen_notes = scan_literals(tokens, baseline=baseline)
    failures.extend(literal_problems)
    style_problems, style_count = scan_text_styles(tokens)
    failures.extend(style_problems)
    if failures:
        for item in failures:
            print(f'[fail] {item}')
        print(f'\n设计 token 检查未通过：{len(failures)} 项')
        return 1
    counts = ', '.join(
        f'{group} {len(tokens[group])}' for group in ('color', 'space', 'radius', 'stroke', 'size')
    )
    print(f'[ok] 投影一致；{style_count} 条文字样式复用 token；无未登记的字面量（{counts}）')
    for note in frozen_notes:
        print(f'[note] 未刻度类别冻结在内（新增取值会被拒）：{note}')
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description='卡牌演示全局设计 token 投影与检查')
    sub = parser.add_subparsers(dest='command', required=True)
    sub.add_parser('generate', help='写出 Swift 与 Figma kit 投影')
    sub.add_parser('check', help='校验投影漂移与字面量绕过')
    sub.add_parser('baseline', help='重写未刻度类别的冻结登记')
    args = parser.parse_args(argv)
    try:
        if args.command == 'generate':
            return command_generate(args)
        if args.command == 'baseline':
            return command_baseline(args)
        return command_check(args)
    except TokenError as exc:
        print(f'[error] {exc}')
        return 2


if __name__ == '__main__':
    sys.exit(main())
