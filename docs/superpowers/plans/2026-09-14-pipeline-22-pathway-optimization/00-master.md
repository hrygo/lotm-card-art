# 流水线 22 途径扩展优化方案 · 主文档

> **状态**：Agent 生成提案。**非约束、非批准、非 canon**（效力见 `docs/AGENTS.md`：`superpowers/plans/*` 属「Agent 生成·非约束」）。
> **基线**：`e4b2bf0`（tag `v0.3.0`）。证据 = HEAD 上的直接源码/grep 实测 + 代码图（`tools/` 211 节点 / 1057 边；索引略早于该提交，`tools/` 结构除新增一个校验函数外未变）。
> **配套子文档**：本目录 `01`–`06`（见文末索引）。

---

## 结论（一句话）

**骨架已经支持 22 途径，生产链目前不支持。** 差距是「代码泛化 + 内容产能」，不是架构死路。完成 `01 → 02 → 04 → 03` 四个代码工作流后，22 途径退化为内容与审核问题，而不是可行性问题。

---

## Goal

把当前「愚者专属垂直切片」的视觉生产链，泛化为「**一条途径 = 一份生产合同（数据）**」的通用链，使 22 途径 × 10 序列运行在同一套代码上；并修复本轮复核查出的渲染器路径校验缺陷。

## Architecture

现状**已有正确的分层**（代码图实测，非推断）：

- `tools/cardctl.py` = **core**（fan-in 21 / fan-out 3），完全 `pathways/{slug}` 参数化；
- `tools/production.py` = **internal**（fan-out 21 → 单向依赖 cardctl，无 `import production` 反向依赖，无 IO 层重复实现）；
- `tools/render/*.swift` = **leaf**（只有入边，无出边）；
- 内聚簇 5 个：通用生产机（41 成员 / cohesion 0.93）、foolpipeline 批次（46 / 0.89）、raster+文字（29 / 0.79）、cardctl 核心（24 / 0.84）、绘图原语（8 / 0.92）。
  → **职责在「簇」层面已分离，但共处同一文件**（`production.py` 1914 行、`foolpipeline5.swift` 72 处 fool 引用）。

目标形态：一个通用渲染器读「途径生产合同」；门禁按途径参数化；共享配置单一来源；契约 pin 由生成器产出。

## 现状基线（实测，可复现）

| 面 | 实测值 | 判定 |
|---|---|---|
| 途径脚手架 | `catalog/pathways.json` 22 条；`pathways/` 22 个目录；220 序列卡槽 | ✅ 已就绪 |
| `cardctl.py` | 全 `pathways/{slug}/…` 参数化 | ✅ 已泛化 |
| `config/{sequence-hierarchy,quality-color-tokens,project}.json` | **0 处** fool 提及 | ✅ 途径无关、可复用 |
| `tools/render/compose.swift` | **0 处** fool 引用 | ✅ 通用合成器 |
| `production/schemas/{task,call,composition,card-text-panels,emblem-dock}` | 通用编辑器契约 | ✅ 可复用 |
| `tools/render/foolpipeline5.swift` | **72 处** fool 引用；硬编码 4 个合同路径（:603 carrier / :729 kit / :1039 inscriptions-v2 / :1049 rank-numerals） | ❌ **头号阻塞** |
| `tools/production.py` | 1914 行；113 行含 fool；42 个 def 中 6 个 fool；硬编码途径校验 :288/:576/:620；内联五档映射 :547-553 | ❌ 需参数化 |
| `production/` 文件面 | 295 个 `*.json`，其中 **150 个**文件名含 fool（**51%**） |  扁平命名，未按途径分层 |
| 契约 pin | **23** 个合同文件、**249** 条 pin；单文件最高重复 **15×**（sop-v3 15、tokens 15、preflight 14、resolution-policy 9、hierarchy 8） | ❌ 手工维护不可扩展 |
| 渲染器路径校验 | `foolpipeline5.swift:252-255`：`base` 用 `resolvingSymlinksInPath()`、`resolved` 只用 `standardizedFileURL` → 同目录产出 `/var/…` vs `/private/var/…`，前缀永不匹配 | ❌ **真实缺陷**（见 01） |
| CI | ubuntu-latest + py 3.10–3.14，仅跑 `scaffold` + `unittest`；无 `swiftc` → 渲染器测试 skip | ❌ 渲染器链无 CI 覆盖 |
| 客户端体积 | App Audio 合计 19M、CardArt 合计 16M（含既有 2 卡）；每卡在 `artifacts/` 与 `apps/…/Resources/` **各存一份** | ️ 22×10 规模需治理 |

## 十个事实（复核确认）

