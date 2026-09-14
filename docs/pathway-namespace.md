# 途径命名空间规范（22 途径生产布局）

> **效力**：规范·当前。由 ADR-004 决策 3（前向命名空间）派生，约束**仓库布局**；与 ADR-003（画布与采样工艺）互补，二者不冲突。
> **读者**：新增途径合同/任务/模板/回执的人、门禁维护者、客户端资源接入者。

## 规则

**新途径**的合同、任务、模板、回执一律置于 `production/<area>/<pathway>/…`；
**`fool` 保持现有扁平形态，并显式视为历史形态**——它不是「尚未迁移」，而是被冻结的历史层，不要为了一致性去补迁移。

## 两种命名形态

| 形态 | 适用 | 路径 | 状态 |
|---|---|---|---|
| 扁平（**历史**） | 仅 `fool` | `production/<area>/fool-*.json` | 冻结：不迁移、不改名，也不作为新途径的起名模板 |
| 命名空间（**当前规则**） | 其余 21 途径及未来途径 | `production/<area>/<pathway>/…` | 新文件一律用此形态 |

`<area>` ∈ `tasks` `symbols` `templates` `calls` `narratives` `cards` `approvals` `compositions` `retirements`。`schemas/` 见下节，不按途径建目录。

`<pathway>` 取 `catalog/pathways.json` 的 `id`（唯一来源；id 不随中文名修订而改变）。

## 命名空间可用性（已实测）

22 个途径 id 在 9 个 area 下与既有条目**零同名**，因此直接用 id 作目录名不会冲突：

```text
fool error door visionary sun tyrant white-tower hanged-man darkness death twilight-giant
demoness red-priest hermit paragon wheel-of-fortune mother moon black-emperor justiciar chained abyss
```

## 为什么不做批量重命名

- `production/{symbols,tasks,templates,schemas,calls}` 的 `fool*` 被 **54 个文件**引用，其中 **10 个在 `artifacts/**`**（不可覆盖的历史回执，只能改或标注迁移）。
- 活合同 pin 实测 **112 条 / 21 文件**（`python3 tools/pin_seal.py --check`）；`artifacts/**` 另有 25 条历史 pin（实测 12 stale + 1 missing，按其 provenance 语义**有意不重封存**）。
- 决策时另一位写入者有 101+ 未提交文件且在写 → 重命名的冲突面远大于收益。整体重命名见 ADR-004「D. 整体重命名（推迟）」。

## schemas

不新增 22 份近似相同的 schema 文件（那是把 DRY 问题搬个地方）。通用契约留在 `production/schemas/`（`task`/`composition`/`call`/…）；**途径特定约束写进合同数据**本身，而不是复制一份 schema。

## artifacts 命名（与途径解耦）

`artifacts/**` 按**任务/卡 id**组织，不按途径组织：

```text
artifacts/production/<task-id>/vNNN/…      # 任务级回执与图层
artifacts/lotm.<card-id>/audio-vNNN/…      # 卡级音频
```

途径信息体现在合同/任务的字段里，**不体现在 artifacts 目录名**；给 artifacts 目录加途径前缀会破坏历史回执及其 pin。artifacts 不可覆盖（ADR-003）。

## 门禁判定（对应计划 02-T2）

途径身份校验以「**合同声明的途径 == 调用方途径**」为准，而不是硬编码 `== "fool"`。参数化落地前，`validate_fool_*` 的现有硬校验照旧生效——**本条不放宽任何断言**；参数化只是把「fool」换成「调用方途径」，并为其余途径提供同一入口。

## 未来若要迁移 fool

前置（来自 ADR-004 D）：**独占写入窗口** + `03`（pin 单一来源）先行 + 单独批次 + 保留回退路径。不得在并行写入者活跃时迁移。

## 反模式

- 不因为「fool 是扁平的」就把新途径也写成扁平名（会让 21×N 个名字挤进同一命名空间）。
- 不把 `fool` 的扁平形态判为「漏迁移」而去补迁移。
- 不用途径名重命名 `artifacts/**` 目录（破坏历史回执与 pin）。
- 不新增 22 份近乎相同的 schema 文件。
