# 《诡秘世界》单仓库布局与分层治理 · 设计规格

> **状态**：Proposed（待用户评审）
> **日期**：2026-09-15
> **依据**：`docs/product/secret-world-prd-v1.0.md`（产品基线·立项级）；用户裁决「《诡秘世界》采用单仓库架构」+「采纳追加式精简方案」
> **效力**：本文件是**设计规格**（`docs/AGENTS.md` 定义的 Agent 生成·非约束层）。实施完成后，规范效力由新 ADR 承接。

---

## 1. 问题陈述

| 问题 | 证据 |
|---|---|
| P1 仓库自我定位失准 | `README.md` 标题与核心目标以「220 张成神途径卡牌制作脚手架」自居；根 `AGENTS.md` 把 PRD 写成「未来产品基线（不是交付面）」的脚注。用户裁决产品已为《诡秘世界》单仓库，卡片制作只是其中一部分。 |
| P2 无法表达「引擎层」 | 现有顶层目录没有 IP 中性引擎代码的位置；PRD §25 要求引擎与 IP 内容解耦。 |
| P3 结构债随内容量单调增长 | 现状：**113 条封存 pin**（`production/**` 的 `contracts[]`，可被 `pin_seal` 重封存）+ **91 条门禁校验的 `references[]`**（全部指向 `artifacts/**`，**不被**重封存，只能手改）+ 约 170 处工具路径字面量。此外 `verify_records` 在 **16+ 个调用点**校验 `contracts`、`references`、`evidenceRefs`、`dependencies`、`receipts`、`vector_assets` 等记录类型的 `path + sha256`——**真实校验面大于 pin 数**。目前仅 `fool` 途径做深；余 21 途径 × 10 序列铺开后，批准链与引用将线性增长。 |
| P4 搬迁的历史税即将归零 | 用户决定清空 git（本地 + GitHub）→ 重排不再产生「历史碎片化」代价。这是长期成本最低的唯一窗口。 |

## 2. 目标与非目标

**目标**
- G1 顶层身份改为《诡秘世界》产品；本仓库为其**单仓库**，卡片制作为其中一层。
- G2 建立可被**机器强制**的层界：引擎层不得依赖内容层。
- G3 把完整性模型从「路径为主键」演进为「内容寻址」，使**未来的搬迁零成本**。
- G4 迁移**可证明**（内容不变式 + 全门禁），而非「小心操作」。
- G5 历史清空后，「可追溯」仍有明确落点。

**非目标（本次不做）**
- N1 不搬 `docs/`、`production/`、`config/`、`artifacts/`（省 83/113 条 pin 与 46 条 references 的高风险改写；`artifacts/` 另有「不迁移」条款）。
- N2 不引入 Git LFS / 内容寻址存储（**延后**：LFS 迁移是路径保持的，将来做不需要搬文件）。
- N3 不改稳定标识：内容 ID `lotm.*`、`production/schemas/*.json` 的 `$id` 值、技能名 `lotm-*`、小说/IP 引用（依 D18）。
- N4 不实现引擎功能（CHARACTER/STORY/AUDIO 引擎仍属未来；本次只定义层界与协议占位）。
- N5 不回写历史文档：`docs/research/**`、`docs/reviews/**`、`docs/superpowers/**`（既有）、`docs/decisions/ADR-004`、`docs/product/secret-world-prd-v1.0.md` 一律保留原文与旧路径（追加式，依 `docs/AGENTS.md`）。
- N6 不改既有卡片契约、卡数口径、批准状态与 `release_approved: false`。

## 3. 目标布局

```text
world-of-mysteries/
├── apps/                     # 应用层：可交付的外壳（现为 macOS 客户端）
│   └── WorldOfMysteries/     #   SwiftPM：Core / Features / App（不动）
├── packages/                 # 引擎层（★新增）：IP 中性，不含任何原著内容
│   ├── README.md             #   层规则与依赖方向声明
│   └── (engine-types/ engine-core/ …) #   未来实现时新增，本次仅占位与协议草案
├── content/                  # 内容层（★新增）：IP 特定 canon
│   ├── pathways/             #   ← pathways/（22 途径 canon/direction/序列卡）
│   ├── catalog/              #   ← catalog/（22 途径工作 ID 索引）
│   └── sources/              #   ← sources/（来源登记 registry.json）
├── production/               # 内容制造系统（原位）：tasks/calls/compositions/schemas/approvals
├── artifacts/                # 不可覆盖 provenance（原位，禁迁移）
├── docs/                     # 文档层（原位）：product/ design/ decisions/ research/ plans/ specs/
├── design/ config/ tools/ tests/ schemas/ templates/ generated/ reports/ references/  # 原位
└── .agents/skills/           # Agent 技能（原位）
```

