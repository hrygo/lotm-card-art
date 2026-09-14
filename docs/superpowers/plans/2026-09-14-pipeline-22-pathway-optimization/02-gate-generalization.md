# 02 · 门禁参数化与目录命名空间

> **状态**：Agent 生成提案（非约束、非批准）。父文档：`00-master.md`。优先级 **P0**。依赖：`01`。

## Goal

把 `validate_fool_materials` / `validate_fool_cards` / `validate_fool_audio_package` 泛化为**按途径参数化**的门禁，去掉硬编码途径校验，并把 `production/symbols|tasks|templates|schemas|calls` 按途径命名空间化。

## 现状证据

| 位置 | 事实 |
|---|---|
| `production.py:288` | `contract.get("pathway_id") != "fool"` → 硬编码途径校验（carrier contract） |
| `production.py:576` | `catalog.get("pathway_id") != "fool"` → 五档 catalog 硬编码 |
| `production.py:620` | `layered.get("pathway_id") != "fool"` → 分层基线硬编码 |
| `production/` 文件面 | 295 个 `*.json`，**150 个**文件名含 fool（51%） |
| 分布 | symbols 18(12 fool) / tasks 33(18) / templates 10(3) / schemas 8(2) / compositions 5(5) / calls 34(18) / narratives 11(0) |
| 门禁函数 | `production.py` 42 个 def 中 6 个 fool 专属；其余为通用分层生产 |

## Must Do

- [ ] **T1 门禁参数化**：引入 `validate_pathway_materials(root, pathway_id)` 等入口，由途径合同解析（途径 id、资产根、映射、注册表）。保留 `validate_fool_*` 作为**薄包装**（避免一次性破坏现有调用与历史回执）。
- [ ] **T2 途径校验去硬编码**：`:288/:576/:620` 改为「合同声明的途径 == 调用方途径」，而不是「== fool」。
- [ ] **T3 目录命名空间**：`production/symbols/<pathway>/…`、`tasks/<pathway>/…`、`calls/<pathway>/…`、`templates/<pathway>/…`；`schemas/` 保留通用契约 + `pathway-*.schema.json` 家族（途径特定约束写进合同数据，而非新增 21 个 schema 文件）。
- [ ] **T4 兼容期**：提供**只读**的旧路径 → 新路径映射，使历史回执与 pin 在迁移期仍可解析；迁移完成后再删除映射（另开批次）。

## Must Not Do

- 不因为「21 条途径尚未制作」而放宽现有愚者门禁的任何断言。
- 不在本任务内迁移 `artifacts/**`（不可覆盖 provenance）。
- 不新增 21 份近乎相同的 schema 文件（那是把 DRY 问题搬个地方）。

## 验收标准

- [ ] 愚者门禁结果与 `v0.3.0` **完全一致**（`check-fool-materials` / `check-fool-cards` 输出逐字段可比）。
- [ ] 对「另一条途径」构造最小合同后，`validate_pathway_materials` 可运行并给出与该途径合同一致的结果。
- [ ] `python3 tools/cardctl.py check --level scaffold` → `errors: []`（迁移后仍成立）。
- [ ] 旧路径映射生效：历史 `calls/`、`tasks/` 与 pin 仍能被 `validate_task` 解析。

## 风险与回退

- **风险**：目录迁移波及 pin（249 条）→ **必须先完成 `03`**，否则每次迁移都要手工重封存。
- **风险**：命名空间迁移会移动大量文件，与并行写入者冲突概率高 → 建议单批次独占工作区。
- **回退**：保留 T4 兼容映射与薄包装，可整体回退到旧路径。

## 工作量估计

**中**（门禁参数化 + 目录迁移 + 兼容映射）；其中大部分风险来自迁移时的 pin 重封存，已由 `03` 化解。