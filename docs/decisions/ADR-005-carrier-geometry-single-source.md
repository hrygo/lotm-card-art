# ADR-005：载体几何单一来源（合同 pin 锁定 / Python 单源化 / 渲染器派生待决）

## Status

Accepted（Decision 1–3 已实施并验证；A/B 作为后续可选升级保留，见 Decision 3 与「实施前置」）

## Date

2026-09-15

## Supersedes

无。落实 ADR-004 的「单一来源」方向与计划 `docs/superpowers/plans/2026-09-14-pipeline-22-pathway-optimization/04-single-source-consolidation.md` 的 T2；不取代 ADR-002/003/004。

## Context

Fool 载体几何在**三处**并存：`production/symbols/fool-carrier-execution-v1.json`（合同数据）、`tools/production.py`（门禁期望值）、`tools/render/foolpipeline5.swift`（渲染器常量）。计划 04 的判定是「单一来源被复制 → 必然漂移」。实测补充三项事实：

1. **合同此前未被任何 pin 覆盖**：`production/**` 内 21 份活合同的 113 条 pin 均不含该载体合同 → 合同可被改写而不被任何检查发现。
2. **合同并不完整**：渲染器 `FoolGeometry` 共 14 个几何值，载体合同 `anchors` 只提供 11 个；`numeral_exclusion_rect_design` 在接口模板 `production/templates/fool-mother-frame-interface-v1.json`；`illustrationWindow`、`rankNumeralVisibleHeightFinal` **不在任何合同**。
3. **接口模板对同一 `geometry_id` 与合同矛盾（实测）**：

| 字段 | 接口模板 | 载体合同（`measured`） | 渲染器/回执 |
|---|---|---|---|
| gem `center_design` | [512, 1410] | [512, 1421] | 1421 |
| gem `visible_size_design` | [112, 68] | [132, 114] | 132×114 |
| gem `name_clearance_design` | 24 | 12 | 12 |
| gem `shape` | `shield-cut-low-profile-lozenge` | `regular-equilateral-hexagon` | hexagon |

两者都声明 `geometry_id = fool-agentic-mother-v2`。接口模板的 `gem_slot` 块当前只被 Python 读取 `name_surface` 时触及（`tools/production.py` 的 `name_contract` 读取，当前 :1364），渲染器则从载体合同 `anchors` 读宝石并断言等于自身常量（`tools/render/foolpipeline5.swift` 的 `gem` 锚点断言，当前 :733-737）。因此**把几何收敛到接口模板会静默改变宝石几何与像素**，该块须先与实测几何对齐。

## 已裁定（分层：愚者 C / 新途径 A）

**裁定（2026-09-15，用户）**：愚者途径**保留现状 C**；后续途径在制作时**按派生架构（A）落地**——几何只写在
该途径的载体合同里、渲染器派生、schema 只做结构约束。

三条护栏：

1. **愚者不事后改造**：不为了「与后续途径一致」而把愚者的常量表改成派生——与 ADR-004 决策 3 的
   「`fool` 是冻结历史层，不要为一致性补迁移」同一原则；已批准像素与冻结合同优先。
2. **新途径不落常量表**：渲染器不得为新途径添加几何常量（避免 13×N 重复）；派生**之前**先校验合同
   已按 pin 封存，使「未重封的改动」在渲染期照样响亮拒绝，保留 fail-closed 语义。
3. **新途径 schema 只做结构约束**：不把值级 `const` 复制过去——值级强制由 pin 承担，否则等于给
   新途径再造一个真相源。

以下为裁定依据：

取舍对象是**哪一份值级强制为准**，不是几何值本身：已批准像素（11 张卡经用户视觉验收）与载体合同（`status: measured`）**一致**，接口模板的 `gem_slot` 块（`status: template`）是同一 `geometry_id` 下的**陈旧副本**。因此采用 A **不需要**先修模板（A 不读模板）；只有选 B 才必须先对齐模板，否则改像素。

