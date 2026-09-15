# 03 · 契约 pin 单一来源与 `seal` 生成器

> **状态**：Agent 生成提案（非约束、非批准）。父文档：`00-master.md`。优先级 **P1（运营层最紧迫）**。无前置依赖。

## Goal

把 **249 条手工维护的契约 pin** 变成「**单一来源清单 + 一条生成命令**」，使共享配置改一次即可机械地完成全部重封存；并让漂移在 CI 中可被捕获。

## 现状证据

| 事实 | 数值 |
|---|---|
| 含 `contracts` 的合同文件 | **23** |
| `contracts` 条目总数 | **249** |
| 单文件最高重复 pin | **15×**（`docs/production-sop-v3.md`、`config/quality-color-tokens.json`） |
| 次高 | `docs/production-preflight.md` 14×、`config/production-resolution-policy.json` 9×、`config/sequence-hierarchy.json` 8× |
| 本会话实际代价 | 因改 `fool-five-tier-kit.json` / `quality-color-tokens.json` / 渲染器，**手工重封存 3 轮**（每轮 3 份任务合同） |
| pin 语义 | `{"path": …, "sha256": …}`；由 `production.py:verify_records` 校验「文件存在且哈希一致」 |

**结论**：pin 机制本身是好的跨文件一致性证据，问题在**维护方式**。22 途径会让「一次配置改动 → 手工改 15+ 处」放大成不可维护。

## Must Do

- [x] **T1 定义 pin 源清单（单一来源）**：声明「哪些文件属于哪一类契约输入、是否必须被 pin」。类别至少包含：规范文档（sop-v3、preflight）、共享配置（sequence-hierarchy、quality-color-tokens、resolution-policy）、编辑器契约（schemas）、接口模板（templates）、途径资产合同（symbols/<pathway>/…）。
- [x] **T2 生成命令**：`python3 tools/production.py seal --write`（名称可议）——只重写各合同里的 `contracts` 段，其余字段**逐字节不动**；输出必须确定性（排序稳定，便于 diff）。
- [x] **T3 校验模式**：`seal --check` 在 CI 中 fail-on-drift，取代「靠人记得手工改」。
- [x] **T4 语义不变**：`verify_records` 的校验逻辑不动（仍校验存在 + 哈希）；生成器**不得**削弱任何校验。
- [x] **T5 一次性对齐**：对现存 249 条做一次 migration（只改 pin 值，不改语义），单独成提交，便于审阅与回退。

## Must Not Do

- 不删除 pin（pin 是跨文件一致性证据，不是噪声）。
- 不把生成器做成「自动忽略找不到的文件」——文件缺失必须是**错误**，不是跳过。
- 不在本任务内改变任何被 pin 文件的内容（生成器只读过、只写合同）。

## 验收标准

- [x] 改动 `config/quality-color-tokens.json` 后，**一条命令**完成全部重封存，`validate_task` 全绿。
- [x] 人为篡改某合同里的一条 pin → `seal --check` **失败**并指出具体 path。
- [x] `seal --write` 幂等：连续执行两次，第二次无 diff。
- [x] 生成前后，所有合同的非 `contracts` 字段**逐字节一致**。

## 风险与回退

- **风险**：生成器成为新的真相源。缓解 = 生成器只读源文件 + 确定性输出 + 幂等性测试；它永远不判断「该不该 pin」以外的语义。
- **风险**：与并行写入者冲突（合同文件是其活跃区）→ 单独批次独占。
- **回退**：`seal` 只改 pin 段，`git revert` 单个提交即可回到手工状态。

## 工作量估计

**小到中**（一个命令 + CI 校验 + 一次 migration）；收益是后续所有迁移工作流的成本基数。

## 实施记录（2026-09-15 回填）

- **T1–T4（`866b97e`）**：`tools/pin_seal.py` 提供单点重封存（`--write` / `--check`），只改 `sha256` 字节、按 path 稳定排序、幂等；CI 增 pin 漂移检查。生成器不削弱 `verify_records` 语义（仍校验存在 + 哈希）。
- **口径更正（ADR-005）**：活合同 pin 实测 **113 条**；计划所记「249 条」是含 `artifacts/**` 历史回执的口径，那部分无重封存意义（按其 provenance 语义排除）。
- **验收**：改共享配置后一条命令完成重封存且 `validate_task` 全绿；篡改 `pathway_crown.rect_design[0]` → `--check` rc=1 并点名 path 与新/旧哈希；连续两次 `--write` 无 diff；重封存前后非 `sha256` 字段逐字节不变。
