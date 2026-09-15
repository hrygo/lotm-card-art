# ADR-006：以文档确立分层，不执行物理迁移

## Status

Accepted

## Date

2026-09-15

## Supersedes

`docs/superpowers/specs/2026-09-15-monorepo-layout-and-layering-design.md` 中的三项提案：P1（物理搬动 `pathways/`、`catalog/`、`sources/` 到 `content/`）、P2（封存 pin 从路径主键演进为内容寻址）、S2（清空并重置 git 历史）。该规格保留为**未采纳的备选记录**，不再是待执行计划。

## Context

用户要求「依据最新 PRD 重新组织项目文档；制作卡片的能力已经仅仅是本项目的一部分」，并裁决《诡秘世界》采用单仓库架构。

原规格提出的方案是：新增 `packages/`、把内容目录搬入 `content/`、清空 git 历史、把封存 pin 演进为内容寻址。该方案经对抗式审查（oracle 技术风险、Metis 歧义与 AI 失败点、以及独立实证复核）判定**在现行治理下不可执行**。以下每条均有代码或文件级证据：

1. **批准摘要绑定路径。** `tools/production.py` 的 `narrative_digest()`（L1784-1789）把 `entry` 全字段（含 `evidenceRefs[].path`）计入哈希；`validate_narrative()`（L1792-1817）对已批准条目要求 `contentDigest == digest` **且** `review.approvedDigest == digest`。搬动路径会使 `production/narratives/klein-s09-tingen.json` 的批准摘要失效，唯一能过门禁的方式是**重算并覆写人类批准摘要**——即伪造批准，且清史后无 diff 可查。
2. **闭合 schema 封死内容寻址。** `production/schemas/task.schema.json` 对 `contracts.items`、`narrative`、`references.items`、`spec.oneOf[2].protagonist.evidence_refs.items` 四处均声明 `additionalProperties:false` 且 `required` 含 `path`+`sha256`（`references` 另需 `role`）。新增 `content_hash` 或令 `path` 可选会**直接校验失败**，`verify_records` 的新分支根本不可达。
3. **双写会卡死重封存器。** `tools/pin_seal.py` 的 `_reseal_text()`（L102-117）要求旧哈希在文本中唯一：`updated.count(digest) != 1` → `PinError`。双写后 `content_hash` 与 `sha256` 同值即触发中止；且 `MASK_RE`（L26）只遮蔽 `"sha256"` 字段，L95 的字节保全断言对 `content_hash` 是盲区。
4. **不可覆盖 provenance 依赖被改工具。** `artifacts/**` 的 **52** 份 `snapshot.json` 共 **367** 条 `dependencies[]`，其中记录 `tools/production.py`（sha `3c54f56acf…`，已实测）、`production/schemas/task.schema.json`、`.agents/skills/lotm-*/SKILL.md`、`pathways/fool/canon.json` 的哈希；而搬动的路径同步**必须**编辑 `tools/production.py`（L205、L1406 硬编码 `pathways/...`）。`artifacts/**` 不可覆盖 ⇒ **无合规修复路径**。
5. **该层当前已不可验证（既有债）。** 上述 367 条依赖中已有 **76 条指向不存在路径**（17 种，含已按 D10 移除的 `docs/production-sop.md` / `-v2.md`，以及已移入 Trash 的旧四档链 `raw.png`）。而 `tools/selfcheck.py` 与 `.github/workflows/ci.yml` **都不调用** `gate`，因此无人发现。
6. **测试与模板不在原规格的同步范围内。** `tests/` 有 **14** 处硬编码 `pathways/`、`catalog/` 路径（分布 5 个文件，含 `test_cardctl.py` 的 10 处——它虽用合成根，但根是 `shutil.copytree(REPO, …)` 的真仓库副本，搬动后照样失败）；`.github/PULL_REQUEST_TEMPLATE.md` 与 `.github/ISSUE_TEMPLATE/content-evidence.yml` 亦引用内容路径。原规格的同步范围只列了「AGENTS.md 系列、当前规范、`.agents/skills/**`、`tools/**`、`production/**`」。
7. **手段与目标错位。** 用户的痛点是**文档准确性**；重写文档不需要任何搬动、不需要清 git 史、不需要改 pin/schema/tools/skills。
8. **编号冲突。** `docs/decisions/ADR-005-carrier-geometry-single-source.md` 已被占用，原规格拟新增的「ADR-005」必须改为 ADR-006（即本文件）。

## Decision

