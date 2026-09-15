# 改名计划：LotmCardStudio → World of Mysteries（《诡秘世界》）

> 状态：**待用户批准**（Agent 生成提案，非约束；见 `docs/AGENTS.md` 效力层级）。
> 依据：用户裁决「中文名《诡秘世界》确定」「英文名 World of Mysteries 采纳」「引擎模块不挂产品名采纳」。
> 性质：本轮**只出清单与批次**，不动代码。批准后按批次执行，每批一次提交、各自独立验证。

## 0. 结论摘要

- 命名：显示名 **诡秘世界**；英文名 **World of Mysteries**；仓库名 `world-of-mysteries`；bundle id `com.hrygo.world-of-mysteries`；bundle 目录 `WorldOfMysteries.app`；app shell 模块 `WorldOfMysteries`；**未来引擎模块 IP 中性**（`WorldEngine`/`CharacterEngine`/`StoryEngine`/`AudioEngine`）。
- 冲击规模：`LotmCardStudio` 字符串约 **270 次**（Sources 26 / Tests 22 / docs 161 / README 13 / AGENTS 17 / scripts 5 / 其他），加上 4 类**非字符串标识**（Keychain、配置路径、bundle id、仓库名）。
- **两处会静默丢数据的点**（必须做迁移阶梯，不能硬切）：Keychain 服务名、`~/Library/Application Support/<AppName>/SpeechRail.json`。
- **一个绝不能改的命名空间**：内容 ID `lotm.*`（403 文件 / 1089 次），改了会作废全部批准、provenance 与哈希绑定链。
- **不需要改任何顶层规范文档**：实测 `docs/*.md`（规范/侧车类）**零命中**；命中的全部是 `docs/superpowers/`、`docs/research/`、`docs/reviews/`、`apps/.../docs/qa/` 等历史或草稿层，按仓库规矩**保留原文**。

### 0.1 前置依赖：并发的资源治理重构（必须先落地）

实测（2026-09-15）发现并行进行中的资产治理重构，直接改变本计划的两处假设：

- `apps/LotmCardStudio/Resources/Audio`（66）与 `Resources/CardArt`（11）**已从工作树移除并暂存删除**（77 个删除条目，源文件仍保留在 `artifacts/**` 与 `.build` 产物中）。
- `apps/LotmCardStudio/scripts/build-app.sh` 已改为调用
  `python3 tools/production.py stage-app-resources --dest "$APP_BUNDLE/Contents/Resources"`
  ——即 app 资源改为**从 artifacts 单源构建期装配**，不再在仓库里存第二份。
- 依据：`docs/superpowers/plans/2026-09-14-pipeline-22-pathway-optimization/05-asset-namespace-and-size.md`（T2 双拷贝取舍 + T3 体积预算）。

**因此**：改名计划与资源治理重构**不得交叉执行**。资源治理（含 `stage-app-resources` 的验证）先落地并确认可产出完整 `.app`，再开始批次 2；否则目录改名会与 build-app.sh / production.py 的重构撞车。批次 4/5 的构建验证一律走 **新机制**，不再引用 `apps/<App>/Resources/{Audio,CardArt}`。

## 1. 实测冲击面（按处置分组）

### 1.1 必须改

| 面 | 位置 | 量 |
|---|---|---|
| Swift 包定义 | `apps/LotmCardStudio/Package.swift` | 5 个 target + 6 条 path |
| Swift 源码 | `Sources/LotmCardStudio/`（executable）、`Sources/LotmCardStudioCore/`、`Sources/LotmCardStudioFeatures/` | 24 文件 / 26 次（模块名、import、`LotmCardStudioApp`） |
| Swift 测试 | `Tests/LotmCardStudioCoreTests/`、`Tests/LotmCardStudioFeaturesTests/` | 12 文件 / 22 次 |
| 应用元数据 | `Resources/Info.plist`：`CFBundleDisplayName`（现「诡秘卡牌画册」）、`CFBundleIdentifier`（`com.hrygo.lotm-card-studio`）、`CFBundleName`、`CFBundleExecutable` | 4 键 |
| 窗口标题 | `Sources/LotmCardStudio/LotmCardStudioApp.swift`：`WindowGroup("诡秘卡牌画册")` | 1 |
| 打包脚本 | `scripts/build-app.sh`：`--product`、`--show-bin-path`、`.build/*.app`、`Contents/MacOS/*` | 5 处 |
| 忽略规则 | `.gitignore`：`apps/LotmCardStudio/.build/`、`.swiftpm/` | 2 行 |
| CI | `.github/workflows/ci.yml`：`working-directory: apps/LotmCardStudio` | 1 |
| 根文档 | `AGENTS.md`（8）、`apps/AGENTS.md`（5）、`tests/AGENTS.md`（4）、`apps/LotmCardStudio/README.md`（21，随目录移动） | 38 |
| 根 README | `README.md`：标题、badge 链接、目录结构、命令 | 13 |
| 项目技能 | `.agents/skills/lotm-card-production-sop/references/operational-checklist.md`：~~`apps/LotmCardStudio/Resources/Audio/`~~（该路径已随 0.1 的资源治理消失，须改指 `production.py stage-app-resources` 机制） | 1 |

