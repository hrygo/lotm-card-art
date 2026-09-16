# 卡牌制作工具 · 分层与依赖方向

> 状态：**约定（当前未机器强制）**。依据 [ADR-006](../decisions/ADR-006-docs-first-layering-no-physical-migration.md)。
> 本文件是分层规则的**单一说明**；`docs/` 其他文档与根 `AGENTS.md` 只引用、不重复定义。

## 为什么有分层

本仓库是《诡秘之主》成神途径序列卡牌的**制作工具**，职责主线是内容生产面（序列卡研究与制作）。

另有两个**保留面**在本仓库暂存：客户端面（macOS 26 原生画册，M1 垂直切片 + M2 世界外壳）与引擎层（World / Character / Story / Audio、持久世界、Story Book，尚未实现）。两者归属《诡秘世界》产品（`hrygo/WorldofMysteries`），在本仓库暂存、不再扩写（见 `docs/DECISIONS.md` D24）。

分层的作用是让「新增文件该放哪、谁可以依赖谁、改动会波及谁」有唯一答案。

## 层与目录归属（覆盖全部顶层目录）

| 层 | 目录 | 职责 | 允许依赖 |
|---|---|---|---|
| **引擎层**（占位·未实现） | `packages/` | 未来 IP 中性引擎与 Content Pack 契约 | 仅标准库/第三方；**不得**依赖内容、工艺、制造、应用层 |
| **内容层**（事实源） | `pathways/`、`catalog/`、`sources/` | 卡牌六维事实、22 途径索引、来源登记与访问状态 | 无（只被依赖） |
| **内容工艺层** | `design/`、`config/`、`schemas/`、`templates/`、`examples/`、`prompts/` | 六维转译与美术总纲、交付规格、结构约束、任务模板、示例模式、提示词模板 | 内容层 |
| **制造层** | `production/`、`tools/`、`artifacts/`、`generated/`、`reports/`、`references/` | 分层生产记录、确定性合成、产物与**不可覆盖 provenance**、派生报告、参考资料登记 | 内容层、内容工艺层 |
| **应用层**（保留面·归属《诡秘世界》） | `apps/` | macOS 26 原生画册客户端（SwiftUI） | 引擎层（经契约）；**不得**直接读内容层原始文件 |
| **文档层** | `docs/`、根与其他目录的 `AGENTS.md` | 规范、策略、决策、审查、研究、计划、产品基线 | 只读描述；**不持有事实源** |
| **仓库元数据** | `.github/`、`.agents/`、`README.md`、`LICENSE-*.md`、`NOTICE.md`、`CONTRIBUTING.md`、`SECURITY.md`、`CODE_OF_CONDUCT.md`、`SUPPORT.md`、`.editorconfig`、`.gitignore` | CI 与模板、Agent 技能、入口与法律/社区文件 | — |

> `examples/` 存放内容工艺的模式参考（如方向研究示例、六维转译模式），`prompts/` 存放研究/美术/审核提示词模板；二者服务内容生产，**不含事实源**。

## 依赖方向（硬规则）

1. **只允许下游依赖上游**：引擎层不被内容层依赖；内容层不依赖任何代码层；工艺层依赖内容层；制造层依赖内容层与工艺层；应用层经契约依赖引擎层。
2. **应用层不得直接读取内容层原始文件**：`apps/**` 不引用 `pathways/`、`catalog/`、`sources/`。客户端当前使用**合成 fixture**；打包期由 `tools/production.py stage-app-resources` 从 `artifacts/**` 取图与音频。
3. **引擎层不得依赖内容/工艺/制造/应用层**：`packages/**` 不引用 `pathways|catalog|sources|design|config|schemas|templates|production|tools|artifacts|generated|reports|apps`，也不得出现 IP 专有名词（IP 中性）。
4. **文档层不建第二份事实源**：序列、配方、晋升、限制写 `pathways/*/canon.json` 与 `card.json`，来源状态写 `sources/registry.json`，层级标签读 `config/sequence-hierarchy.json`。

## 当前状态与边界（诚实声明）

- **未机器强制**：本次**没有**新增层界检查脚本。上述规则靠评审与人工维护，绿色门禁不代表层界已被验证。待首个引擎包落地时另开 ADR 评估工具化。
- **`packages/` 为空占位**：仅 `README.md` 声明契约。因此「引擎层无违规引用」当前是**空真**，不构成已达成目标。
- **已知豁免（保留原文，不回写）**：`docs/research/**`、`docs/reviews/**`、`docs/superpowers/**`、`docs/decisions/ADR-004*`、`docs/product/**` 为历史文档或产品基线原文，其路径与表述保持原样。
- **未处理的既有债**：`artifacts/**` 的 52 份 `snapshot.json` 共 367 条 `dependencies[]` 中有 **76 条指向不存在路径**（详见 ADR-006 Context 5）。这是先于本分层存在的独立技术债，本文件不声称已解决。

## 变更方式

- 层归属、目录位置或依赖规则的变更：**先改本文件**，再在 `docs/DECISIONS.md` 或新 ADR 记录。
- **物理移动顶层目录属高风险变更**：必须先满足 ADR-006 Decision 6 的 a–f 全部前置条件（批准摘要与路径解耦、开放闭合 schema、处置 snapshot 依赖、门禁接入、git 基线与还原演练、同步范围含 `tests/**` 与 `.github/**`）。