- **选 A**：schema 的 `gem_slot` 值级 `const`（`shape` / `center_design` / `visible_size_design` / `name_clearance_design`）放宽为结构约束，值级强制**移交 pin**；渲染器改为派生并删除等值断言。
  - 须接受的风险：合同值若被改动**且同时重封存**，渲染器会静默跟到新几何——此时唯一拦截是 golden 与人工视觉验收（fail-closed → fail-on-pin 的失败模式变更）。
- **维持 C（现状）**：合同 `measured` + 渲染器等值断言 + pin 三处一致，schema 值级 `const` 作为第四道冗余；代价是几何值在 schema 里多存一份。

## Decision

1. **已实施——合同纳入 pin**：`production/symbols/fool-carrier-execution-v1.json` 加入 `production/tasks/fool-five-tier-frame-batch-v1.json` 的 `contracts[]`（112→113 条）。改动该合同即令 `pin_seal --check` 失败（实测 rc=1 并点名路径与新旧哈希），该检查已进 CI。
2. **已实施——Python 单源化**：`tools/production.py` 删除重复的几何字面量，改为**结构校验 + 关系不变量**：`safe_rect ⊆ rect`、宝石居中于姓名面、宝石不侵入姓名面安全距、序列数字居中于画布。精确值交由 pin 锁定，语义交由不变量守护。配对新增 6 条用例（pin 存在性、3 条关系反例、容器判定正负例）。
3. **已裁定并实施——渲染器保留 fail-closed 等值断言（选项 C），并补齐几何覆盖**：渲染器继续以 `requireRect`/`requirePoint` 对同一载体合同做等值断言，失败模式不变（合同漂移即拒绝渲染，不静默跟随）。同时把此前**未被任何合同覆盖**的 3 个几何值补进载体合同并加断言：`illustration_window`、`numeral_exclusion`、`rank_numeral_visible_height_design`（含 schema 扩展与 2 条覆盖用例）。结果是：载体合同成为**唯一且被 pin 锁定的几何声明源**，渲染器 13 个几何常量**全部**被合同覆盖并逐项断言，未再留有游离字面量。
   - **后续可选（未实施）**：
     - **A**（推荐升级）：渲染器改为**派生**并在渲染前校验合同已按 pin 封存，从而「改一处即生效」且仍 fail-closed。**代价**：需放宽 `fool-carrier-execution.schema.json` 中 `gem_slot` 等处的值级 `const`（把值级强制从 schema 移到 pin），属失败模式变更，须单独决定。
     - **B**：几何改以**接口模板**为唯一家，载体合同只保留实测锚点。**前置**：先修正接口模板的陈旧 `gem_slot` 块（其值与载体合同对同一 `geometry_id` 矛盾），否则等于改像素。

## 实施前置

- ✅ 已随选项 C 完成：`illustration_window`、`numeral_exclusion`、`rank_numeral_visible_height_design` 落入选定合同（含 schema 扩展：`anchors.required`/`properties` + `$defs.rect_only`），并补 2 条覆盖用例；重封 pin（113 条）；渲染器逐项断言。
- ⏳ 仅采用 A/B 时需要：对齐接口模板的陈旧 `gem_slot` 块；渲染器改为派生并在渲染前校验合同已封存；放宽 schema 的值级 `const`。
- 验证门：`swiftc` 自检、golden 逐字节一致、五门禁逐字节一致、Python 全套、`swift test`（选项 C 下已全部通过）。

## Consequences

- 正面：几何精确值有了唯一且可机检的锁定点；门禁不再维护第二份数值副本；漂移在 CI 阶段即可见。
- 代价与风险：pin 重封成为几何变更的必经步骤；若采用 A/B，渲染器失败模式由「拒绝渲染」变为「跟随合同」，必须靠 golden 逐字节比对与合同 pin 校验共同把关。
- **口径更正**：ADR-004 记「合同 pin 共 249 条」，实测为 **113 条**（`production/**` 的 21 份活合同；`artifacts/**` 的历史回执按其不可覆盖 provenance 语义排除，另有 25 条分布在 3 份回执内）。ADR-004 的改名成本结论方向不变，但绝对数应以实测为准。

## Alternatives Considered

即 Decision 3 的 A/B/C 三条路线；C 是唯一不需要改动渲染器的收口方式，A 是唯一同时满足「单一来源」与 fail-closed 的路线。
