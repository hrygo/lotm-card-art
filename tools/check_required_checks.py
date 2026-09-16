#!/usr/bin/env python3
"""必需检查名契约守卫。

分支保护按『检查名』匹配：一旦有人改了 workflow 里 job 的 `name`，已配置的必需检查
就永远等不到结果，PR 会永久卡在 pending —— 这比检查失败更难排查。

本脚本把必需检查名当成公开接口来守护：解析 `.github/workflows/*.yml` 里每个 job 实际
暴露的检查名，断言 `.github/required-checks.json` 声明的名字都存在；同时拒绝把
`${{ matrix.* }}` 这类插值名当作必需检查（矩阵展开后会变成多个名字）。

只读、零第三方依赖：不引入 PyYAML，按缩进扫描 job 块。Python 3.10+。
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Dict, List, Tuple


REPO_ROOT = Path(__file__).resolve().parents[1]
CONTRACT_RELATIVE_PATH = Path(".github") / "required-checks.json"
WORKFLOWS_RELATIVE_PATH = Path(".github") / "workflows"

JOB_KEY_RE = re.compile(r"^ {2}([A-Za-z0-9_.\-]+):[ \t]*(?:#.*)?$")
NAME_RE = re.compile(r"^ {4}name:[ \t]*(\S.*?)[ \t]*$")
INTERPOLATION_RE = re.compile(r"\$\{\{")


def _normalize(raw: str) -> str:
    """去掉 YAML 引号与行尾注释，得到 GitHub 实际使用的检查名。"""
    value = raw.strip()
    if value[:1] in ("'", '"'):
        quote = value[0]
        end = value.find(quote, 1)
        return value[1:end].strip() if end > 0 else value[1:].strip()
    hash_index = value.find(" #")
    if hash_index >= 0:
        value = value[:hash_index]
    return value.strip()


def job_check_names(workflow_path: Path) -> Dict[str, str]:
    """返回 {job_id: 暴露的检查名}。job 未显式声明 name 时，GitHub 以 job_id 作为检查名。"""
    lines = workflow_path.read_text(encoding="utf-8").splitlines()
    try:
        start = next(i for i, line in enumerate(lines) if line.rstrip() == "jobs:")
    except StopIteration:
        return {}

    names: Dict[str, str] = {}
    current_job: str | None = None
    seen_name: set[str] = set()
    for line in lines[start + 1 :]:
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if not line.startswith(" "):
            break  # 离开 jobs 块
        job_match = JOB_KEY_RE.match(line)
        if job_match:
            current_job = job_match.group(1)
            names.setdefault(current_job, current_job)
            continue
        if current_job and current_job not in seen_name:
            name_match = NAME_RE.match(line)
            if name_match:
                raw = _normalize(name_match.group(1))
                if raw:
                    names[current_job] = raw
                    seen_name.add(current_job)
    return names


def exposed_check_names(repo_root: Path = REPO_ROOT) -> Dict[str, List[str]]:
    """返回 {检查名: [「workflow 相对路径:job_id」...]}。"""
    exposed: Dict[str, List[str]] = {}
    workflows_dir = repo_root / WORKFLOWS_RELATIVE_PATH
    if not workflows_dir.is_dir():
        return exposed
    for workflow in sorted(workflows_dir.glob("*.y*ml")):
        for job_id, check_name in job_check_names(workflow).items():
            exposed.setdefault(check_name, []).append(
                f"{workflow.relative_to(repo_root).as_posix()}:{job_id}"
            )
    return exposed


def audit(repo_root: Path = REPO_ROOT) -> Tuple[List[str], Dict[str, List[str]]]:
    """断言契约成立的检查名都能在 workflow 里找到。返回 (问题列表, 现有检查名)。"""
    contract_path = repo_root / CONTRACT_RELATIVE_PATH
    if not contract_path.is_file():
        return [f"缺少必需检查契约文件：{CONTRACT_RELATIVE_PATH.as_posix()}"], {}
    try:
        contract = json.loads(contract_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        return [f"契约不是合法 JSON：{exc}"], {}
    if not isinstance(contract, dict):
        return ["契约根节点必须是对象"], {}

    checks = contract.get("checks")
    if not isinstance(checks, list) or not checks:
        return ["契约里的 checks 必须是非空数组"], {}

    exposed = exposed_check_names(repo_root)
    problems: List[str] = []
    if not exposed:
        problems.append(f"{WORKFLOWS_RELATIVE_PATH.as_posix()}/ 下没有可解析的 job，契约无法被证明成立")

    for entry in checks:
        if not isinstance(entry, dict):
            problems.append("checks 里的条目必须是对象")
            continue
        context = str(entry.get("context", "")).strip()
        workflow_rel = str(entry.get("workflow", "")).strip()
        if not context:
            problems.append("checks 里存在空的 context")
            continue
        if INTERPOLATION_RE.search(context):
            problems.append(
                f"必需检查名不得包含 ${{{{ }}}} 表达式（矩阵展开会改名，保护会永久 pending）：{context}"
            )
            continue
        origins = exposed.get(context)
        if not origins:
            known = "、".join(sorted(exposed)) or "（无）"
            problems.append(f"契约声明的检查名在 workflow 里不存在：{context}（现有检查名：{known}）")
            continue
        if workflow_rel:
            actual = {origin.split(":", 1)[0] for origin in origins}
            if workflow_rel not in actual:
                problems.append(
                    f"检查名 {context} 实际出现在 {'、'.join(sorted(actual))}，与契约声明的 {workflow_rel} 不一致"
                )
    return problems, exposed


def main(argv: List[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="必需检查名契约守卫（只读）")
    parser.add_argument("--root", default=str(REPO_ROOT), help="仓库根（默认本工具所在仓库）")
    args = parser.parse_args(argv)

    problems, exposed = audit(Path(args.root).resolve())
    for name in sorted(exposed):
        print(f"workflow 暴露的检查名：{name}  <-  {'、'.join(exposed[name])}")
    if problems:
        for problem in problems:
            print(f"❌ {problem}", file=sys.stderr)
        print(
            f"必需检查契约不成立：{len(problems)} 个问题。"
            "若确实要改必需检查名，请同步更新分支保护 ruleset，否则 PR 会永久 pending。",
            file=sys.stderr,
        )
        return 1
    print(f"✅ 必需检查契约成立：{len(exposed)} 个检查名，契约声明全部存在")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