**为什么是这三层可见化**：`content/` 与 `production/` 构成有意义的「**what vs how**」seam（canon 事实 vs 制造系统）；`packages/` 是 PRD §25 要求的引擎归属。`docs/`、`config/`、`production/`、`artifacts/` 本身已是单一职责、无歧义的目录，搬动不增加可维护性，只增加一次性出错概率。

## 4. 分层与依赖方向（唯一硬规则）

| 层 | 目录 | 允许依赖 | 禁止依赖 |
|---|---|---|---|
| 引擎层 | `packages/**` | `packages/**`、语言标准库 | **`content/`、`production/`、`artifacts/`、`apps/`、`design/`** |
| 内容层 | `content/**` | —（纯数据） | 一切代码目录 |
| 内容工艺层 | `design/**`、各层 `AGENTS.md` 与规范 | —（规范性文本） | 作为任何代码的运行时输入 |
| 制造层 | `production/**`、`tools/**` | 内容层、内容工艺层、文档层、自身 | — |
| 应用层 | `apps/**` | 引擎层（经 Content Pack 协议）、标准库 | 直接读取 `content/` 原始文件（应经协议/内容包产物） |
| 文档层 | `docs/**` | — | 作为任何代码的运行时输入 |

依赖方向单向：`apps → packages → (协议) ← 内容包由 apps 侧装配`；`tools/production → content`。引擎层是**叶子**。

## 5. Content Pack 协议（结构性解耦，本次只定契约）

引擎只能看见协议，看不见 canon 内容；内容通过经审核的 Content Pack 注入。

```swift
// packages/engine-types（未来）：IP 中性，无原著名词
public protocol ContentPack: Sendable {
    var identifier: String { get }                 // 例："lotm-canon-v1"
    var pathwayIDs: [String] { get }               // 中性 ID 列表
    func pathway(_ id: String) -> PathwayDefinition?
    func sequenceCard(pathway: String, sequence: Int) -> SequenceCardDefinition?
}

public struct PathwayDefinition: Sendable { /* 通用字段，不含具体设定文本 */ }
public struct SequenceCardDefinition: Sendable { /* 由内容包填充 */ }
```

- 引擎层**不 import** 内容层；耦合点只有协议类型。
- 内容包的实现在应用装配处（`apps/**` 或未来独立的 pack 模块），负责把 `content/**` 的 canon 映射为协议类型。
- 本次交付：协议文件草案 + 边界门；**不实现**引擎逻辑。

## 6. 完整性模型演进：路径主键 → 内容寻址

**现状与缺陷**：`production/**` 的 `contracts[]` 为 `{path, sha256}`；`pin_seal.py --write` 只重写 `sha256`，被 pin 文件不存在即 `PinError` 中止 ⇒ **搬动路径无法通过重封存修复**，必须手改合同。

**目标形态**：

```json
{ "content_hash": "<sha256>", "path_at_seal_time": "content/pathways/fool/…", "role": "card-definition" }
```

- **主键是 `content_hash`**；`path_at_seal_time` 降级为可审计元数据，不再参与校验。
- 兼容策略：迁移期**双写**（保留 `path` + 新增 `content_hash`）；`pin_seal.py --check` 支持两种形态且判定等价；随后新条目可只写 `content_hash`。
- **必须同步改 `production.py`，这不是只改 `pin_seal.py`**：`verify_records(root, records)` 同时服务 `contracts[]`（第 1856 行）与 `references[]`（第 1855 行）及其余 14+ 个调用点，其实现为 `inside(root, item["path"])` + `sha(path) != item["sha256"]`——**对缺失 `path` 的条目会直接 `KeyError`**。因此：
  - `verify_records` 需支持「有 `path` 则按路径+哈希校验；仅有 `content_hash` 则跳过路径解析、只做存在性/哈希策略校验」；
  - 该分支必须配反例测试（缺 `path` 且缺 `content_hash`、仅有 `content_hash` 但内容不匹配等）。
- `path` 字段在只写 `content_hash` 的条目上变为可选；**`--check`/`--write` 的既有语义与退出码保持不变**。
- 反例测试同步扩充（依 `tools/AGENTS.md`「新增硬规则同步补反例测试」）。