### 1.2 改，但必须带迁移阶梯（静默破坏点）

| 面 | 现值 | 迁移策略 |
|---|---|---|
| Keychain 服务名 | `com.lotm.cardstudio.speechrail`、`com.lotm.cardstudio.speechrail.touchid` | 新增 `com.hrygo.world-of-mysteries.speechrail[.touchid]` 为首选，**旧名保留为 legacy 并保持可读**；复用 `SpeechRailCredentialStore` 现有的 `legacyService → protectedService` 阶梯模式（该文件已是两级阶梯，改名后成三级） |
| SpeechRail 配置文件 | `~/Library/Application Support/LotmCardStudio/SpeechRail.json`（`SpeechRailConfigurationFileStore.defaultFileURL` 硬编码目录名） | 新路径 `.../WorldOfMysteries/SpeechRail.json`；**读取时回退旧路径**，写入走新路径；首次成功读旧文件后可提示迁移，不静默删除旧文件 |

### 1.3 建议保留（本次排除，理由须写入 D18）

| 面 | 位置 | 量 | 排除理由 |
|---|---|---|---|
| **内容 ID 命名空间 `lotm.*`** | `production/`、`pathways/`、`artifacts/lotm.*/`（12 目录）、`production/approvals/*`、`production/cards/*`、`apps/**/DemoContent.swift`、`production/schemas/card-narrative.schema.json` 的 `slotID` pattern | **403 文件 / 1089 次** | 卡 ID 是稳定标识（AGENTS「ID 不随中文名修订而改变」）；批准 sidecar 按 `card_id` + sha256 绑定卡图与 provenance，门禁校验 `card_id == f"lotm.{slug}.primordial-01"`。改名会**作废全部批准与哈希链** |
| 内容生产 schema `$id` | `production/schemas/*.json`（`lotm-card-art/...`）、`config/project.json` 的 `project_id` | 4 schema + 1 | 属内容层稳定命名空间；`generated/` 产物内嵌引用。按 PRD §25「内容体系保持独立职责」，内容层保留自己的命名空间更安全 |
| 项目技能名 | `.agents/skills/lotm-foundation|hierarchy|subject|symbols|quality-frames|card-production-sop/` | 6 个 | 内容生产层身份；改名会牵动 harness skill 名、根 AGENTS 与所有引用。属可选后续清理，不混入本次 |
| 历史/草稿文档 | `docs/superpowers/**`、`docs/research/**`、`docs/reviews/**`、`apps/.../docs/qa/**` | 20+ 文件 | 仓库规矩：历史文档保留原文、不回写；改动只以**新日期小节追加** |

### 1.4 非代码面

| 面 | 处置 |
|---|---|
| 品牌资产 | `Resources/AppIcon.icns`、`Assets.xcassets`、`logo.png`、`logo_128.png`、`docs/assets/logo_160.png`：本次**只跟随路径改名**；图标/标志重绘属设计任务，不在本计划 |
| 已安装包 | `/Applications/LotmCardStudio.app` 与 `~/.Trash/LotmCardStudio-*.app` 多份 |
| GitHub 仓库 | `hrygo/lotm-card-art`：README badge、`.github/ISSUE_TEMPLATE/config.yml`（3 URL）、`SECURITY.md`（1 URL）。GitHub 改仓库名后旧 URL 自动重定向（旧名未被新仓库占用时） |
| 构建缓存 | `.build/`、`package.resolved`：自动重建，无需处置 |

## 2. 分批执行计划

> 每批 = 一次提交，独立验证；批内失败即回滚该批，不影响已完成批次。

### 批次 0 — 决策落盘（纯文档）
- `docs/DECISIONS.md` 新增 **D18**：改名决策（中英文名、标识符方案、范围排除项及其理由、Keychain/配置路径迁移策略、历史文档不回写）。
- 验证：`pin_seal.py --check`（112 条）、`cardctl.py check --level scaffold`。

### 批次 1 — 仓库与文档标识（不动代码）
- 根 `README.md`（标题、badge、结构树、`cd` 命令）、`SECURITY.md`、`.github/ISSUE_TEMPLATE/config.yml`、`.github/workflows/ci.yml`、`.gitignore`、根 `AGENTS.md`、`apps/AGENTS.md`、`tests/AGENTS.md`、技能 checklist 路径。
- 不含 `config/project.json` 与 schema `$id`（见 1.3 决策）。
- 验证：`pin_seal.py --check`；链接/路径 grep 无死链（`grep -rn "apps/LotmCardStudio"` 应为空，除历史层）。

