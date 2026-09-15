"""fresh checkout 自证：clone 后无需额外上下文即可证明仓库自洽（打 tag 前置检查）。"""

from __future__ import annotations

import argparse
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]

STEPS = (
    ("scaffold", ["tools/cardctl.py", "check", "--level", "scaffold"]),
    ("pins", ["tools/pin_seal.py", "--check"]),
    ("design-tokens", ["tools/design_tokens.py", "check"]),
    ("fool-materials", ["tools/production.py", "check-fool-materials"]),
    ("fool-cards", ["tools/production.py", "check-fool-cards"]),
    ("suite", ["-m", "unittest", "discover", "-s", "tests"]),
)


def main(argv=None):
    parser = argparse.ArgumentParser(description="fresh checkout 自证检查")
    parser.add_argument("--list", action="store_true", help="只列出步骤，不执行")
    parser.add_argument("--root", default=str(ROOT), help="仓库根（默认当前工具所在仓库）")
    args = parser.parse_args(argv)

    if args.list:
        for name, command in STEPS:
            print(f"{name}: python3 {' '.join(command)}")
        return 0

    root = Path(args.root).resolve()
    if not (root / "tools" / "cardctl.py").is_file():
        print(f"自证失败：{root} 不是本仓库根（缺 tools/cardctl.py）", file=sys.stderr)
        return 2

    failures = []
    for name, command in STEPS:
        proc = subprocess.run([sys.executable, *command], cwd=root, capture_output=True, text=True)
        print(f"[{'ok' if proc.returncode == 0 else 'FAILED rc=' + str(proc.returncode)}] {name}")
        if proc.returncode != 0:
            failures.append((name, proc))

    if failures:
        for name, proc in failures:
            print(f"--- {name} 输出 ---", file=sys.stderr)
            print(proc.stdout[-4000:], file=sys.stderr)
            print(proc.stderr[-4000:], file=sys.stderr)
        print(f"自证失败：{len(failures)}/{len(STEPS)} 步未通过", file=sys.stderr)
        return 1

    print(f"自证通过：{len(STEPS)}/{len(STEPS)} 步")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