**`references[]` 的特殊处理**：`production.py:1855` 的 `verify_records` 按 `path.is_file() + sha256` 校验 46 条指向 `artifacts/**` 的引用；而 `pin_seal.py` 按设计排除 `artifacts/**`。演进时必须**保持 references 的 path+sha256 校验语义不变**，不纳入内容寻址（其哈希记录的是产出当时状态，故意与今日可能不符）。

## 7. 机器边界门

- 新增 `tools/check_layers.py`（仅标准库，遵循 `tools/AGENTS.md`）：
  - 规则 R1：`packages/**` 内不得出现对 `content/`、`production/`、`artifacts/`、`apps/`、`design/` 的路径引用或 import。
  - 规则 R2：`content/**` 内不得出现可执行代码文件（仅数据与说明）。
  - 规则 R3：`apps/**` 不得直接引用 `content/**` 原始文件（须经协议/内容包）。
- 反例测试：`tests/test_layer_boundaries.py`（违规样例必须失败，合规样例必须通过）。
- 接入 `tools/selfcheck.py` 步骤序列，位于 `scaffold` 之后、pin 漂移之前；失败给明确非零退出码。
- 规则 R1–R3 的检查对象是**源码文本与路径引用**，不做语义分析；已知边界（不覆盖注释/字符串中的同名文本）在文件中声明。
- R3 现状已满足：客户端使用 Swift 内联 fixture，不读取 `content/**` 原始文件；该规则为**防回归**而设。

## 8. 迁移程序

**分四个可独立验证的阶段**，阶段间设硬门（§9 的不变式），任何阶段失败即回滚到 S0 备份：
P1 布局与 git 重置（S0–S3）→ P2 pin 内容寻址演进（§6）→ P3 边界门（§7）→ P4 文档重写（S6–S7）。
P1 是其余阶段的**前置**；P2/P3 互不依赖，可并行；P4 须在 P1 之后（路径已定）。

| 步 | 动作 | 验证 | 失败处理 |
|---|---|---|---|
| S0 | 刷新备份（rsync 增量 + bundle 重建），校验 sha256 清单 | 差异 0 行 | 停止 |
| S1 | **不**做 checkpoint 提交（结论性决定） | — | — |
| S2 | 清空 git：本地 `git init` 新历史；GitHub 重置为新初始提交 | 推送后 `ls-remote` 指向新 HEAD | 从备份/iCloud 还原 |
| S3 | 物理移动：`pathways/ catalog/ sources/ → content/`；新增 `packages/`（含 README + 协议草案） | `git status` 只显示预期的 R | 按备份反向移动 |
| S4 | 路径同步：工具字面量、6 条 `pathways` 封存 pin 的 `path`、`.agents/skills` 引用、AGENTS 路由、`pathways/AGENTS.md` → `content/pathways/AGENTS.md` | `check_layers` + 引用计数归零 | 逐项回退 |
| S5 | 门禁与测试全绿 | 见 §9 | 回滚到 S0 备份 |
| S6 | 文档重写：`README.md`、根 `AGENTS.md`、`docs/AGENTS.md` + 新增架构文档 | 自审 + 用户评审 | 迭代 |
| S7 | 首个提交 + 推送 + 记录 `pre-monorepo HEAD` | `selfcheck.py` 退 0 | — |

**路径同步范围界定（重要）**：只改**活文档与活合同**——`AGENTS.md` 系列、当前规范（`docs/production-sop-v3.md` 等）、`.agents/skills/**`、`tools/**`、`production/**` 的 `contracts[]`/任务引用。**历史文档一律不回写**（§2 N5），因此历史文档中残留旧路径是**预期状态**，不计为缺陷。

## 9. 验证不变式（硬门，任一不过即回滚）

- **I1 内容不变（仅对 S3 移动步成立）**：S3 移动前后，**被移动文件集合**的 sha256 多重集合完全一致（移动只改路径、不改内容）。**新增文件不计入**——P2/P3/P4 会新增 `check_layers.py`、`test_layer_boundaries.py`、ADR-005、`layering.md`、`packages/README.md`、本 spec 与实施计划，因此「全树多重集合一致」在迁移整体上不成立，不得如此表述。
- **I2** 113 条封存 pin 全绿（`pin_seal.py --check` 退出 0）。
- **I3** 91 条 `references[]` 全部 resolve（`verify_records` 通过），且**迁移前后哈希值不变**。
- **I4** 四门禁 `check-fool-materials` / `check-fool-cards` / `check-fool-nonsequence-cards` / `check-fool-audio` 全 exit 0；`check --level scaffold` exit 0。
- **I5** `python3 -m unittest discover -s tests` 通过；`swift test` 通过（Swift 侧不受布局影响，作为回归确认）。
- **I6** `tools/selfcheck.py` 退 0。
- **I7** `tools/check_layers.py` 通过，且其反例测试全部失败符合预期。