### 批次 2 — Swift 包与模块改名（纯代码，不碰元数据）
- `apps/LotmCardStudio` → `apps/WorldOfMysteries`；target/模块：`WorldOfMysteries`、`WorldOfMysteriesCore`、`WorldOfMysteriesFeatures`、`WorldOfMysteriesCoreTests`、`WorldOfMysteriesFeaturesTests`；目录名与 `Sources`/`Tests` 同步；`LotmCardStudioApp` → `WorldOfMysteriesApp`；全部 `import` 同步。
- **不含** Info.plist、窗口标题、build-app.sh、Keychain（留给批次 3）。
- 验证：`swift build` + `swift test`（**87 passed / 0 failures 基线必须保持**）。

### 批次 3 — 运行时标识与迁移阶梯
- `Info.plist`：`CFBundleDisplayName 诡秘世界`、`CFBundleIdentifier com.hrygo.world-of-mysteries`、`CFBundleName`/`CFBundleExecutable` `WorldOfMysteries`。
- 窗口标题 `WindowGroup("诡秘世界")`。
- `build-app.sh`：product 与 `.build/WorldOfMysteries.app`。
- Keychain：新服务名 + 旧名 legacy 阶梯（三级）。
- `SpeechRailConfigurationFileStore`：新路径 + 旧路径只读回退。
- 新增测试：**改名前的 keychain 项仍可读**、**改名前的 SpeechRail.json 仍可读**（防回归）。
- 验证：`swift test`（基线 + 新增用例）；人工确认旧路径/旧 key 场景。

### 批次 4 — 全量验证
- `cardctl.py check --level scaffold`、`python3 -m unittest discover -s tests`、4 条 `check-fool-*` 门禁、`pin_seal.py --check`、`swift test`、`build-app.sh debug` **→** `release`（release 收尾，只有 release 配置会签名）。
- `.app` 内容核验：11 张卡图 + 66 WAV、arm64、`LSMinimumSystemVersion 26.0`、`codesign --verify --deep --strict`、`diff -rq` 与构建产物一致。

### 批次 5 — 安装迁移与验收记录
- 旧 `/Applications/LotmCardStudio.app` 移入 `~/.Trash/`（不用 `rm`）→ 安装 `WorldOfMysteries.app` → 启动冒烟（启动 → 存活 → 正常退出 → 无崩溃报告）。
- `apps/.../docs/qa/m1-local-run.md` **追加新日期小节**记录改名迁移与本轮验证数字；**不改写**任何历史小节。
- 验证：安装后 codesign/资源/架构核验 + 冒烟。

### 批次 6 — GitHub 仓库改名（独立、可选）
- `hrygo/lotm-card-art` → `hrygo/world-of-mysteries`；同步 badge 与 3 处 issue template URL、`SECURITY.md` URL。
- 前置：确认旧名不会被新仓库占用（否则重定向失效）。
- 验证：CI 在改名后仍能跑通；本地 remote 更新。

## 3. 风险与前置约束

1. **顺序约束**：批次 2/3 必须先于批次 5，否则安装包名与 product 不匹配。
2. **用户数据风险**：当前无 SwiftData/收藏持久化，真正会被改名影响的用户数据只有 **Keychain 项**与 **SpeechRail.json** 两处；两者都必须走阶梯回退，禁止硬切。
3. **批准链不可动**：内容 ID `lotm.*`、批准 sidecar、provenance 哈希绑定均不在改名范围；改名不得触碰 `production/approvals/**`、`production/cards/**`、`artifacts/**`、`pathways/**`。
4. **历史文档不回写**：旧名出现在历史/草稿层是事实记录，保留。
5. **签名**：`build-app.sh` 只在 `release` 配置签名；任何批次收尾都必须是 `release` 构建。
6. **一次性完成**：改名在有真实用户数据之后执行会变成数据迁移；本计划的价值在于此刻成本最低。
7. **与资源治理重构互斥执行**：见 §0.1。`stage-app-resources` 未验证通过前，不开始批次 2。
8. **不触碰他人暂存区**：工作区已有并发的暂存删除（77 个资源条目）与多处未暂存改动；本计划任何批次都不得 `git add -A`、不得提交或还原他人的改动。

## 4. 待你确认的三个子决策

1. `config/project.json` 的 `project_id: "lotm-card-art"` 与 4 个 schema `$id`：**保留**（推荐，内容层命名空间）还是随仓库改名？
2. 6 个项目技能名 `lotm-*`：本次不动（推荐）还是纳入改名？
3. GitHub 仓库改名：本计划内执行（批次 6）还是暂缓、只改本地与文档？

## 5. 执行前提

- 用户批准本计划后，从**批次 0** 开始，逐批推进并在每批末汇报验证结果；批间不跳步。
- **前置**：§0.1 的资源治理重构先落地且 `stage-app-resources` 验证可产出完整 `.app`（11 卡图 + 66 WAV），再进入批次 2。
- 本文件在批准前不产生任何代码或契约变更。
