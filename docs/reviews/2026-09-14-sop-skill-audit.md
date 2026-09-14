# SOP 与生产 Skill 全面审查记录

日期：2026-09-14

状态：整改完成；当前愚者 S09/S00 候选已作为完整卡包接入 App，叙事与配音已更新，视觉批准、最终采样和正式 release 仍未因此自动完成。

## 审查范围

本次审查覆盖：

- `docs/production-sop-v2.md`
- `docs/pathway-carrier-sop.md`
- `docs/production-preflight.md`
- `.agents/skills/lotm-foundation/SKILL.md`
- `.agents/skills/lotm-hierarchy/SKILL.md`
- `.agents/skills/lotm-quality-frames/SKILL.md`
- `.agents/skills/lotm-symbols/SKILL.md`
- `.agents/skills/lotm-subject/SKILL.md`
- `.agents/skills/lotm-card-production-sop/SKILL.md`
- `production/schemas/emblem-dock.schema.json`
- `production/templates/emblem-dock-interface-v1.json`
- `production/symbols/fool-layered-asset-baseline-v1.json`
- `production/cards/fool-card-candidates-v1.json`
- `production/cards/fool-card-visual-review-v1.json`
- `production/cards/fool-final-sampling-v1.json`

静态清单扫描项目根目录得到 34 份逻辑指令/Skill 文档、34 份物理文档、5 个项目 Skill 入口，未发现断链事件。审查以文档之间的真实引用、职责边界和已知失败模式为依据，不把静态扫描当作运行时或视觉质量证明。

## 审查发现与整改

### 1. 状态词曾分散，容易把“生成过”误认为“可交付”

SOP 原有 `study`、`candidate`、`approved`、`release` 的使用口径分散在多个段落，EmblemDock 合同又有自己的 `status`，容易出现模板齐全但资产未测量、视觉通过但未 release 的误读。

整改：在 SOP 增加统一状态表，区分 `study`、`candidate`、`measured`、`approved`、`release`，并明确合同状态不能代替文案、音频或正式发布状态。

### 2. 生产顺序仍偏线性，没有明确上游锁点

如果没有锁点，姓名、单枚圣徽或主体背景失败时容易重生整框，造成重复生图和批准失效范围扩大。

整改：增加 L0–L6 锁点，明确每个锁点冻结什么、通过后可继续什么，以及几何变化会使哪些下游失效。后续任务必须沿资产图向下重放，不回头重做无关上游。

### 3. 缺陷路由不够机械化

此前虽有“保留其他层”的原则，但没有把“谁负责修、谁不能被顺手重做”固化成表格。

整改：新增最小返修矩阵：母版几何、嵌座材质、单枚圣徽、精确文字、主体场景、角色叙事分别归属明确节点，并列出必须保留和必须重新检查的下游。

### 4. EmblemDock 合同只有结果字段，没有统一硬阈值

仅记录 `geometry_displacement_px` 等检查结果，无法保证不同 Agent 使用同一拒收标准。

整改：为合同增加不可变 `thresholds`：几何位移、孔洞/姓名/钻石交集、域外像素均为 0；圣徽可见 bbox 中心误差不超过 1 final px；v1 明确禁止真实穿透孔。

### 5. 版本号写入 Skill，容易与实际 catalog/manifest 脱节

Skill 中固定写 `v3/v4/v5` 会在新版本出现后继续误导 Agent，且版本号不是 Skill 应该拥有的事实。

整改：质量框和层级 Skill 改为要求从 catalog/manifest 读取实际渲染器版本；愚者侧铭文章节去除易过期的 `v3` 标题。历史版本仍保留在计划、回执和产物目录中。

### 6. 历史愚者实例与新通用架构的边界曾不够醒目

历史克莱恩实例采用无中央托座，而新定稿要求母版提供 EmblemDock；如果不标注时间和批准范围，未来容易误把历史实例规则当作通用规则。

整改：所有相关 Skill/SOP 明确：历史实例不回写；新母版使用 `FrameCore + EmblemDock`；愚者帷幕只是途径形态示例，不是所有途径的固定模板。

### 7. 主体 Skill 对“独立主体”和“完整卡候选”的职责边界仍有歧义

如果把完整带框卡面同时当作主体输出参考和主体结果，后续 Agent 容易回到旧的局部拼装路径，或把主体候选误登记为正式卡面。

整改：`lotm-subject` 现明确：独立 `kind=subject` 任务只产主体/环境候选；完整愚者卡由独立 Agentic 整卡终段负责，输入整框与主体参考并在同一原生画布中保持连续关系。框架文字不属于主体插画区域，但完整卡终段必须负责逐字校对。

### 8. Skill 修订后任务契约 hash 必须同步，不能以忽略失败维持绿色

本次 Skill 修订首次触发 S00/S09 任务快照的旧 hash 拒收，证明验证器确实拦截了过期契约。

