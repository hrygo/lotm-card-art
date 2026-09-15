# apps/ 目录工作约定

本目录承载 macOS 客户端代码、资源与运行说明；更细的运行/构建说明见 `apps/WorldOfMysteries/README.md`，验收记录见 `apps/WorldOfMysteries/docs/qa/`。
当前 `WorldOfMysteries` 已完成 M1 里程碑垂直切片（画廊、详情页、三类清单、故事抽屉、SpeechRail 接口）与 M2「世界外壳」（世界 / 卡牌 / 人物 / 故事书四个一级区域、人物档案、故事书命运详情、卡牌详情命运入口与命运生成界面）。导入、SwiftData 用户库、批量正式资源、音频缓存和游戏规则尚未实现；当前包含 S00 愚者先生、S09 克莱恩·莫雷蒂，序列之上·诡秘之主的福生玄黄天尊、序列之上·星界支柱的上帝、序列之上·现实支柱的堕落母神，以及永恒之暗、恶魔之父、毁灭天灾、失序者、知识之妖、光之钥六位「序列之上」旧日，共十一套隔离候选卡包，不要把 M1/M2 fixture 描述为完整产品。十一张卡的新增、替换和删除必须按身份、卡图、六维回读、故事、音频状态和清单意图的整套卡包执行；九位「序列之上」存在均为非序列卡位（`lotm.celestial-worthy`、`lotm.god-almighty`、`lotm.mother-goddess-depravity`、`lotm.eternal-darkness`、`lotm.father-of-demons`、`lotm.destruction-calamity`、`lotm.embodiment-of-disorder`、`lotm.demon-of-knowledge`、`lotm.key-of-light`），不占 22×10 序列卡槽；正义小姐 App 外源资产须保持独立保留。

M2 世界外壳由**合成示例世界**（`SampleWorld`）驱动：世界时间、事件、经历、关系与秘密都是为验证界面写的示例数据，只存在于 App 进程内。它们不得写回 `pathways/**`、`canon.json`、`sources/registry.json`、`artifacts/**` 或任何批准记录，界面上「示例」标记不得移除。按 D17，World / Character / Story / Audio 引擎不属本仓库实现范围：客户端只做运行时投影，不生成故事、不裁定 Canon。界面目标与交互契约见 `docs/product/macos-ux-interaction-prd-v1.0.md`（M3 及之后依赖引擎立项）。

## 开发基线
- 最低部署版本 macOS 26 Tahoe；不维护 macOS 14 兼容路径或旧系统 fallback。
- 直接使用当前 SDK 的 macOS 26 SwiftUI 能力（Liquid Glass、系统导航、toolbar、search 语义）；只有目标高于 macOS 26 时才加显式可用性分支。
- 构建、QA 与 `.app` 元数据必须以 macOS 26.0 为最低版本；不能用宿主机能运行当作 deployment target 已切换的证据。

## 数据边界
- 客户端示意内容必须保持为合成 fixture，不得冒充已核验正典；十一张卡已获用户视觉批准（`user-visually-approved`）并在客户端作为正式收藏呈现，但内容是待核验 fixture，批准不等于发布（`release_approved` 仍为 false）。
- `card_id`、`slot_id`、`character_id`、`identity_slice_id`、内容状态与叙事审批状态各自承担独立职责。
- App 是内容源的运行时投影；不得把用户收藏、笔记、密钥、缓存或运行状态写回公开卡牌源文件。
- SpeechRail 仅允许本机 loopback（默认 `http://127.0.0.1:8201`），不调用云端，不自动启动/停止/下载服务。
- 未通过人工批准摘要校验的台词或章节不得播放；服务失败时保留文字稿，不伪造播放成功。

## UI 施工约定
- 详情页的主卡面、身份面板和故事抽屉必须使用正常布局流；不得用固定高度、绝对定位或隐式叠放掩盖容器重叠。
- 故事抽屉独立维护章节显示文本，唤醒问候语不能覆盖第三人称故事文字。
- `220` 是序列卡槽基线，不是客户端收藏分母或卡片上限：同一序列可有多个不同人物的身份卡，同一人物可有跨多个序列的形象卡，实际卡数可超过 220。同一角色可以有多张独立身份卡；聚合展示不能合并 `card_id`、收藏记录或播放状态。
- 世界外壳的「在世界里的位置」（未进入世界 / 有一段进行中的命运 / 已有 N 段历史）与内容核验状态是两个独立维度，不得合并成同一个标签。
- 叙事界面不得显示引擎数值：灵性、暴露、危险、污染等只能以文学化提示出现；数值视图如需保留，只能放在默认隐藏的诊断入口。
- 新增交互优先补领域/视图模型测试，再修改界面；避免空操作按钮，未实现的途径入口应明确置灰。
- 卡图解码不得落在主线程或帧提交路径上：视图 `body` 不读文件、不解码、不做图像缩放，一律经 `ArtworkStore` 后台解码并按「瓦片档 / 详情大图档」缓存（决策见 D22 / D23，契约见 UX/Interaction PRD §4.7）。
- **App 内不放母版**：卡图成片在打包时由 `tools/production.py stage-app-resources` 从 `artifacts/**` 母版生成（`APP_IMAGE_TIERS`：tile 800×1200 / hero 1024×1536，只缩不放，且不得低于 `APP_IMAGE_DISPLAY_MINIMUM_LONG_EDGE`），**运行时零图像处理**——不得在客户端重新引入缩略图上限、按需缩放或读 PNG 母版。网格列宽上限（`albumTileMaxDisplayWidth`）必须落在瓦片档的显示覆盖内，两处的自洽由 `tests/test_app_image_staging.py` 反查。
- 两档缓存都按**字节成本**限流（不是按张数），并响应系统内存压力丢弃解码结果。多个 `glassEffect` 用 `GlassEffectContainer` 合并渲染时，容器 `spacing` 必须小于内部布局间距，否则相邻玻璃静止即融合。

## 验证与提交
- 在 `apps/WorldOfMysteries` 执行 `swift test`、`./scripts/build-app.sh debug` 和 `./scripts/build-app.sh release`。
- 修改布局或播放流程后，必须进行一次 `.app` 人工验收，并更新 `apps/WorldOfMysteries/docs/qa/m1-local-run.md` 或对应阶段记录（世界外壳见 `m2-world-shell.md`）；机器测试与构建通过不能替代人工视觉验收。
- `.build/`、`.swiftpm/` 和本机签名产物是生成物，不提交到 Git；资源文件是否存在必须由打包脚本显式处理。卡图与音频以 `artifacts/**` 为唯一真源，不在 `Resources/` 内重复存放；打包脚本经 `tools/production.py stage-app-resources` 按登记表落资源（卡图在该步骤按档生成 JPEG 成片，母版 PNG 不入包），不得另写第二份资源登记表。
- 不在客户端源码、fixture 或日志中写入令牌、私钥或真实人物隐私资料。
