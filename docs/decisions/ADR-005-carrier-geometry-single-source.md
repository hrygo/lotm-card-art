# ADR-005：载体几何单一来源（合同 pin 锁定 / Python 单源化 / 渲染器派生待决）

## Status

Proposed（Decision 1–2 已实施并验证；Decision 3 待裁定）

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

两者都声明 `geometry_id = fool-agentic-mother-v2`。接口模板的 `gem_slot` 块当前只被 Python 读取 `name_surface` 时触及（`tools/production.py:1365`），渲染器则从载体合同 `anchors` 读宝石并断言等于自身常量（`tools/render/foolpipeline5.swift:693-697`）。因此**把几何收敛到接口模板会静默改变宝石几何与像素**，该块须先与实测几何对齐。

## Decision

1. **已实施——合同纳入 pin**：`production/symbols/fool-carrier-execution-v1.json` 加入 `production/tasks/fool-five-tier-frame-batch-v1.json` 的 `contracts[]`（112→113 条）。改动该合同即令 `pin_seal --check` 失败（实测 rc=1 并点名路径与新旧哈希），该检查已进 CI。
2. **已实施——Python 单源化**：`tools/production.py` 删除重复的几何字面量，改为**结构校验 + 关系不变量**：`safe_rect ⊆ rect`、宝石居中于姓名面、宝石不侵入姓名面安全距、序列数字居中于画布。精确值交由 pin 锁定，语义交由不变量守护。配对新增 6 条用例（pin 存在性、3 条关系反例、容器判定正负例）。
3. **待裁定——渲染器几何来源与失败模式**：
   - **A（推荐）**：几何以**实测载体合同**为唯一家；渲染器**派生**其常量，并在渲染前校验该合同已按 pin 封存。改几何必须显式重封 pin（等同人工批准），从而同时满足计划验收的「改一处生效」与现行为的安全边界 fail-closed。
   - **B**：几何以**接口模板**为唯一家，载体合同只保留实测锚点。**前置**：先修正接口模板的陈旧宝石块，否则等于改像素。
   - **C**：保留现行为——渲染器继续用 `requireRect`/`requirePoint` 对合同做 fail-closed 等值断言，把 T2 收口为「强制镜像」，并修订计划验收措辞（不再要求渲染器派生）。

## 实施前置（A 或 B 均需）

- 将 `illustrationWindow`、`rankNumeralVisibleHeightFinal` 落入选定合同，并核对 schema `additionalProperties: false` 的约束是否需要同步放宽。
- 对齐接口模板的陈旧宝石块，或显式声明其为历史接口。
- 重封 pin，并让渲染器在渲染前校验合同已封存。
- 验证门：`swiftc` 自检、golden 30/30 逐字节一致、五门禁逐字节一致、Python 全套、`swift test`。

## Consequences

- 正面：几何精确值有了唯一且可机检的锁定点；门禁不再维护第二份数值副本；漂移在 CI 阶段即可见。
- 代价与风险：pin 重封成为几何变更的必经步骤；若采用 A/B，渲染器失败模式由「拒绝渲染」变为「跟随合同」，必须靠 golden 逐字节比对与合同 pin 校验共同把关。
- **口径更正**：ADR-004 记「合同 pin 共 249 条」，实测为 **113 条**（`production/**` 的 21 份活合同；`artifacts/**` 的历史回执按其不可覆盖 provenance 语义排除，另有 25 条分布在 3 份回执内）。ADR-004 的改名成本结论方向不变，但绝对数应以实测为准。

## Alternatives Considered

即 Decision 3 的 A/B/C 三条路线；C 是唯一不需要改动渲染器的收口方式，A 是唯一同时满足「单一来源」与 fail-closed 的路线。