整改：更新两个当前任务的 Skill contract hash，并分别重新编译 S00/S09 任务快照；不重生图像、不覆盖旧 receipt，保留历史生成事实。专项测试从失败恢复为通过。

### 9. 最终采样需要独立的批准队列和 receipt 门禁

仅在 SOP 中描述“最终一次采样”仍可能被临时脚本绕过，尤其容易误把待审候选直接放大或把 2K 结果继续放大到 4K。

整改：新增 `production/cards/fool-final-sampling-v1.json`、`finalize` 和 `check-final-sample`。工具只接受清单中有真实用户视觉批准的完整 `1024×1536` 原生卡，并强制零裁切、零中间 2K、每个输出一次整幅变换和最终 `sRGB` 标记；receipt 绑定批准清单、当前候选清单及源图 hash，正式 release 仍独立保持 false。真实 `sips` 标准/收藏沙盒采样已验证该链路。

### 10. Agent 视觉预审必须与候选图绑定，但不能冒充用户批准

如果视觉观察只写在回复中，后续无法确认观察对应的是哪一版图；如果把 Agent 的“未见明显缺陷”写成批准，又会绕过用户审美门槛。

整改：新增 `production/cards/fool-card-visual-review-v1.json`，并由 `check-fool-cards` 校验两张候选的 ID、源图 hash、尺寸和 pending 状态与预审记录一致。预审仍明确标记为 Agent observation，用户批准字段保持空值。

## 当前统一规则

```text
L1 母版几何
  ├─ FrameCore
  └─ EmblemDock（视觉嵌孔、暗腔、承托、前缘遮挡）
        ↓
L2 独立圣徽本体（途径标识 + 序列数字）
        ↓
L3 精确文字层（途径名、序列名、姓名）
        ↓
L4 身份框
        ↓
L5 主体与完整环境
        ↓
L6 确定性合成、门禁、批准与 release
```

母版拥有结构，圣徽拥有识别形体，合成器拥有装配；任何结构像素只能有一个 owner。默认使用视觉嵌孔，不让主体背景透出；Agentic 负责完整视觉创作，确定性工具负责登记、原生测量、摘要、必要的回放和最终整幅采样，不把局部文字编辑误认为零漂移。

App 接入采用卡包原子边界：身份 `cardID/slotID/characterID/identitySliceID`、当前卡图、六维回读、叙事 `cardID`、音频状态和收藏意图必须一起更新；删除旧卡图时同时删除旧资源名与兼容映射，不留下“旧图 + 新身份”的半套状态。当前 App 只保留最新 S09/S00 两个完整卡包，各自含 6 条新版文案与 6 个本地 WAV。与本次愚者卡无关的正义小姐源资产不随 App 清理：原始插画、六维源、人物故事研究和六条 WAV 继续保留在 App 外生产目录。

当前 `LotmCardStudio` 仍是 M1 静态 fixture，尚未提供用户导入/删除 API；因此新增或删除的边界先由 `AlbumCard` 的原子字段与 `AlbumViewModel` 的派生收藏/愿望状态锁定。未来接入持久化时，操作对象必须是完整卡包，不允许分别写卡图、收藏记录、故事或音频状态。

## 已执行验证

- 项目 instruction inventory：通过，未发现断链事件；仅作静态证据。
- `emblem-dock.schema.json` 自身 schema 检查：通过。
- `emblem-dock-interface-v1.json` 按 schema 验证：通过。
- 五个项目生产 Skill 的 `skill-creator` quick validation：通过。
- 通用 `lotm-card-production-sop` 的 `skill-creator` quick validation：通过。
- `python3 tools/cardctl.py check --level scaffold`：通过，22 条途径、220 个序列卡位。
- `python3 tools/production.py check-fool-materials`：通过，五档、十序列、十融合参考、五项可复用材质和清理账本一致。
- `python3 tools/production.py check-fool-cards`：通过，S09/S00 两张完整原生候选的任务、回执、叙事和摘要一致；正式release仍为 false。
- `python3 tools/production.py check-fool-carrier`：当前执行器以 `fool-carrier-execution-v1.json` 校验 RankNumeralDock、等边六边形宝石、保护域和零漂移阈值；通用 EmblemDock 模板只作为非穿透结构语法。
- `foolpipeline5 selftest`、母版/五档/十序列阶段测试：通过，三个阶段均绑定当前载体执行合同，未启用穿透孔或重复圣徽覆盖。
- `python3 tools/production.py check-fool-cards`：通过，S09/S00 两张完整原生候选、最终采样批准队列的任务、回执、叙事和摘要一致；正式release仍为 false。
- `python3 tools/production.py check-content production/narratives/mr-fool-s00.json` 与 S09 内容检查：通过；两包六条目均有当前 draft 指纹，未伪造逐字批准。
- `python3 -m unittest discover -s tests -v`：通过，168 tests，OK（skipped=6）。
- `tests.test_fool_agentic_pipeline`、`tests.test_fool_card_validation`、`tests.test_fool_material_validation`：通过，24 tests，验证 Skill contract 同步、候选门禁、候选清单绑定、最终采样拒绝/成功路径和清理账本。
- 真实 `sips` 临时沙盒：standard `2048×3072` 与 collector `4096×6144` 均通过，输出带 `sRGB`，receipt 独立检查通过，临时目录已删除。
- App 卡包回归与安装验收：当前 S09/S00 的身份、图像资源、叙事绑定、候选状态和音频状态测试通过；debug/release 重打通过，`/Applications/LotmCardStudio.app` 签名校验通过，安装包内两张当前卡图 SHA 与生产候选源一致，旧资源名不再存在。
- 正义小姐 App 外保留验收：`artifacts/lotm.visionary.s07/render-v001/` 原图与派生图、`pathways/visionary/sequences/07/card.json` 六维源、研究/故事边界文档及 `audio-v001/` 六条 WAV 均存在；本次清理未触碰。
- Markdown 相对链接检查：通过。
- `git diff --check`：通过。

