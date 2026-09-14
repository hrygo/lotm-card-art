# AGENTS.md — docs/ 文档目录 · 规则地图与效力层级

> 子目录作用域：只管 `docs/`。根 `AGENTS.md` 的全局契约与路由优先；事实源在 `pathways/`、`config/`、`sources/`，不在本目录。

## 概览 OVERVIEW
`docs/` 是流程、策略、决策、审查、研究与计划的**文档层**，不是数据层，也不是批准层。
- 核心分别是**效力**：规范性当前合同 ＞ 执行性侧车/检查表 ＞ 决策记录 ＞ 历史/被取代 ＞ Agent 生成的计划·规格·研究草稿。
- 文档只回答“应该怎么做 / 曾经怎么判断”；断言、卡状态、批准分别在 `pathways/*/canon.json`、`sequences/*/card.json`、`sources/registry.json`、`config/`。
- 读取任何文件先看头部：版本、状态字段（如 Accepted/Proposed、`material-prep/no-production`）、适用范围；文内状态优先于目录位置和文件名。

## 查哪里 WHERE TO LOOK
| 任务 | 文件 | 效力 |
|---|---|---|
| 阶段流转、最小上下文、失败处理 | `workflow.md` | 规范·当前 |
| 证据等级、否定/缺口、引用边界 | `source-policy.md` | 规范·当前 |
| 当前分层生产流程 | `production-sop-v3.md` | 规范·当前生产入口（v3.5.0） |
| 开工范围、工具能力预检、逐项准入 | `production-preflight.md` | 执行约定·当前（非自动批准机制） |
| 载体、EmblemDock 接口、品质细目 | `pathway-carrier-sop.md` | 侧车细则·当前（不重复主流程） |
| 问候/口头语/故事/声音合同 | `card-narrative-contract.md` | 规范·当前（v1.0.0，独立于图像批准） |
| 制作文档总索引 | `card-production-index.md` | 索引（入口维护，非规则） |
| 制作上手顺序 | `START-HERE.md` | 指南（非规范） |
| 架构决策 | `DECISIONS.md` + `decisions/ADR-*.md` | 决策记录；逐份读 `Status`（ADR-002 仍 Proposed，ADR-003 取代其部分生产假设） |
| 项目边界与未执行事项 | `LIMITATIONS.md` | 边界声明（当前诚实边界） |
| SOP/Skill 审查结论 | `reviews/*.md` | 记录（非批准、非发布结论） |
| 单卡/途径研究、资料包 | `research/*.md` | 草稿（非 canon；逐份读状态） |
| 实施计划与设计规格 | `superpowers/plans/*`、`superpowers/specs/*` | Agent 生成提案（待审阅/待执行，非约束） |
| 方法与来源入口 | `REFERENCES.md` | 研究入口（非已核验；访问状态以 `sources/registry.json` 为准） |
| logo、UI 截图 | `assets/` | 视觉资产（非卡面、非事实） |
| 旧流程（禁止按其实施） | `production-sop-v2.md`（历史五档）、`production-sop.md`（旧工具合同 v1） | 历史·被取代（仅追溯） |

## 约定 CONVENTIONS
- 效力顺序：当前规范 → 当前侧车/检查表 → ADR（按 `Status`）→ 历史文档 → 计划/规格/研究草稿。低效力不得覆盖高效力，目录新旧不代表效力。
- docs/ 不持有单一事实源：序列、配方、晋升、限制写入 `pathways/*/canon.json` 与 `card.json`，来源状态写 `sources/registry.json`，层级标签读 `config/sequence-hierarchy.json`；文档不复写第二份。
- 研究稿中的 `lead`/`knowledge_gap` 不因被引用或重复出现而升级；`verified` 必须有核验者、时间与可复核位置。
- 规则变更：先改对应规范文件，再在 `DECISIONS.md`/新 ADR 记录；ADR 注明 `Status` 与被取代关系。
- 历史文档保留原文，不删改、不回写摘要；新流程不回填旧文件结论。
- 引用克制：不放原著长摘录；来源访问范围如实登记。
- `research/`、`reviews/`、`superpowers/` 采用日期前缀命名，仅表示时序，不表示批准。

## 反模式 ANTI-PATTERNS
- 把 `superpowers/plans`、`superpowers/specs`、`research/` 草稿当 canon、当批准或当已核验事实；计划勾选 ≠ 交付完成。
- 按 `production-sop-v2.md`/`production-sop.md` 的旧四档、旧合成器字段实施当前生产。
- 把 `reviews/` 的“整改完成”当作视觉通过或 release 通过；把 `LIMITATIONS.md`/`REFERENCES.md` 条目当作“已取得原文/已完成核验”。
- 在 docs/ 新建事实数据、批准记录或第二份色表/层级表，绕过 `card.json`/`canon.json`。
- 用 `assets/` 图片或计划文件完成度推断项目状态。

## 状态 STATUS
- 规范·当前：`workflow.md`、`source-policy.md`、`production-sop-v3.md`、`card-narrative-contract.md`。
- 执行/侧车·当前：`production-preflight.md`、`pathway-carrier-sop.md`、`card-production-index.md`。
- 决策：`DECISIONS.md` 与 `decisions/ADR-*`（Accepted/Proposed 并存，按 `Status` 使用）。
- 历史·被取代：`production-sop-v2.md`、`production-sop.md`。
- Agent 生成·非约束：`superpowers/plans/*`、`superpowers/specs/*`、`research/*`、`reviews/*`。