1. `cardctl.py` 的 22 途径能力是**现成**的：`check --level scaffold` 在 fresh checkout 上 `errors: []`。
2. **共享配置真的共享**：`config/` 三个文件零 fool 提及；五档语义已是跨途径基线（不做 5×10 交叉）。
3. `compose.swift` 是途径无关的通用合成器；EmblemDock 被显式写为「面向未来途径的词汇表」（`production.py:239`）。
4. Fool 的途径耦合集中在**两个文件**：`foolpipeline5.swift`（渲染）与 `production.py`（门禁 + 几何常量）。
5. **渲染器是唯一无法用「加数据」解决的阻塞**：其余耦合都能靠参数化 + 迁移数据消除。
6. pin 是**运营层最紧迫**的问题：改一次共享配置要手工改 15 处；本会话已因此手工重封存 3 轮。
7. `config/sequence-hierarchy.json` 被 root `AGENTS.md` 声明为层级标签**唯一来源**，但 `production.py:547-553` 内联了同一映射 → 两个真相源。
8. Fool 几何同时存在于 `production.py:239-325` 与 `foolpipeline5.swift` → **跨语言重复**。
9. App 门禁的「登记式白名单」把卡表硬编码进 `production.py`，与 `apps/…/Resources/` 实际文件**构成双真相源**（漂移面）。
10. tag `v0.3.0` 只是**快照**：打 tag 后工作区又新增 6 张卡（App 卡图 5→11）与 Sefirot/旧日研究稿。

## 工作流拆分与依赖

| 子文档 | 主题 | 依赖 | 优先级 | 类型 |
|---|---|---|---|---|
| `01-renderer-generalization.md` | 渲染器途径化 + 路径校验缺陷修复 | — | **P0** | 代码 |
| `02-gate-generalization.md` | 门禁参数化 + 目录命名空间化 | 01 | **P0** | 代码 + 数据迁移 |
| `03-pin-seal-automation.md` | 249 条 pin → 单一来源 + `seal` 生成器 | — | **P1（运营阻塞）** | 工具化 |
| `04-single-source-consolidation.md` | 五档映射 / 几何 / App 登记表 去重 | 01、02 | P1 | 代码 |
| `05-asset-namespace-and-size.md` | 资产命名空间与仓库体积治理 | 02、03 | P2 | 数据 + 构建 |
| `06-verification-and-regression.md` | 跨路径回归、CI 覆盖、快照纪律 | 01 | P1 | 验证 |

```
01 ──┬─→ 02 ──┬─→ 04
     │        └─→ 05
     └─→ 06
03 ─────────────→ 05
```

## 批次建议

- **批次 A（可立即做，无外部依赖，收益立刻）**：`01` 的 T1（路径缺陷 1 处修复 + 反例测试）、`03`（pin 生成器）、`06` 的符号链接回归。
- **批次 B（结构改动，需 golden 保护）**：`01` 的 T2–T4（渲染器途径化）、`02`（门禁与目录迁移）。
- **批次 C（规模化治理）**：`04`、`05`。

## 总验收门禁（每个子文档的改动都必须同时满足）

```bash
python3 tools/cardctl.py check --level scaffold          # errors: []
python3 -m unittest discover -s tests -v                  # 全绿（01-T1 修复后不应再有渲染器失败）
python3 tools/production.py check-fool-materials          # passed
python3 tools/production.py check-fool-cards              # passed
cd apps/LotmCardStudio && swift test                      # 80 tests / 0 failures
```

附加纪律：
- **不削弱任何现有门槛**（root `AGENTS.md` 反模式：局部规则不得静默削弱质量门槛）。任何放宽必须同步补反例测试并在 `DECISIONS.md` 记录。
- 契约 pin 变更后必须仍通过 `validate_task`。
- `artifacts/**` 是不可覆盖 provenance；**只对新输出生效**，不回填、不改写已封存批准快照。
- 机器 gate 通过 ≠ 视觉/正式批准；候选保持 `pending-user-visual-approval`。

## 风险与非目标

**风险**
1. **并行写入者冲突**：本会话我的改动被从旧快照回退过两次（swift / 测试 / DECISIONS）；任何批次开工前须确认工作区所有权，或用 `HEAD + 我的改动` 方式落盘。
2. 渲染器改动会改变生产核心；必须有 golden 对比（fool 现有输出逐字节不变）。
3. 目录迁移会波及 pin 与历史回执 → `03` 应先于 `02`/`05` 的迁移部分。

**非目标**
- 不新增任何途径的内容/美术；不替 21 条途径做设计决策。
- 不改愚者已批准视觉基线；不重排模型上岗分配；不动 `artifacts/` 已封存批准快照。
- 不把本方案当批准或发布结论。

## 证据边界

结论基于 HEAD `e4b2bf0` 的**直接源码/grep 实测**（文件:行、计数）加代码图（`tools/` 抓取；索引略早于该提交）。耦合计数是**代理指标**，非完整调用图审计；「22 途径可支持性」是基于上述结构的工程判断，其内容侧成本（每条途径约 36 个资产条目）为**估算**，需在 01/02 落地后重新测量。

## 索引

- `01-renderer-generalization.md` — 渲染器途径化与路径校验缺陷
- `02-gate-generalization.md` — 门禁参数化与目录命名空间
- `03-pin-seal-automation.md` — 契约 pin 单一来源与 `seal` 生成器
- `04-single-source-consolidation.md` — 五档映射 / 几何 / App 登记表去重
- `05-asset-namespace-and-size.md` — 资产命名空间与体积治理
- `06-verification-and-regression.md` — 跨路径回归、CI 覆盖、快照纪律