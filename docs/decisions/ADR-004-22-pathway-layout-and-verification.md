# ADR-004：22 途径扩展的三个结构决策（媒体存放 / CI 覆盖 / 命名空间）

## Status

Accepted

## Date

2026-09-14

## Supersedes

无。新增决策，不取代 ADR-002/ADR-003。与 ADR-003 的关系：ADR-003 约束**画布与采样工艺**，本 ADR 约束**仓库布局与验证覆盖**，二者不冲突，共同服务 22 途径扩展。

## Context

以 `e4b2bf0`（tag `v0.3.0`）为基线的 DRY/SOLID 分析与复核结论：**骨架已支持 22 途径，生产链尚不支持**（依据 `docs/superpowers/plans/2026-09-14-pipeline-22-pathway-optimization/`，该计划本身非约束）。三项实测事实驱动本决策：

1. **媒体重复存放**：每张卡的卡图与音频在 `artifacts/**`（provenance）与 `apps/LotmCardStudio/Resources/{CardArt,Audio}`（bundle）**各存一份**。单卡实占约 12M（卡图 3.5M×2、音频 3.9M+1.1M），其中约一半是副本。`.git` 已达 264M，工作区 1.1G；按 220 序列卡外推约 2.6GB。
2. **原生侧零 CI 覆盖**：CI 为 `ubuntu-latest`（Python 3.10–3.14），仅跑 `cardctl check --level scaffold` 与 `unittest discover`。无 `swiftc` → **5 个测试被跳过**（含唯一覆盖原生渲染器 `foolpipeline5` 的 3 例）；`apps/LotmCardStudio` 的 **80 个客户端测试从未在 CI 运行**。渲染器路径校验缺陷（`tools/render/foolpipeline5.swift:252-255`）因此长期不可见，并两次被误诊为「依赖 gitignore 的 `generated/`」。
3. **重命名爆炸半径与并发**：`production/{symbols,tasks,templates,schemas,calls}/fool*` 被 **54 个文件**引用（其中 **10 个在 `artifacts/`**，属历史回执）；合同 pin 共 **249 条**（单文件最高重复 15×），任何改名都需重封存。决策时另一位写入者有 101 个未提交文件且 38 秒前仍在写。`git-lfs` 未安装。

## Decision

1. **媒体单一存放（对应计划 05-T2 选项 a）**：卡图与音频以 `artifacts/**` 为**唯一真源**（保持其不可覆盖 provenance 语义）；`apps/LotmCardStudio/Resources/{CardArt,Audio}` 不再是真源，改由 `scripts/build-app.sh` 在打包时**按登记表**拷贝进 bundle。
   **前置条件**：`04-T3`（登记表 ↔ 资源一致性门禁）先落地，且其校验对象由 `Resources/` 目录改为 `artifacts/`。
2. **CI 覆盖原生侧（对应 06-T2 选项 a）**：新增 macOS runner job，真实执行原生渲染器测试与客户端 `swift test`。
   **前置条件**：`01-T1`（渲染器路径规范化缺陷）必须先修，否则新 job 恒红，并会再次被误读为环境问题。
3. **前向命名空间（对应 02/05 选项 b）**：**不对 fool 历史文件做批量重命名**。规定「**新途径**的合同/任务/模板/回执置于 `production/<area>/<pathway>/…`」；fool 保持现有扁平形态，并在 `02` 规范中**显式标注为历史形态**，以免后人误判为不一致。

## Execution Order（本次同时确认）

```
01-T1（渲染器路径缺陷修复）
  → 02（仅写"新途径命名空间化"规范 + 门禁参数化）
    → 03（pin 单一来源 + seal 生成器）
      → 04-T3（登记表 ↔ 资源一致性门禁）
        → 1A 实施（单一存放 + 构建期拷贝） 与 2A 加 CI
```

理由：1A 依赖 04-T3（否则 App 资源失去校验来源）；2A 依赖 01-T1（否则 CI 恒红）；03 必须先于任何迁移/改名，否则每次改动都要手工重封存 249 条 pin。

## Alternatives Considered

### A. 保留双份 + Git LFS

拒绝。历史迁移需 `git lfs migrate` → **重写历史 + force-push**，会破坏已打 tag `v0.3.0` 与全部哈希钉值，与「artifacts 不可覆盖」正面冲突；GitHub 免费 LFS 额度（约 1GB 存储/带宽）远小于外推 2.6GB；且引入外部依赖（团队须安装 git-lfs）。

### B. 现状 + 仅加体积预算

保留为**过渡手段**（计划 05-T3），不作为终态：不降低总量，220 卡时仓库 ~2.6GB+、clone 与 CI 拉取变慢。

### C. CI 显式豁免 + 本地必跑清单

保留为**私有仓库情形下的降级方案**：成本为 0，但依赖纪律，缺陷仍可能潜伏（本会话已证明代价）。

### D. 整体重命名（把 fool 搬入 `production/<area>/fool/`）

**推迟**。命名最统一，但冲突面最大（54 处引用 + 10 个 artifacts 回执 + 249 条 pin），且与「artifacts 不可覆盖」冲突（回执只能改或标注迁移）。若未来执行，需**独占写入窗口 + 03 先行 + 单独批次**。

### E. 隔离 worktree 内迁移后合并

拒绝。与「大改名 + 对方大量新增文件」的合并会产生密集冲突，成本高于前向命名空间。

## Consequences

### 正面影响

- **1A**：仓库总量约 −50%、clone 更快；登记表成为媒体唯一声明源，消除双真相源。
- **2A**：唯一覆盖生产渲染器的用例与 80 个客户端用例进入自动验证，消除本会话那类「缺陷长期潜伏并被误诊」。
- **3B**：零重命名 / 零回执失效 / 零 pin 重封存，立即获得「新途径不与 fool 命名冲突」的可扩展性。

### 成本与限制

- **1A**：`Resources/` 内不再直接可见卡牌资源（IDE 预览变弱）；打包脚本必须能读到 `artifacts/`；`Resources/` 中非卡牌资源（图标/logo 等）需保留清单。
- **2A**：CI 时长 +3–8 分钟；若仓库为私有，macOS runner 按 10× 倍率计费（公开仓库的 standard runner 免费——**待确认仓库可见性**）。
- **3B**：仓库短期存在两种命名形态（fool = 历史、新途径 = 命名空间），需规范明文说明。
- **本 ADR 不放宽任何质量门槛**：三项均为「布局与验证」调整，不删改任何断言；新增/变更的门禁须配反例测试。

## Verification boundary

- **1A 生效判据**：门禁在**不依赖** `apps/…/Resources/{CardArt,Audio}` 为真源的前提下仍能校验登记一致性；打包后的 `.app` 能正常加载卡图与音频。
- **2A 生效判据**：CI 出现 macOS job，且原生渲染器 3 例与客户端 80 例**真实执行**（非 skip）。
- **3B 生效判据**：`02` 规范含「新途径命名空间化 + fool 为历史形态」明文；以合成途径 id 验证不与既有路径冲突。
- 本 ADR 中的体积、时长、计费数值均为测量或估算，**非承诺**；实施后须重新测量。