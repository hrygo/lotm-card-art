#!/usr/bin/env python3
"""契约 pin 的单一来源重封存器：--check 检漂移，--write 只改 hash 文本。

pin 语义 = 合同里 `contracts[]` 的 {path, sha256} 断言「该路径文件哈希如此」，
由 `production.py:verify_records` 校验。本工具只重算并改写 hash 字段，
不改任何其他字节、不增删条目、不判断除「该不该 pin」以外的语义。

范围：只处理 `production/**` 的活合同（人工维护）。`artifacts/**` 是历史回执
（不可覆盖 provenance），其 pin 记录的是产出当时的哈希，故意会与今日不符，
因此**按设计排除**；`generated/`、`reports/` 为派生输出，同样排除。
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path


DEFAULT_ROOT = Path(__file__).resolve().parents[1]
CONSUMER_PREFIX = "production/"
EXCLUDED_PREFIXES = ("artifacts/", "generated/", "reports/", ".git/", ".build/", "node_modules/")
MASK_RE = re.compile(r'("sha256"\s*:\s*)"[0-9a-f]{64}"')
HASH_RE = re.compile(r"^[0-9a-f]{64}$")


class PinError(RuntimeError):
    """pin 漂移、缺失或结构不合法。"""


def sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def discover_consumers(root: Path) -> list[Path]:
    found = []
    for path in root.rglob("*.json"):
        rel = path.relative_to(root).as_posix()
        if rel.startswith(EXCLUDED_PREFIXES):
            continue
        if not rel.startswith(CONSUMER_PREFIX):
            continue
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        if isinstance(data, dict) and isinstance(data.get("contracts"), list) and data["contracts"]:
            found.append(path)
    return sorted(found, key=lambda p: p.relative_to(root).as_posix())


def collect_entries(root: Path, consumer: Path) -> list[tuple[int, str, str]]:
    data = json.loads(consumer.read_text(encoding="utf-8"))
    entries = []
    for index, entry in enumerate(data["contracts"]):
        if not isinstance(entry, dict):
            raise PinError(f"{consumer.relative_to(root)}: contracts[{index}] 不是对象")
        target, digest = entry.get("path"), entry.get("sha256")
        if not isinstance(target, str) or not isinstance(digest, str) or not HASH_RE.match(digest):
            raise PinError(f"{consumer.relative_to(root)}: contracts[{index}] 缺 path 或 sha256")
        entries.append((index, target, digest))
    return entries


def audit(root: Path) -> tuple[list[str], int]:
    """返回 (漂移/缺失问题列表, pin 总数)。文件缺失是错误，不是跳过。"""
    problems: list[str] = []
    total = 0
    for consumer in discover_consumers(root):
        rel = consumer.relative_to(root).as_posix()
        for _index, target, digest in collect_entries(root, consumer):
            total += 1
            pinned = root / target
            if not pinned.is_file():
                problems.append(f"MISSING {rel} -> {target}")
                continue
            actual = sha256_file(pinned)
            if actual != digest:
                problems.append(f"STALE   {rel} -> {target} ({digest[:12]}… -> {actual[:12]}…)")
    return problems, total


def seal(root: Path) -> list[str]:
    """按当前文件重写过期 pin，逐字节保留其余内容；返回被改写的消费者列表。"""
    rewritten: list[str] = []
    for consumer in discover_consumers(root):
        rel = consumer.relative_to(root).as_posix()
        text = consumer.read_text(encoding="utf-8")
        updated, changed = _reseal_text(root, rel, text, collect_entries(root, consumer))
        if not changed:
            continue
        if MASK_RE.sub(r'\1"<HASH>"', text) != MASK_RE.sub(r'\1"<HASH>"', updated):
            raise PinError(f"{rel}: 改写越过了 sha256 字段，已中止（未落盘）")
        _atomic_write(consumer, updated)
        rewritten.append(rel)
    return rewritten


def _reseal_text(
    root: Path, rel: str, text: str, entries: list[tuple[int, str, str]]
) -> tuple[str, bool]:
    updated = text
    changed = False
    for _index, target, digest in entries:
        pinned = root / target
        if not pinned.is_file():
            raise PinError(f"{rel}: 被 pin 的文件不存在：{target}")
        actual = sha256_file(pinned)
        if actual == digest:
            continue
        if updated.count(digest) != 1:
            raise PinError(f"{rel}: 旧哈希 {digest[:12]}… 在文本中不是唯一出现，已中止")
        updated = updated.replace(digest, actual)
        changed = True
    return updated, changed


def _atomic_write(path: Path, text: str) -> None:
    temp = path.with_name(path.name + ".pinseal.tmp")
    with open(temp, "w", encoding="utf-8", newline="") as stream:
        stream.write(text)
    temp.replace(path)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="契约 pin 重封存（单一来源）")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--check", action="store_true", help="只检漂移；有漂移则退出码 1")
    mode.add_argument("--write", action="store_true", help="重写过期 pin，其余字节不动")
    parser.add_argument("--root", default=str(DEFAULT_ROOT), help="仓库根（测试可指向合成树）")
    args = parser.parse_args(argv)
    root = Path(args.root).resolve()
    try:
        if args.check:
            problems, total = audit(root)
            for problem in problems:
                print(problem)
            print(f"检查 {total} 条 pin：{'通过' if not problems else f'{len(problems)} 条需处理'}")
            return 1 if problems else 0
        rewritten = seal(root)
        print(f"重封存 {len(rewritten)} 个合同文件" + (f"：{', '.join(rewritten)}" if rewritten else "（无需改动）"))
        return 0
    except PinError as exc:
        print(f"错误：{exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