## 未完成事项

- 通用 `EmblemDock` 模板仍只负责跨途径的非穿透结构语法；当前愚者路线已经由 `production/symbols/fool-carrier-execution-v1.json` 固定 RankNumeralDock、等边六边形宝石、保护域和零漂移阈值，并由 `foolpipeline5.swift` 在母版、五档和十序列阶段实际读取、绑定和门禁。其他途径仍需各自建立并实测自己的执行合同，不能把愚者合同泛化。
- 当前愚者五档完整框和十张完整序列框已登记为用户批准的视觉基线，但尚未取得正式 release 批准。
- App 当前没有独立的用户新增/删除界面；已将完整卡包字段、收藏/愿望状态派生和资源边界写入领域模型与回归测试，后续持久化不得拆包操作。
- S09 克莱恩·莫雷蒂与 S00 愚者先生已有完整原生候选；S09 的局部姓名编辑实测为全图重绘，已拒绝作为零漂移局部层；两张卡均等待用户视觉验收。
- 最终采样工具已就绪，但批准队列仍为 pending，因此尚未生成 `2048×3072` / `4096×6144` 文件；不得用机器门禁替代用户批准。
- 生产源中的 S09 与 S00 已更新为当前 6 条新版叙事，摘要和 `--ready-for-audio` 均通过；12 个 WAV 已由本机 SpeechRail 生成并完成格式、时长、哈希和 App 白名单校验。两张卡仍是视觉候选，不因文案和配音完成而自动进入正式 release。
- 最终 `2048×3072` / `4096×6144` 采样尚未执行，符合“完整卡批准后再一次采样”的当前 SOP。

## 2026-09-14 最新执行增量：S00/S09 叙事、配音与 App 卡包

本节只记录本轮完成后的当前事实；前文较早的检查条目保留为审查过程快照，若出现旧数量或旧审核状态，以本节和生产源为准。

- 当前 App 白名单只允许两张愚者途径候选卡：S09 `克莱恩·莫雷蒂` 与 S00 `愚者先生`；旧 S03/正义小姐 App 资源已移出 App。正义小姐的 App 外源资产仍通过独立保留检查。
- 两张卡的结构化叙事包已更新为新版问候语、口头语和三章故事；每张 6 条，均逐条绑定当前 digest 并标记 `NarrativeReview.approved`。对应 Swift 领域模型、生产 JSON 和音频 manifest 的 `cardID` 一致。
- SpeechRail 本机 loopback 生成 12 个当前 WAV：S09 使用 `dylan`，S00 使用 `uncle_fu`。音频生成记录保留服务版本、文本 digest、SHA-256、采样率、声道和时长；不落盘或输出 API key。
- `python3 tools/production.py check-fool-audio` 实测通过：2 张卡、12 个 WAV、2 张卡图，生产源与 App 资源哈希一致，未发现缺失、孤儿、旧白名单名或格式不符资源。
- `swift test --verbose` 实测 76/76 通过；Debug/Release 构建通过；安装版 `/Applications/LotmCardStudio.app` 的 `LSMinimumSystemVersion=26.0`、Mach-O `arm64`、深度签名校验均通过。CUA 已确认当前画廊只显示两张卡，S09 新故事和 S00 新问候语可进入播放状态。
- 当前 App 卡包校验已成为运行时模型与生产门禁的双重约束：身份、卡图、六维回读、叙事、音频与清单意图缺一不可。仍不提供拆包式新增/删除 API。

本轮完成的是内容与音频接入及资源边界收口，不等于视觉正式批准。S00/S09 仍为视觉候选；最终采样和正式 release 继续等待用户视觉验收，不能由自动化门禁代替。