## 10. 文档重写规格

**原则：一个事实一个家**；README 与 AGENTS 只做**路由**，不复述他处事实。

| 文件 | 职责 | 关键内容 |
|---|---|---|
| `README.md` | 产品门面 + 文档 router | 顶层为《诡秘世界》产品定义（引 PRD §0–2，指向 PRD 而非复述）；本仓库 = 单仓库；四层导航（引擎/内容/应用/文档）；快速开始按层分组；状态如实标注（引擎未实现、11 卡 user-visually-approved 但 `release_approved: false`） |
| 根 `AGENTS.md` | 操作性总契约 + 路由 | **保留**全部现行质量契约、门禁、反模式与稳定标识规则；改写「概览/路由」为层图（产品层/引擎层（未实现）/内容层/应用层）；新增 §4 依赖方向硬规则与 `check_layers` 入口；卡片制作降为「内容层」的一个子域并指向 `docs/card-production-index.md` |
| `docs/AGENTS.md` | 文档层效力地图 | 产品层由「未来基线·非规范」提权为「**产品意图定义**（对产品意图规范；对仓库事实仍非规范，不构成批准）」；新增 router 与「一个事实一个家」约定；更新路径（`pathways/`→`content/pathways/` 等） |
| 新增 `docs/architecture/layering.md` | 分层与依赖方向的规范说明 | §3/§4/§5 的可读版；指向 `check_layers.py` |
| 新增 `docs/decisions/ADR-005-*.md` | 承接规范效力 | 单仓库分层决策；对 `artifacts/` 不迁移条款的**遵守**说明；pin 内容寻址演进的接受记录 |

## 11. 历史归档与可追溯

- 旧史恢复点（两处，均已校验）：
  1. `/Users/hrygo/Backups/world-of-mysteries-20260915-140241`（本机）
  2. `~/Library/Mobile Documents/com~apple~CloudDocs/Backups/world-of-mysteries-pre-monorepo`（iCloud，离机）
- 归档锚点：**`pre-monorepo HEAD = c93de0be2cad92603d083eff02a3ea4367518c9d`**（84 提交，含 2 个未推送 + 74 项未提交改动的前置状态）。
- 新仓库首个提交信息须包含该 HEAD 与备份位置。
- `docs/AGENTS.md` 的「追溯以 git 历史为准」条款须改写为：「追溯以新历史为准；monorepo 之前的旧史归档于备份与 iCloud（锚点 HEAD 见上），不在本仓库历史内」。
- `README.md` 不得声称仓库历史含 monorepo 之前内容。

## 12. 风险与回滚

| 风险 | 缓解 |
|---|---|
| R1 迁移中途状态不可用 | 每个 S 步独立可验证；S0 备份双份；任一步失败按表回滚 |
| R2 静默破坏批准链 | I1（sha256 多重集不变）+ I2 + I3 三重守门；批准按哈希绑定，内容不变则批准不失真 |
| R3 路径同步漏项 | 迁移后对活文档做引用计数扫描（`content/` 旧路径残留须为 0，历史文档除外并被显式豁免） |
| R4 GitHub 旧史被覆盖 | 按用户决策执行；旧史仅存备份/iCloud → 已达成本机 + 离机双副本并校验 |
| R5 iCloud 副本被「优化存储」驱逐 | 恢复前须确认文件已完整下载；本节记录为已知限制 |
| R6 `check_layers.py` 规则过宽误报 | 规则仅针对路径引用与 import 文本；已知边界声明在文件内；反例测试锁定行为 |

## 13. 后续（不在本次范围）

- 资产策略：315MB 二进制仍在 git、无 LFS；`artifacts/**` 随 22 途径增长（估 3–5GB）。LFS/CAS 迁移为路径保持，独立决策。
- `packages/` 内部包划分（`engine-types` / `engine-core` / 各引擎）随 PRD Phase 0 启动再定。
- `production/schemas/*.json` 的 `$id` 为命名空间值（非路径），本次无需改动；若未来统一命名空间前缀，需新 ADR。
