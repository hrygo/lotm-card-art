"""Required-check name contract tests: literal names, rename detection, negative cases."""

import io
import json
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import check_required_checks


WORKFLOW = """name: CI

on:
  push:
    branches: [main]

jobs:
  test:
    name: Toolchain (Python ${{ matrix.python-version }}) · macOS
    runs-on: macos-26
    steps:
      - name: Check scaffold
        run: echo scaffold
        with:
          name: not-a-job-name
  native:
    runs-on: macos-26
    steps:
      - run: echo native
  gate:
    name: All Quality Gates Passed
    runs-on: macos-26
    steps:
      - run: echo gate
"""


class SyntheticRepositoryTests(unittest.TestCase):
    def make_tree(self, workflow_text: str = WORKFLOW, contract: dict | None = None) -> Path:
        holder = tempfile.TemporaryDirectory()
        self.addCleanup(holder.cleanup)
        root = Path(holder.name)
        (root / ".github/workflows").mkdir(parents=True)
        (root / ".github/workflows/ci.yml").write_text(workflow_text, encoding="utf-8")
        payload = contract if contract is not None else {
            "version": 1,
            "ruleset": "main-protection",
            "checks": [
                {"context": "All Quality Gates Passed", "workflow": ".github/workflows/ci.yml", "required": True}
            ],
        }
        (root / ".github/required-checks.json").write_text(
            json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
        return root

    def test_contract_holds_for_literal_job_name(self):
        problems, exposed = check_required_checks.audit(self.make_tree())
        self.assertEqual(problems, [])
        self.assertIn("All Quality Gates Passed", exposed)

    def test_job_without_name_falls_back_to_job_id(self):
        exposed = check_required_checks.exposed_check_names(self.make_tree())
        self.assertIn("native", exposed)
        self.assertEqual(exposed["native"], [".github/workflows/ci.yml:native"])

    def test_step_level_name_does_not_override_job_name(self):
        exposed = check_required_checks.exposed_check_names(self.make_tree())
        self.assertIn("Toolchain (Python ${{ matrix.python-version }}) · macOS", exposed)
        self.assertNotIn("not-a-job-name", exposed)
        self.assertNotIn("Check scaffold", exposed)

    def test_renaming_required_job_fails_the_guard(self):
        renamed = WORKFLOW.replace("name: All Quality Gates Passed", "name: Quality Gate")
        problems, _ = check_required_checks.audit(self.make_tree(workflow_text=renamed))
        self.assertEqual(len(problems), 1)
        self.assertIn("All Quality Gates Passed", problems[0])
        self.assertIn("Quality Gate", problems[0])

    def test_matrix_interpolated_name_is_rejected_as_required_check(self):
        contract = {
            "checks": [
                {"context": "Toolchain (Python ${{ matrix.python-version }}) · macOS", "workflow": ".github/workflows/ci.yml"}
            ]
        }
        problems, _ = check_required_checks.audit(self.make_tree(contract=contract))
        self.assertEqual(len(problems), 1)
        self.assertIn("矩阵展开会改名", problems[0])

    def test_contract_pointing_at_the_wrong_workflow_is_rejected(self):
        contract = {"checks": [{"context": "All Quality Gates Passed", "workflow": ".github/workflows/other.yml"}]}
        problems, _ = check_required_checks.audit(self.make_tree(contract=contract))
        self.assertEqual(len(problems), 1)
        self.assertIn("other.yml", problems[0])

    def test_missing_contract_file_is_reported(self):
        root = self.make_tree()
        (root / ".github/required-checks.json").unlink()
        problems, _ = check_required_checks.audit(root)
        self.assertEqual(problems, ["缺少必需检查契约文件：.github/required-checks.json"])

    def test_empty_checks_array_is_reported(self):
        problems, _ = check_required_checks.audit(self.make_tree(contract={"checks": []}))
        self.assertEqual(problems, ["契约里的 checks 必须是非空数组"])

    def test_invalid_json_is_reported(self):
        root = self.make_tree()
        (root / ".github/required-checks.json").write_text("{not json}\n", encoding="utf-8")
        problems, _ = check_required_checks.audit(root)
        self.assertEqual(len(problems), 1)
        self.assertIn("不是合法 JSON", problems[0])

    def test_workflow_without_jobs_block_exposes_nothing(self):
        root = self.make_tree(workflow_text="name: CI\non:\n  push:\n")
        problems, exposed = check_required_checks.audit(root)
        self.assertEqual(exposed, {})
        self.assertEqual(len(problems), 2)
        self.assertTrue(any("没有可解析的 job" in problem for problem in problems))

    def test_main_exit_codes_and_output(self):
        root = self.make_tree()
        out = io.StringIO()
        with redirect_stdout(out):
            self.assertEqual(check_required_checks.main(["--root", str(root)]), 0)
        self.assertIn("必需检查契约成立", out.getvalue())

        broken = self.make_tree(contract={"checks": [{"context": "Nope"}]})
        err = io.StringIO()
        with redirect_stdout(io.StringIO()), redirect_stderr(err):
            self.assertEqual(check_required_checks.main(["--root", str(broken)]), 1)
        self.assertIn("必需检查契约不成立", err.getvalue())


class LiveRepositoryTests(unittest.TestCase):
    """本仓库自身的契约必须成立：CI 与分支保护依赖这个断言。"""

    def test_this_repository_contract_holds(self):
        problems, exposed = check_required_checks.audit(ROOT)
        self.assertEqual(problems, [])
        self.assertIn("All Quality Gates Passed", exposed)

    def test_required_check_name_is_free_of_matrix_interpolation(self):
        contract = json.loads((ROOT / ".github/required-checks.json").read_text(encoding="utf-8"))
        for entry in contract["checks"]:
            self.assertNotIn("${{", entry["context"])


if __name__ == "__main__":
    unittest.main()
