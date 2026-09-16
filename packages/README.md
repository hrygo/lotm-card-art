# packages/ — 引擎层契约占位（未实现）

> 状态：**占位**。本目录当前只有本文件，**没有任何实现代码**。
> 依据 [`docs/architecture/layering.md`](../docs/architecture/layering.md) 与 [`docs/decisions/ADR-006-docs-first-layering-no-physical-migration.md`](../docs/decisions/ADR-006-docs-first-layering-no-physical-migration.md)。

## 这一层是什么

《诡秘世界》的产品目标（见 [`docs/product/secret-world-prd-v1.0.md`](../docs/product/secret-world-prd-v1.0.md)，立项级产品基线）是**单人持续世界演绎应用**，包含 World / Character / Story / Audio 引擎与持久世界、Story Book。该产品本体归属仓库 `hrygo/WorldofMysteries`（见 `docs/DECISIONS.md` D24）；本目录只是**保留面占位**，不承接该产品的引擎实现。

本层与内容层解耦：卡牌内容生产是内容层的职责，引擎通过 Content Pack 消费内容，不把具体设定硬编码进引擎。按母 PRD §25，引擎实现不与卡牌美术仓库耦合。

## 硬契约

1. **IP 中性**：`packages/**` 不得出现《诡秘之主》专有名词、角色名、途径名或任何受版权保护的具体设定；具体内容经 Content Pack 从内容层注入。
2. **不依赖内容层与内容工艺层**：不得引用 `pathways/`、`catalog/`、`sources/`、`design/`、`config/`、`schemas/`、`templates/`、`examples/`、`prompts/`。
3. **不依赖制造层**：不得引用 `production/`、`tools/`、`artifacts/`、`generated/`、`reports/`、`references/`。
4. **不依赖应用层**：不得引用 `apps/`。依赖方向只能是应用层 → 引擎层，不能反向。
5. **契约先于实现**：先定义接口契约（如 Content Pack），再由内容层提供数据；不得为了让示例跑通而把内容硬编码进引擎。

## 诚实边界

- **本层边界当前未被机器强制**：没有层界检查脚本，也没有 CI 规则。本文件是**约定声明**，不是可执行的保证。
- 因此「引擎层无违规引用」目前是**空真**（因为本层没有任何文件）。首个引擎包落地时，须另开 ADR 评估是否以及如何工具化强制，并把门禁接入 `tools/selfcheck.py` 与 CI。
- 本目录的存在**不**表示引擎能力已实现，也**不**表示相关产品目标已排期或已批准。
- 本目录不持有事实源、不写卡牌数据、不记录批准。

## 变更方式

新增本层代码前，先在 `docs/architecture/layering.md` 与本文件确认边界，并在 ADR 中记录该层的首批接口契约；层或依赖规则的变更须先改 `layering.md`。
