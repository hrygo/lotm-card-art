# 06 · 验证覆盖、跨路径回归与快照纪律

> **状态**：Agent 生成提案（非约束、非批准）。父文档：`00-master.md`。优先级 **P1**。依赖：`01`。

## Goal

让验证**真的被执行**、跨路径**结果一致**、快照**不被误读为最新态**；并纠正本会话已发生的**误诊**，避免后人重复。

## 现状证据

| 事实 | 影响 |
|---|---|
| CI = `.github/workflows/ci.yml`：ubuntu-latest、Python 3.10–3.14，仅 `cardctl check --level scaffold` + `unittest discover` | 无 `swiftc` → 3 例渲染器测试 **skip** |
| 渲染器路径缺陷（`foolpipeline5.swift:252-255`） | 在 `/var/folders`（`$TMPDIR`）下 3 例**必失败**；在 `/Users/…` 下通过 |
| 组合结果 | **渲染器链路在 CI 与临时 worktree 中都没有有效覆盖**；本地主仓库绿 → 缺陷长期不可见 |
| 本会话误诊 | 我早前两次把该失败归因为「依赖 gitignore 的 `generated/`」——**错误**（输入 PNG 被跟踪，手工同一命令 `rc=0` 成功） |
| 快照纪律 | tag `v0.3.0` 后工作区又新增 6 张卡，但 tag 本身**不携带「在途内容」信息** |

## Must Do

- [x] **T1 跨路径回归**：`01-T1` 修复后，新增「符号链接根路径」反例测试（macOS `$TMPDIR` 场景），确保渲染器测试在任何 checkout 位置都绿。
- [x] **T2 CI 覆盖决策**：二选一，**不允许默默 skip**——
  - (a) 增加 macOS + `swiftc` 的 CI job，真正运行渲染器测试；或
  - (b) 在 CI 与文档中**显式登记**「原生渲染器不在 CI 覆盖内，属已知边界」，并给出本地必跑清单。
- [x] **T3 误诊更正登记**：在 `docs/DECISIONS.md` 或本目录记录「3 例渲染器失败 = 渲染器路径校验缺陷，**不是** `generated/` 缺失」，附实测矩阵与 `file:line`。
- [x] **T4 快照纪律**：打 tag 时附「**在途内容清单**」（未提交/在途的卡、研究稿、config 改动），避免 tag 被当作最新态；tag 名/说明需体现「快照而非发布」的语义。
- [x] **T5 fresh checkout 自证脚本**：把「clone 后能否自证」固化成一条命令（`scaffold` + `check-fool-materials` + `check-fool-cards` + 单测），作为打 tag 的前置检查。

## Must Not Do

- 不用「测试跳过」掩盖失败：修 01 前，3 例失败必须被理解为缺陷信号，而非环境噪声。
- 不把 macOS CI 的缺失当作「已经覆盖」。
- 不在本任务内改动渲染器语义（那是 01 的范围）。

## 验收标准

- [x] 在 `$TMPDIR` 下的 worktree 与主仓库运行同一套测试，**结果一致**（不再出现「位置决定绿红」）。
- [x] CI 对渲染器要么覆盖、要么显式豁免（有文字与出处），无静默 skip 的假绿。
- [x] 「3 例失败」的归因在仓库内有据可查（含更正记录）。
- [x] fresh checkout 自证一条命令可跑，输出可为 tag 前置门禁。
- [x] tag 说明/附带清单能区分「快照」与「发布」。

## 风险与回退

- **风险**：新增 macOS CI runner 有成本（时长/额度）。缓解 = 可用 (b) 过渡，但必须**显式**而非沉默。
- **风险**：T4/T5 属流程约定，容易被忽略；建议把自证脚本挂到现有门禁命令清单里（`AGENTS.md` 命令段）。

## 工作量估计

**小到中**：T1/T3/T5 小；T2 取决于 (a)/(b)；T4 是约定 + 一次 tag 说明更新。

## 实施记录（2026-09-15 回填）

- **T1（`2cc99fe`）**：输出路径校验改路径分量比较后，符号链接根路径不再误拒；正例/反例见 `tests/test_fool_agentic_pipeline.py::RendererTests.test_output_path_validation_is_escape_safe_and_symlink_agnostic`。
- **T2（`a78f282`）**：二选一取「覆盖」而非豁免——CI 新增 `macos-26` job，原生渲染用例在 macOS 上**必须真跑**（非 skip 强制断言），未使用显式豁免。
- **T3 归因（就地登记，因 `docs/DECISIONS.md` 由另一位写入者持有）**：早前 3 例渲染器失败 = **渲染器输出路径校验用字符串前缀且未统一规范化**，在符号链接根路径下被误拒；**不是** `generated/` 缺失（`generated/` 只是 `brief` 的派生输出目录）。证据：修复提交 `2cc99fe`、上述反例用例，以及 2026-09-15 在 `/var/folders/.../T/opencode/lotm-sym-check`（`pwd -P` → `/private/var/...`）worktree 下全套件 **OK (skipped=6)**。
- **T4（`57c158a`）**：`docs/workflow.md` 增 tag 快照纪律（tag 附「在途内容清单」，语义为快照而非发布）。
- **T5（`0948769`）**：`tools/selfcheck.py` 一条命令自证（scaffold → pins → 愚者门禁 → 全套件），登记于 `tools/AGENTS.md`；实测 fresh checkout **5/5** 通过。