1. **不执行物理迁移。** `pathways/`、`catalog/`、`sources/` 保持现状；**不**新增 `content/`；**不**清空或重置 git 历史；**不**改动 `tools/production.py`、`tools/pin_seal.py`、`production/schemas/*.json`、`.agents/skills/**`。
2. **以文档确立分层。** 新增 `docs/architecture/layering.md` 作为分层与依赖方向的**单一说明**；每个顶层目录必须归入一层并给出规则。
3. **声明引擎层契约占位。** 新增 `packages/README.md`，声明未来 IP 中性引擎层（World/Character/Story/Audio）的边界与「不得依赖内容/生产/应用层」契约；**不写实现代码**。
4. **重写身份与导航。** `README.md`、根 `AGENTS.md`、`docs/AGENTS.md` 改为**产品优先**叙事：本仓库是《诡秘世界》的前置工程，现有两个交付面（内容生产、macOS 客户端）与一个未来面（引擎层）；制卡是内容层的一个子域。
5. **边界门仅作规范表达。** 本次**不**新增机器强制的层界检查脚本；`layering.md` 必须显式写明「当前未机器强制」。待首个引擎包落地时另开 ADR 评估工具化。
6. **未来若仍要物理迁移，必须先满足以下前置条件**（逐条可核对；本清单即审查结论的落点）：
   - **a.** 把 `narrative_digest` 与路径解耦（改为对已解析证据内容取哈希），作为独立的、经评审的改动落地；并新增不变式「迁移前后 `production/narratives/**` 的 `contentDigest`/`approvedDigest` 逐字节不变」。
   - **b.** 开放上述 4 处闭合 schema，并同步 `verify_records` 的 `path` 缺省分支与 `pin_seal` 的字段化改写，配反例测试（含「`sha256` 与 `content_hash` 同值」用例）。
   - **c.** 就 `artifacts/**` 的 snapshot/receipt 依赖制定处置策略（修复、标记失效、或不追踪工具哈希），并先处理已断的 **76 条**。
   - **d.** 把 `check-fool-materials` / `check-fool-cards` / `check-fool-nonsequence-cards` / `check-fool-audio` 与未来边界门接入 `tools/selfcheck.py` 与 CI（当前 selfcheck 只跑前两项，CI 一项都不跑）。
   - **e.** 定义唯一的 git 基线提交，演练 `git bundle` 可还原（`git clone` + `git fsck`），并导出 GitHub 独有数据（Issues / PR / Releases / Actions 日志 / 分支保护）。
   - **f.** 把 `tests/**` 与 `.github/**` 纳入路径同步范围，并给出受搬动影响的完整清单。已实测基准：`production/**` 内以 `pathways/`、`sources/` 开头的路径值共 **42 处**，分布 **31 个文件**（字段分布 `source` 22、`path` 12、`semantic_source` 8；其中经 `verify_records` 校验的是 `path` 那 12 处）；另有 **113** 条封存 `contracts[]`（分布 **21** 个消费文件，全部 `path`+`sha256` 齐备）、**91** 条 `references[]`（全部指向 `artifacts/**`，本次不受影响）。

## Alternatives Considered

### A. 立即执行完整单仓库迁移（原规格）

拒绝。见 Context 1–6：会破坏批准摘要与不可覆盖 provenance，或直接被闭合 schema 与重封存器护栏卡死。

### B. 先搬目录，内容寻址演进留待后续

拒绝。搬动本身就必须编辑 `tools/production.py`，已足以破坏不可覆盖依赖；且 B 完全不解决批准摘要问题（Context 1 与 3 皆不涉及）。

### C. 只做文档重组，声明分层，迁移另立程序（本决定）

接受。用户痛点依赖文档重写即可解决，且该路径不触碰任何被 pin、被批准、被 snapshot 记录的区域。

## Consequences

### 正面影响

- 用户的痛点（README/AGENTS 已不能准确描述本仓库）当场解决，且改动面**仅在文档**；
- 不触碰被 pin、被批准、被 snapshot 记录的区域 ⇒ **零 provenance 风险**；
- 15 项审查结论与 6 项前置条件以 ADR 形式留存，未来不必重新推导。

### 成本与限制

- 层界是**约定**而非机器强制，依赖评审与人工维护；
- `packages/` 只是占位，**不构成「引擎层边界已达成」**，不得据此宣称机器强制；
- `docs/architecture/layering.md` 与根 `AGENTS.md` 需人工保持同步；
- `artifacts/**` 的 **76 条失效依赖仍未处理**，属独立技术债（见 Decision 6c），本 ADR 不解决它。

## 与 D17 / 母 PRD §25 的关系（引擎代码归属）

`D17` 与母 PRD `§25` 的表述是「World/Story/Character/Audio 引擎**不进入**卡牌美术仓库」「引擎实现属另一交付面，需**另行立项**」；本 ADR 与 `docs/architecture/layering.md` 则把**引擎层定为 `packages/`（本仓库内）**。二者措辞冲突，必须显式消解：

1. **归属（2026-09-15 用户确认「以此为准」）**：用户已裁决《诡秘世界》采用**单仓库架构**，并在 2026-09-15 明确确认本项。据此，引擎代码的家是**本仓库的 `packages/`**，不再是「另一仓库」。就**代码归属**这一点，本 ADR 与 `layering.md` 的表达**优先于** D17 / 母 PRD §25 的措辞。此优先关系**不是本 ADR 的自行推断**，而是用户裁决。
2. **实质要求不变**：§25 真正要守的是**引擎与内容解耦、引擎 IP 中性**，而不是「代码必须在别处」。该要求由 `packages/README.md` 的五条硬契约承接（不引用内容/工艺/制造/应用层、不出现 IP 专有名词、契约先于实现）。
3. **未改变的部分**：引擎**仍未实现**（`packages/` 只有契约占位）；本 ADR **不**宣告引擎能力、不宣告层界已被机器强制、不批准任何卡牌状态。母 PRD 正文逐字不改（`docs/product/**` 为不回写豁免，见 Consequences 与 `layering.md`）。引擎相关里程碑（命运闭环、声音优先、故事书完整化）仍阻塞于**引擎立项**，立项不等于已有实现。
4. **变更条件**：第 1 项是**已确认的裁决**。若要改为「引擎代码另立仓库」，须由用户给出**新的明确裁决**；届时同步修订 `layering.md` 的引擎层行与 `packages/README.md`，并在本 ADR 记录取代关系。

## Verification boundary

本 ADR 只决定「不做物理迁移、以文档确立分层」，**不批准**任何卡牌、图像、音频或发布状态；`release_approved` 保持 `false`，十一张卡的 `user-visually-approved` 状态不受影响也不被升级。分层说明的准确性须经人工评审，不得由机器 gate 冒充。
