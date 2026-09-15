# M1 本机验收记录

日期：2026-09-13

## 验收范围

- 书架画廊：动态身份卡数量、已确认/正式/候选统计和未填充卡位。
- 卡牌详情：大卡面、身份语义面板、故事抽屉与 SpeechRail 失败回退。
- 布局修复：故事抽屉作为详情主内容的垂直兄弟节点参与正常布局，不覆盖身份面板。
- 实时字幕：语音控制区下方的字幕轨、故事全文入口与当前章节状态标记。
- macOS 26 UI：`NavigationSplitView`、toolbar search、Liquid Glass 控件与背景延展效果。
- SpeechRail 凭据闭环：启动不访问钥匙串、Settings 配置文件状态、0600 写入和远程失败回退。

## 自动化结果

在仓库根目录的 `apps/LotmCardStudio` 执行：

```text
swift test
Executed 51 tests, with 0 failures
Swift Testing runner diagnostic: Target Platform: arm64e-apple-macos14.0 (0 tests in that runner; package test binary target is verified as macOS 26.0 below)
```

## macOS 26-only 切换验收

- `Package.swift` 使用 Swift tools 6.2、`.macOS(.v26)` 和 Swift language mode 6。
- release `.app` 的 `Contents/Info.plist` 为 `LSMinimumSystemVersion=26.0`。
- release Mach-O 为 `arm64`，`LC_BUILD_VERSION` 为 `minos 26.0`、SDK 26.5。

```text
./scripts/build-app.sh debug
输出：apps/LotmCardStudio/.build/LotmCardStudio.app
```

```text
./scripts/build-app.sh release
输出：apps/LotmCardStudio/.build/LotmCardStudio.app
产物：Mach-O 64-bit executable arm64
```

```text
codesign --verify --deep --strict --verbose=2
valid on disk
satisfies its Designated Requirement
```

仓库级回归：

```text
python3 -m unittest discover -s tests -v
Ran 48 tests in 32.723s
OK
```

## 之前基线手动结果

- `.app` 可启动并显示书架画廊；统计数字显示为实际值，不再出现 Swift 插值字面量。
- “我的收藏”“候选收藏”“愿望清单”三个入口分别能筛出对应卡牌；未实现的途径入口明确置灰。
- 点击示意卡进入详情页后，主卡面与身份面板正常显示。
- 打开“查看故事”后，故事抽屉出现在身份面板下方并可通过滚动查看，没有容器重叠。
- 唤醒问候语失败时不会覆盖故事抽屉中的第三人称章节文字。
- 音频接入前点击“唤醒卡牌”会真实尝试 loopback SpeechRail；历史服务端失败路径仍保留文字稿，当前代码会将 401 显示为配置文件缺失或无效，未伪造播放成功。

## S00 音频更新验收

- 用户批准的 6 条文案已绑定 `NarrativeReview.approved`，`uncle_fu` 作为实际系统音色；草稿直通播放入口会被拦截。
- 6 个源 WAV 和 6 个 `.app/Contents/Resources/Audio/` 资源均为有效 `RIFF/WAVE`，24 kHz、16-bit、mono；打包后 SHA-256 与源资产一致。
- macOS Keychain 已发现旧条目 service `com.lotm.cardstudio.speechrail` / account `api-key`；当前 App 不读取、迁移或删除该条目。运行时配置文件路径为 `~/Library/Application Support/LotmCardStudio/SpeechRail.json`。
- release `.app` 已覆盖安装至 `/Applications/LotmCardStudio.app`，进程已成功启动。
- 本轮已在解锁后的已安装版 App 中通过 CUA 实测点击“唤醒卡牌”：未再次出现钥匙串密码框，AX 状态显示“正在讲述/正在播放”及字幕，随后已停止试听；三章逐章播放仍未覆盖。
- 最终 release 冷启动后再次确认没有钥匙串密码框；打开无本地音频的小丑卡并点击“唤醒卡牌”，AX 显示“文字稿保留 · 问候语 · 声音不可用 · SpeechRail API key 缺失，请在设置中配置文件”，没有触发旧 Keychain 读取。

## SpeechRail 配置文件闭环

- 静态与单元测试确认：`SpeechRailConfiguration.makeClient()` 只捕获异步 file provider，不在启动或 client 初始化时读取配置文件；S00 / 奥黛丽本地 WAV 路径在远程请求前结束，不需要凭据。
- Settings 保存 JSON 配置时创建 `Application Support/LotmCardStudio` 目录并设置 `0700`，配置文件设置 `0600`；读取失败、坏 JSON 和空 key 都有稳定错误提示。
- 单元测试覆盖 4 个配置文件行为、3 个设置 ViewModel 行为、7 个旧 Keychain 边界回归、配置文件 provider、错误映射和 3 个懒加载 provider 行为；没有测试读取真实 key。
- 已通过 CUA 检查最终安装版启动、本地 S00 播放和远程缺失配置回退均不弹钥匙串密码框；Settings 菜单入口显示“尚未配置”和实际文件路径，真实 API key 保存尚待用户本人完成，因为自动化不会代填 API key。
- 真实用户操作路径：打开 Settings → 确认配置文件路径 → 输入 API key → 点击“保存到配置文件” → 返回远程卡片触发合成。API key 缺失或 HTTP 401 时文字稿仍保留，并回到 Settings 修正文件。

## 奥黛丽·正义 / S07 更新验收

- 新增独立身份卡 `lotm.visionary.s07.audrey-01`，绑定 `lotm.visionary.s07`、`character_id=audrey` 和 `identity_slice_id=audrey.s07.justice`；未合并到克莱恩或其他角色身份。
- `pathways/visionary/sequences/07/card.json` 已通过 `cardctl.py check --level design --card visionary:07`；途径为观众/空想家，序列名为心理医生，六维事实和视觉载体均已登记。
- 卡面标准档为2048×3072、PNG、sRGB，资源名 `audrey-s07-psychologist-v001`；另保留4096×6144收藏母版候选。标准档由1024×1536原始输出经 `sips -z` 放大，未宣称原生分辨率。
- 新增 6 条用户已确认文案的本地 WAV，使用 SpeechRail `2.5.1 / quality` 的 `serena` 系统音色；均为单声道、24 kHz、Int16，并通过 `afinfo` 解码检查。
- release `.app` 已包含新卡图和 6 个 `audrey-*.wav`；可播放资格仍由 `NarrativeReview.approved` 与内容摘要匹配共同控制。
- 本轮未覆盖奥黛丽卡片的完整点击式验收：仍需打开奥黛丽卡片，验证画廊/详情标题、观众途径标签、故事抽屉和“唤醒卡牌”实际播放。

## macOS 26 UI 更新验收

- 静态源码确认主界面已使用 `NavigationSplitView`；搜索字段已移入系统 toolbar search；卡片、身份面板、故事抽屉、状态芯片与操作按钮使用 `glassEffect`，操作区使用 `GlassEffectContainer`。
- 搜索无结果时显示明确空状态，并支持 `Escape` / “清除搜索”恢复当前清单；侧栏、卡牌、章节和图标播放控件已补充 VoiceOver 标签、状态值与操作提示。
- `.app` 已确认包含 `Assets.car`、`AppIcon.icns`、S00/奥黛丽卡图和 12 个批准试听 WAV。
- 本轮已通过 CUA 实测详情页、故事抽屉、唤醒、字幕、播放与停止状态，并保留了远程 SpeechRail 失败文字稿；画廊/详情切换、toolbar 搜索、卡片点击、Settings 配置保存和三章逐章播放尚未覆盖，因此仍不把本轮记录标记为完整 UI 验收。

## 实时字幕更新验收

- `PlaybackCaption` 保存台词 ID、类型和文本；批准内容进入播放流程后立即可见，SpeechRail 不可用时仍保留文字稿，停止播放时清理。
- 身份面板在“唤醒卡牌 / 查看故事”下方显示字幕轨：空闲、准备、播放、暂停、结束和失败状态均有对应文案；故事台词提供打开故事抽屉的入口。
- 故事抽屉保留完整文字稿，并只对当前播放章节显示“正在讲述 / 已暂停 / 已讲完”等状态；切换章节后播放控件不会误操作上一章节。
- release `.app` 已重新构建并覆盖安装至 `/Applications/LotmCardStudio.app`；签名有效，主程序为 arm64，内含 12 个 WAV 与 2 张卡图。
- 本轮已确认问候语字幕和 SpeechRail 失败回退的文字稿保留；故事播放字幕及 Settings 配置 key 后的远程合成仍需用户手动完成。

## 环境与限制

- 本次执行主机为 Apple silicon arm64，实测系统为 macOS 26.6.2、Xcode 26.6、Swift 6.3.3；不是 M1 实机验收，因此不能把本记录表述为 M1 硬件验证。
- 当前内容为示意 fixture，不代表 220 张正式卡牌或正典资料已完成核验。
- 尚未加入 Xcode 开发者签名、正式资源导入和发行包公证；本轮 SpeechRail `2.5.1` 健康检查与真实 WAV 合成基线已完成，配置文件中的真实 API key 尚需用户本人保存。

## 详情页固定动效围台与信息轨重构

- 2026-09-13：详情页已改为固定 CardMotionViewport 与弹性 DetailRail；围台固定 420×630pt，卡牌本体固定 320×480pt，中心留出横向约 50pt、纵向约 75pt 的动效安全空间。
- 宽窗口使用“围台 + 信息轨”双栏；缩窄窗口后自动切换为“固定围台 + 下方信息轨”的正常布局流，Accessibility 顺序从卡牌元数据进入详情模式和故事内容，未观察到容器覆盖。
- 身份 / 故事使用同一个信息轨切换；身份模式保留 CTA 下方唯一实时字幕轨，故事模式在同一轨内展示章节正文与播放控制，不再追加底部全宽故事面板。
- 六维回读在宽信息轨中使用两列卡片，在窄信息轨中退化为单列；卡牌围台、卡面和文本显式使用普通箭头，侧栏、画册卡片、CTA 和可播放章节使用 pointing hand，禁用项不提供可点击反馈。
- CUA 原生验收已覆盖：打开小丑详情、身份/故事切换、故事播放入口与停止、窗口缩窄和恢复；SpeechRail 配置缺失时显示“声音不可用”并保留文字稿，截图确认固定围台、安全留白、信息轨边界和章节文字可见。
- 自动化：swift test 48/48 通过；仓库级 python3 -m unittest discover -s tests -v 55/55 通过；debug/release 构建退出码均为 0。
- 安装验证：release 已覆盖安装至 /Applications/LotmCardStudio.app；codesign --verify --deep --strict 通过，主程序为 arm64，LSMinimumSystemVersion=26.0。
- 为解除当前工作区的 Swift 6 构建阻断，SpeechRailConfigurationFile 的默认参数从 Self.defaultFileURL 改为明确类型名；相关文件测试已纳入本轮 48 项 Swift 回归。

## 用户文案展示层清理验收

- 2026-09-13：完成主画册、侧栏、卡牌列表、详情页、故事页、播放状态、错误提示和设置页的用户文案审查。
- 移除用户界面的流水线标签、原始 voice ID、`fixture`、`snapshot`、`recipe`、`hash`、`interpretation`、`2:3` 等内部表达；底层 card ID、审批状态、音频资源名仍保留在模型层供程序使用，不再直接渲染。
- 卡牌副标题改为角色与故事导向的自然中文；声音状态改为“可以播放 / 可生成声音 / 等待确认”；故事章节改为“可朗读 / 待确认”。
- 详情页将 `IDENTITY PANEL`、`CHARACTER FAMILY`、`VOICE / SPEECHRAIL`、`SEMANTIC READBACK` 等实现或流程标签替换为“身份信息 / 角色关联 / 声音 / 六维信息”，不显示 `uncle_fu`、`serena` 等原始音色 ID。
- 语音设置保留必要的服务密钥和高级保存位置，但主画册不再暴露服务名称、文件路径或配置实现细节。
- 新增回归测试：Demo 卡牌副标题不得包含流水线术语；内部角色和音色 ID必须映射为用户可读名称；播放和设置错误提示不显示 API key、HTTP、认证实现等内部表达。
- 当前 Swift 全套测试：54/54 通过；仓库级 `python3 -m unittest discover -s tests -v`：55/55 通过。
- 当前 Debug/Release 构建均退出码 0；Release 已覆盖安装至 `/Applications/LotmCardStudio.app`，签名校验通过，主程序为 arm64，`LSMinimumSystemVersion=26.0`。
- CUA 已验收画册首页、愚者详情、愚者故事页和奥黛丽详情；可见文本均为自然中文，未发现脚本语言泄露或原始内部标识。

## 故事面板默认高度对齐验收

- 2026-09-13：故事模式的 `DetailRail` 使用 `CardDetailLayout.storyMinimumHeight`，与固定卡牌围台 `motionViewportSize.height` 共享 `630pt` 几何契约；身份模式不增加该最小高度。
- 新增回归测试 `testStoryModeUsesCardAreaAsDefaultMinimumHeight`，验证故事模式最小高度等于卡牌围台高度，身份模式保持 `0` 的自然布局约束。
- TDD 聚焦测试先以缺少 `minimumRailHeight` 失败，补充布局规则后通过；当前 `swift test` 为 `55/55`，仓库级 `python3 -m unittest discover -s tests -v` 为 `107/107`。
- 本轮 `./scripts/build-app.sh debug` 与 `./scripts/build-app.sh release` 均退出码 0；release `.app` 的 `LSMinimumSystemVersion=26.0`，主程序为 Mach-O `arm64`，`codesign --verify --deep --strict` 通过。
- CUA 重启本次 release 构建后打开小丑详情并切换到故事模式；截图确认右侧故事面板上下边界与左侧卡牌围台对齐，章节正文和播放控件未发生重叠。

## 故事播放器与羊皮纸卷宗更新

- 2026-09-13：故事页新增已确认章节队列导航；上一个/下一个会跳过待确认章节，边界状态自动禁用，不会触发未批准内容。
- 播放控件形成完整闭环：开始（播放中变为暂停、暂停后变为继续）、重播当前章节、停止、上一个和下一个；停止只清理播放状态，保留当前章节文字稿，并复用已经生成的远程音频。
- 故事正文改为与档案馆皮革、黄铜体系相容的旧纸中间调 folio；新增 `ArchiveTheme.Story` 的色彩、排版、间距、圆角和表面 token，控制区仍保持深色信息轨层级。
- 当前 SpeechRail 合约下，每个已批准章节的完整正文对应一次 `/v1/audio/speech` 请求，重播和停止后再次开始复用内存音频缓存，不按句拆分；服务只返回单段音频、没有章节时间轴，因此本轮不宣称整篇单请求可精确跳章。
- 自动化：`swift test` 执行 59 tests，0 failures；新增 `StoryChapterNavigatorTests` 覆盖跳过待确认章节和上下边界，`SpeechPlaybackCoordinatorTests` 覆盖重播/停止后的单次合成复用。
- CUA 最新 release `.app` 实测：故事页可见 folio、章节标题和五个 transport 控件；开始、暂停、重播、下一章、上一章、停止状态，以及停止后正文保留并可再次重播均已确认。

## 身份卡信息与序列文案 UI 审查

- 2026-09-13：按当前 release `.build/LotmCardStudio.app` 逐屏复核画册主页、序列 0 原型卡、序列 7 奥黛丽身份卡、故事抽屉和搜索无结果态；截图与 Accessibility 文案均来自本轮重启后的当前构建。
- 序列展示统一为不补零的用户文案：`序列 0`、`序列 3`、`序列 7`、`序列 9`；`s00` / `s09` 等稳定内部 ID 保持不变。卡牌列表、卡面围台、详情标题、六维身份回读和 VoiceOver 标签均通过同一格式化入口展示。
- 序列层级文字色统一为五档稀有度 token：`低序列（9–8）= 银白`、`中序列（7–5）= 翡翠绿`、`圣者（4–3）= 秘蓝`、`天使（2–1）= 典藏紫`、`真神（0）= 橙金`；层级色与“已确认/候选”内容状态色分离。
- 主页愿望指标改为真实的 `wishlistCount`，标题统一为“愿望清单”；移除虚构的最近唤醒入口；画廊导语改为“选择一张身份卡，查看身份、六维信息和故事”。
- 主页移除无点击行为、且与导语重复的“开始探索”横幅及装饰性进度线；统计栏后直接进入真实的“卡牌列表”。
- 详情页移除身份面板重复的内容状态徽章；具体人物只显示人物名和身份卡数量，不展示身份存储规则；原型卡改为“身份类型 / 途径原型 / 原型卡”，并明确“不对应具体角色”。
- 声音提示集中到实时字幕栏，按钮行不再出现易截断的重复说明；空闲状态统一为“未播放”。故事可播放时明确提示“这段故事可以朗读，也可以直接阅读”。
- 搜索无结果态移出 `LazyVGrid`，以完整内容宽度居中展示“没有找到匹配的身份卡”，并保留“清除搜索”恢复入口；人工截图未观察到卡片覆盖、文字出框或面板重叠。
- 自动化：`swift test` 执行 71 tests，0 failures；新增五档序列映射、层级文案去重与颜色 token 区分回归，并覆盖旧格式序列输入仍可用新格式搜索；`./scripts/build-app.sh debug` 与 `./scripts/build-app.sh release` 均退出码 0；release `.app` 的 `LSMinimumSystemVersion=26.0`、主程序为 Mach-O `arm64`，`codesign --verify --deep --strict` 通过。
- CUA 复核当前 release `.app` 的画廊首页：序列 3 显示秘蓝、序列 9 显示银白、序列 0 显示橙金、序列 7 显示翡翠绿；当前合成 fixture 没有序列 2/1 卡牌，天使色通过五档 token 单元测试核验。

## 五档层级 token 与脚本泄露复核

- `SequenceBadge` 统一用于卡牌列表、详情卡面围台和身份信息抬头；详情与 VoiceOver 明确读出“低序列 / 中序列 / 圣者 / 天使 / 真神”，序列数字始终不补零。
- 序列色只表达力量层级；内容状态、六维信息、声音与故事播放态分别使用 `ArchiveTheme.Status`、`ArchiveTheme.Semantic` 与 `ArchiveTheme.Playback`，候选状态改为烟铜色，魔药维度改为玫瑰色，均不复用天使紫或低序列银白。
- CUA 复核序列 0、序列 3、序列 7、候选清单和画廊首页：未发现 `fixture`、`snapshot`、`recipe`、原始 voice ID、审批/流水线标签或重复的序列层级文案；序列 0 只显示“序列 0 · 真神”。

## 愚者途径当前候选卡内置验收

- 2026-09-14：S09 `lotm.fool.s09.klein-moretti.tingen-01` 与 S00 `lotm.fool.s00.klein-moretti.mr-fool-01` 均改为当前生产源的原生候选卡图；App 用户文案分别显示为“克莱恩·莫雷蒂 / 序列 9 · 占卜家”和“愚者先生 / 序列 0 · 真神”。
- S09 资源为 `fool-s09-card-name-edit-v1-v001.png`，S00 资源为 `fool-s00-card-agentic-v1-v001.png`；两份资源均为 1024×1536 PNG，App 源文件 SHA-256 分别为 `2d73c4662e9de0b263f833b75ca419605299b40f52c0909421c3b0d9d4dc0efe` 与 `11eab4ed8688a4949411721f0fad07586cd006debb444919153907fb77b584ce`。
- 旧 S09/S00 卡图资源已从 `Resources/CardArt/` 移入 macOS 废纸篓，不保留旧资源名或兼容映射；当前候选图尚未因 App 打包而获得用户视觉批准，不计入正式卡牌。
- S09 的 6 条叙事与 `production/narratives/klein-s09-tingen.json` 的内容摘要同步，仍为待审核文本；S00 继续使用 App 内已批准的本地试听链路，卡 ID 与人物身份切片已同步到生产源。
- 已安装的 `/Applications/LotmCardStudio.app` 通过 `codesign --verify --deep --strict`；实际画廊验收可见 4 张 fixture，S09/S00 均可打开当前卡图，分别显示候选、六维信息与故事；S09 的声音/故事保持待审核锁定，S00 的本地配音与故事保持可用。

## 正义小姐 App 外资产保留核验

- 2026-09-14：正义小姐的原始插画与两个高清派生版本仍保留在 `artifacts/lotm.visionary.s07/render-v001/`；六维源数据仍保留在 `pathways/visionary/sequences/07/card.json`，人物研究与故事边界仍保留在 `docs/research/2026-09-13-audrey-s07-research.md`。
- 6 条已批准配音仍保留在 `artifacts/lotm.visionary.s07/audio-v001/`；本次愚者卡清理没有触碰上述 App 外资产。

本机 App 发布结论：Release 已安装至 `/Applications/LotmCardStudio.app`；安装包内为 2 张当前卡图和 12 个当前 WAV，签名、`arm64`、`LSMinimumSystemVersion=26.0`、启动和真实窗口交互均已复核。App 发布已完成；卡牌视觉正式 release 仍是独立待批准事项。

## 2026-09-14 当前卡包与叙事/配音回归

本节是当前安装版和当前生产源的最新验收记录；上文较早日期的数字、卡片清单和资源描述保留为历史快照，不覆盖本节。

- App 当前只内置两套愚者途径候选卡包：S09 `克莱恩·莫雷蒂` 与 S00 `愚者先生`；画廊实测为 `0 张已确认卡牌`、`2 张卡牌`，愿望清单为 1 张。旧 S03/正义小姐 App 卡包及其 App 内资源已清理。
- 两套卡包都满足原子边界：身份 `cardID/slotID/characterID/identitySliceID`、当前卡图、六维回读、叙事 `cardID`、收藏/愿望意图与音频状态同时存在；每张卡均有 6 条当前版本叙事和 6 个本地 WAV。
- S09 使用 `dylan`，S00 使用 `uncle_fu`；新口头语和故事已写入 `production/narratives/`，六条目逐条绑定当前内容摘要并标记为 `approved`。机器校验不替代用户对卡图和声音审美的批准。
- `python3 tools/production.py check-fool-audio`：通过；2 张卡、12 个 WAV、2 张 App 卡图均通过白名单、哈希、叙事摘要绑定和孤儿资源检查。12 个 WAV 均为可解码的 24 kHz、16-bit、mono PCM。
- `swift test --verbose`：77/77 通过；Debug/Release 构建均通过。当前安装版 `/Applications/LotmCardStudio.app` 的最低系统版本为 `26.0`、主程序为 `arm64`，`codesign --verify --deep --strict` 通过。
- CUA 实测当前安装版画廊只显示 S09/S00，侧栏“愚者”统计为 `0 张已确认 · 2 张候选`；S09 故事页显示三个新版章节并可开始/停止朗读，停止后正文保留；S00 可播放新版问候语。这里验证的是 UI 状态、文字绑定和音频解码/播放链路，不把机器检查等同于人工听感批准。
- 正义小姐 App 外资产仍保留：原始/派生插画、六维源数据、研究/故事资料与 6 条 WAV 均在 `artifacts/lotm.visionary.s07/`、`pathways/visionary/sequences/07/card.json` 和对应文档中；未被本次 App 清理删除。

当前仍未通过的门：两张卡的视觉用户验收、最终 2K/4K 采样与正式 release。App 仍是 M1 静态 fixture，尚未提供真正的用户导入/删除界面；未来必须以整套卡包为新增/删除单位。

## 2026-09-14 新增「福生玄黄天尊」卡包（序列之上）

- App 新增第三张隔离候选卡 `lotm.celestial-worthy.primordial-01`（展示名 福生玄黄天尊，`sequenceName` 序列之上 · 诡秘之主，`slotID` `lotm.celestial-worthy`，characterID `celestial-worthy`，identitySliceID `celestial-worthy.primordial`）。它是「序列之上」存在，不占 22×10 序列卡槽，也不按真神归档。
- 卡图用用户提供的 Codex 直出完整卡（资源名 `celestial-worthy-card-v1-v001`，1024×1536 RGB）；来源登记在 `artifacts/production/celestial-worthy-card-v1/v001/provenance.json`。不做合成、不转 2K。
- 六维回读 01–06、1 条问候、2 条口头语、3 个故事章节齐备；文案由用户逐字批准，摘要绑定见 `production/narratives/celestial-worthy.json`，审核记录见 `docs/reviews/2026-09-14-celestial-worthy-narrative-audio.md`。
- 6 条音频使用本轮注册的自定义 VoiceDesign 音色 `celestial-worthy`（本机 SpeechRail 8201），均为 24 kHz / 16-bit / mono PCM，落在 `artifacts/lotm.celestial-worthy/audio-v001/` 并同步到 `Resources/Audio/`。
- `python3 tools/production.py check-fool-audio`：通过；3 张卡、18 个 WAV、3 张 App 卡图通过白名单、哈希、叙事摘要绑定与孤儿资源检查。
- `swift test`：78/78 通过；`build-app.sh debug` 与 `release` 均通过；`.app` 内为 3 张卡图 + 18 WAV，arm64、`LSMinimumSystemVersion=26.0`。
- 未执行：`/Applications/LotmCardStudio.app` 的替换安装、真实窗口人工走查、用户对卡图与音色的最终审美批准。以上均保持待办，不因机器通过而视为已批准。

## 2026-09-14 新增「上帝」卡包（序列之上 · 星界支柱）

- App 新增第四张隔离候选卡 `lotm.god-almighty.primordial-01`（展示名 上帝，`sequenceName` 序列之上 · 星界支柱，`slotID` `lotm.god-almighty`，characterID `god-almighty`，identitySliceID `god-almighty.primordial`）。它与福生玄黄天尊同为「序列之上」存在，不占 22×10 序列卡槽，也不按真神归档。
- 卡图用用户提供的 Codex 直出完整卡（资源名 `god-almighty-card-v1-v001`，1024×1536 RGB、无 alpha，sha256 `d9012cdd9baaee354514008a3cf340804880404409e1c94e9460e2cf0b8dd89d`）；来源登记在 `artifacts/production/god-almighty-card-v1/v001/provenance.json`。不做合成、不转 2K（`intermediate_2k_count = 0`）。
- 六维回读 01–06、1 条问候、2 条口头语、3 个故事章节齐备；文案由用户逐字批准，摘要绑定见 `production/narratives/god-almighty.json`，审核记录见 `docs/reviews/2026-09-14-god-almighty-narrative-audio.md`。
- 6 条音频使用本轮注册的自定义 VoiceDesign 音色 `god-almighty`（本机 SpeechRail 8201，服务版本 `2.6.1`），均为 24 kHz / 16-bit / mono PCM，落在 `artifacts/lotm.god-almighty/audio-v001/` 并同步到 `Resources/Audio/`。
- `python3 tools/production.py check-fool-audio`：通过；4 张卡、24 个 WAV、4 张 App 卡图通过白名单、哈希、叙事摘要绑定与孤儿资源检查。
- `swift test`：79/79 通过；`build-app.sh debug` 与 `release` 均通过；`.app` 内为 4 张卡图 + 24 个 WAV，arm64、`LSMinimumSystemVersion=26.0`、`codesign --verify --deep --strict` 通过。
- 事实边界：支柱位格、源质＝混沌海、五途径归属（空想家/太阳/暴君/白塔/倒吊人）与四核心象征（全知/全能/造物主/星界之主）本轮**全部**维持 `lead / 待中文底本核验`；本轮外部交叉核证未取得结果，未据此升级任何断言。左右铭文与构图来自用户编辑裁定。
- 未执行：`/Applications/LotmCardStudio.app` 的替换安装、真实窗口人工走查、用户对卡图与音色的最终审美批准。以上均保持待办，不因机器通过而视为已批准。

## 当前已知未过项（非本次「上帝」改动引起）

- `python3 -m unittest discover -s tests`：141 项中 1 项 error —— `test_production.py::test_three_real_task_contracts` 抛 `missing/stale dependency: tools/render/foolpipeline5.swift`。原因是该文件已在本机被改动（磁盘 sha256 `ab58a00929c5d3694f7a0bb9e9c337888954c52515396cb59edddc51854a6eb4`），而 `production/tasks/fool-mother-frame-v1.json`、`fool-five-tier-frame-batch-v1.json`、`fool-ten-sequence-frame-batch-v1.json` 仍登记旧值 `09dfc9ae613fa572c7fb78559934193f9bd528844fcbb1c795cb3291c10f7e3d`。需由该改动的所有者重算并同步任务契约 sha；不属于本次卡包范围，未擅自修改。

## 2026-09-14 新增「堕落母神」卡包（序列之上 · 现实支柱）

- App 新增第五张隔离候选卡 `lotm.mother-goddess-depravity.primordial-01`（展示名 堕落母神，`sequenceName` 序列之上 · 现实支柱，`slotID` `lotm.mother-goddess-depravity`，characterID `mother-goddess-depravity`，identitySliceID `mother-goddess-depravity.primordial`）。它与福生玄黄天尊、上帝同为「序列之上」存在，不占 22×10 序列卡槽，也不按真神归档。
- 口径：用户回答「源质／途径口径」时裁定 **源质＝母巢**（地球侧 月亮＋母亲 两条途径），核心象征 **生命 · 繁衍**；**不纳入**她自身那条外神途径（序列 9 恶棍 → 序列 0 混沌原胎）。见 `docs/DECISIONS.md` D14 与资料包头部的口径裁定。
- 卡图用用户提供的 Codex 直出完整卡（资源名 `mother-goddess-depravity-card-v1-v001`，1024×1536 RGB、无 alpha，sha256 `19583bbce8be36a594c308fcf1588f49b9c20b0a3b5e933a94041a95f87c2f08`）；来源登记在 `artifacts/production/mother-goddess-depravity-card-v1/v001/provenance.json`。不做合成、不转 2K（`intermediate_2k_count = 0`）。卡面实测铭文：左「母巢 / BROOD HIVE」、右「生命 · 繁衍 / LIFE PROPAGATION」、铭牌「堕落母神 / MOTHER GODDESS OF DEPRAVITY」；底部两条英文箴言为本卡原创对照语，不是原著引文。
- 六维回读 01–06、1 条问候、2 条口头语、3 个故事章节齐备；摘要绑定见 `production/narratives/mother-goddess-depravity.json`，审核记录见 `docs/reviews/2026-09-14-mother-goddess-depravity-narrative-audio.md`。
- 6 条音频使用本轮注册的自定义 VoiceDesign 音色 `mother-goddess-depravity`（本机 SpeechRail 8201，服务版本 `2.6.1`），均为 24 kHz / 16-bit / mono PCM，落在 `artifacts/lotm.mother-goddess-depravity/audio-v001/` 并同步到 `Resources/Audio/`。
- `python3 tools/production.py check-fool-audio`：通过；5 张卡、30 个 WAV、5 张 App 卡图通过白名单、哈希、叙事摘要绑定与孤儿资源检查。
- `swift test`：80/80 通过；`build-app.sh debug` 与 `release` 均通过；`.app` 内为 5 张卡图 + 30 个 WAV，arm64、`LSMinimumSystemVersion=26.0`、`codesign --verify --deep --strict` 通过。
- 事实边界：支柱位格、源质＝母巢、被撕裂状态与两途径拆分本轮**全部**维持 `secondary-cross-check / authorial-supplement（转录）`，**没有任何一条可标为 `verified`**；本仓库无中文授权底本，作者公众号原文未取得。不把「收回母巢后」的未取得形态画成既定形象。
- 更正上文「当前已知未过项」：`tools/render/foolpipeline5.swift` 与其三个 task 契约的 sha 已同步为 `ab58a009…`；`python3 -m unittest discover -s tests` 现为 **144 项 OK（skipped=6）**。该项由改动所有者修复，与本卡包无关。
- 未执行：`/Applications/LotmCardStudio.app` 的替换安装、真实窗口人工走查、用户对卡图与音色的最终审美批准。以上均保持待办，不因机器通过而视为已批准。

## 2026-09-14 二次追加：六位「序列之上」旧日纳入（App 扩到 11 卡）与代词归一

### 新增隔离候选卡（6 张，均为非序列卡位）

| 展示名 | cardID | slotID / characterID | sequenceName（存在名） | 音色 |
|---|---|---|---|---|
| 永恒之暗 | `lotm.eternal-darkness.primordial-01` | `lotm.eternal-darkness` | 序列之上 · 永恒之暗 | `eternal-darkness` |
| 恶魔之父 | `lotm.father-of-demons.primordial-01` | `lotm.father-of-demons` | 序列之上 · 恶魔之父 | `father-of-demons` |
| 毁灭天灾 | `lotm.destruction-calamity.primordial-01` | `lotm.destruction-calamity` | 序列之上 · 毁灭天灾 | `destruction-calamity` |
| 失序者 | `lotm.embodiment-of-disorder.primordial-01` | `lotm.embodiment-of-disorder` | 序列之上 · 失序者 | `embodiment-of-disorder` |
| 知识之妖 | `lotm.demon-of-knowledge.primordial-01` | `lotm.demon-of-knowledge` | 序列之上 · 知识之妖 | `demon-of-knowledge` |
| 光之钥 | `lotm.key-of-light.primordial-01` | `lotm.key-of-light` | 序列之上 · 光之钥 | `key-of-light` |

事实依据：`docs/research/2026-09-14-above-sequence-sefirot-old-ones.md`（sha256 `70d470227142ef85993e5003a044ee9d69b0d565f8fa97dd326fed78d95743f1`），其 §3 引《诡秘之主》第1346章「支柱」，§4 为九源质↔九旧日↔22 途径映射。全部字段维持 `secondary-cross-check / 编辑裁定`，**无一条可标 `verified`**；本仓库无中文授权底本。

### 已知异常（用户裁决「按现状纳入」）

- `毁灭天灾` 卡左铭文槽为「毁灭天灾／THE DESTRUCTION CALAMITY」，其余五张该槽放源质（此处应为**灾祸之城**）。已登记于 `artifacts/production/destruction-calamity-card-v1/v001/provenance.json` 的 `card_text_observed.readback_note` 与对应审核记录；**不自行改图**。

### 代词归一为「祂」

- 依 D15 与用户追加裁定，真神及以上主体的第三人称统一为「祂」，其**源质与概念**（永暗之河、暗影世界、灾祸之城、母巢、秩序、知识等）**同样用「祂」**；只有物体、事件与复数事物仍用「它/它们」。涉及卡：永恒之暗、恶魔之父、毁灭天灾、失序者、知识之妖、光之钥、堕落母神、S00 愚者先生。
- `祂` 与 `它/他/她` 同音（`tā`），**本轮未重出音频、未逐条试听**；只保证摘要绑定一致。
- 已同步重算：各卡 `contentDigest`／`approvedDigest`、`artifacts/lotm.<slug>/audio-*/generation.json` 的 `text_digest`、对应 Swift 叙事文件；因 S00 文案变更，`production/tasks/fool-s00-card-agentic-v1.json` 的 narrative `sha256` 同步更新。`artifacts/production/**` 历史回执按不可覆盖原则保持原样。

### 本轮验证结果

- `python3 tools/production.py check-fool-audio`：**通过**，11 张卡 / 66 个 WAV / 11 张 App 卡图（白名单、哈希、叙事摘要绑定、孤儿资源、采样格式）。
- `python3 tools/production.py check-fool-cards`：**通过**（`candidate_count` 2，仍 `pending-user-visual-approval`）。
- `python3 tools/cardctl.py check --level scaffold`：exit 0。
- `python3 -m unittest discover -s tests`：**144 OK（skipped=6）**。
- `swift test`：**86 passed / 0 failures**。
- `./scripts/build-app.sh debug` 与 `release`：exit 0；`.app` 内为 **11 张卡图 + 66 个 WAV**，arm64、`LSMinimumSystemVersion=26.0`、`codesign --verify` 通过。
- App 音频清单：`Resources/Audio/` 共 66 个文件；`src` 端 66 个 `generation.json` 条目与叙事摘要一一绑定。

### 仍未执行

- 六张新卡卡图与音色的用户逐项视觉/听感批准（全部保持 `candidate-pending-user-visual-approval`）；
- `/Applications/LotmCardStudio.app` 的替换安装（须用户同意）。

## 2026-09-14 三次追加：源质／概念亦用「祂」、release 安装至 /Applications

### 二次代词裁定（用户）

- 用户追加裁定：**源质与概念的指代同样用「祂」**。已改 6 张卡文案共 11 处：母巢（堕落母神）、永暗之河（永恒之暗）、暗影世界（恶魔之父 ×2）、灾祸之城（毁灭天灾 ×2）、秩序（失序者 ×2）、知识（知识之妖 ×3）；并修章节标题 1 处（「第三章 · 要成为祂，需要什么」）。
- **仍用「它/它们」**：世界（毁灭天灾问候语）、「名字与源质同词」这件事（光之钥）、两条途径与可能性等**复数事物**（上帝、恶魔之父、失序者、知识之妖的故事段）。
- 失序者 story-02 为避免一个分句内两个「祂」歧义，改用名词：「祂只是替**秩序**自己没有承认的那一半」。
- 同步：6 张卡的 `contentDigest`／`approvedDigest`／`generation.json.text_digest` 与 Swift 叙事文件重算；`docs/DECISIONS.md` D15、`docs/card-narrative-contract.md`、根 `AGENTS.md`、8 份审核记录说明同步为「源质与概念亦用祂」。登记偏差复查为 0。

### 安装记录

- `./scripts/build-app.sh release` → exit 0；`codesign --verify --deep --strict` **通过**（`Sealed Resources version=2 files=79`，ad-hoc 签名）。
- **注意**：`build-app.sh` 只在 `release` 配置下签名；若最后执行 `debug`，`.build/LotmCardStudio.app` 会是未签名包。本次先误装 debug 包（`codesign` 报 `code has no resources but signature indicates they must be present`），已移入废纸篓并重装 release。
- `/Applications/LotmCardStudio.app` 已更新（旧版移入废纸篓 `~/.Trash/`）；与构建产物 `diff -rq` 逐文件一致。
- 安装后核验：11 张卡图 + 66 个 WAV、arm64、`LSMinimumSystemVersion=26.0`、`codesign --deep --strict` 通过；启动→进程存活→正常退出，无本应用的崩溃报告。

### 本轮测试

- `python3 -m unittest discover -s tests`：**144 OK（skipped=6）**；`swift test`：**86 passed / 0 failures**；
- `check-fool-audio`：**passed**（11 卡 / 66 WAV / 11 卡图）；`check-fool-cards` exit 0；`check --level scaffold` exit 0。

## 2026-09-14 四次追加：十一卡视觉批准与「收藏转正式」（批准 ≠ 发布）

### 用户裁决

- 原文：「**已经验收通过，所有卡，变为正式**」。三点边界：① 转正范围为 App 现有十一张；② 深度只转**状态与批准记录**（**不**执行 ADR-003 最终采样、**不**产出 2K/4K）；③ 素材基线一并转正（追问后选定「只记依据，release 保持 false」）。

### 生产侧记录

- 新建人类 sidecar `production/approvals/fool-card-visual-approval-v1.json`（`visual_approved: true` / `release_approved: false` / `sampling_executed: false`，绑定十一张卡图与九份 provenance 的 sha256）。
- 新建聚合记录 `production/cards/fool-nonsequence-card-approvals-v1.json`（九张非序列卡；`sequence_slots: false`）——序列候选清单 `fool-card-candidates-v1.json` 的门禁要求 `sequence ∈ {0,9}` 且有 task/receipt，非序列卡不能混入。
- `fool-card-candidates-v1.json`、`fool-card-visual-review-v1.json`、`fool-final-sampling-v1.json`（`approved-for-final-sampling` + `sampling_executed: false`）、材料与分层基线的 `basis`／`acceptance.approval_sidecar` 同步。
- 所有 `release_approved`／`formal_release_approved` 保持 **false**：十一张卡**没有** 2K/4K 交付像素。
- 门禁新增 CLI `check-fool-nonsequence-cards` 与 `validate_fool_nonsequence_card_approvals`；批准必须由独立人类 sidecar 证明并逐卡比对哈希，禁止清单自证。反例测试 8 条（`tests/test_fool_card_validation.py`）。

### App 侧解耦（正式收藏 ≠ 内容已核验）

- 十一张卡 `collectionIntent` 由 `.candidate` 改为 `.formal`；`contentStatus` **全部保持 `.proposed`**——用户批准的是视觉与收藏身份，不是内容核验。
- `AlbumViewModel.visibleCards(.formal)` 与 `formalCount` 改为只按 `collectionIntents == .formal` 过滤，不再要求 `contentStatus == .confirmed`；「我的收藏」副标题改为「你正式收藏的身份卡；每张卡的内容核验状态以卡片自身的标注为准。」
- 途径统计由 `ArchiveCopy.pathwaySummary(confirmed:candidate:)` 改为 `pathwaySummary(formal:candidate:)`；愚者途径现读作 `2 张已收藏 · 0 张候选`（旧文 `0 张已确认 · 2 张候选`）。
- 新增断言：`formalCount == 11`、`candidateCount == 0`、`confirmedCount == 0`，且九位「序列之上」仍为 `.proposed`，防止后续被误升为已核验。
- 移除 fixture 中 S00 的 `isWishlisted`：十一张卡均为正式收藏，愿望清单为空（分栏与指标保留，`wishlistCount` 为 0）；原「愿望清单 = S00」断言改为显式空集断言，不删除。

### 本轮验证结果

- `python3 tools/cardctl.py check --level scaffold`：exit 0。
- `python3 -m unittest discover -s tests`：**159 tests OK（skipped=6）**（含用户并发提交带入的 `tests/test_pin_seal.py` 6 条）。
- `python3 tools/production.py check-fool-cards`／`check-fool-nonsequence-cards`／`check-fool-audio`／`check-fool-materials`：全部 exit 0／passed。
- `python3 tools/pin_seal.py --check`：**112 条 pin 全部通过**。
- `swift test`：**87 passed / 0 failures**（新增 1 条）。
- `./scripts/build-app.sh debug` 与 `release`：exit 0；`.app` 内 11 张卡图 + 66 个 WAV。

### 仍未执行

- ADR-003 最终采样与 2K/4K 交付像素（用户裁决暂不产出）→ 所有 release 标志保持 false。
- 卡图与音频的人工逐项听感/视觉复验：本轮的「正式」是用户对既有现状的整体验收，不替代逐项验收。

### 打包期资源落地（1A 媒体单一存放，2026-09-15）

- 卡图与音频改为 `artifacts/**` 唯一真源：`apps/LotmCardStudio/Resources/{CardArt,Audio}` 共 **72M**（CardArt 34M + Audio 38M）副本已删除；删除前先在旧门禁（`c39c83c`，仍含 `Resources`↔`artifacts` 逐字节比对）下验证副本与 artifacts 逐字节一致。
- `check-fool-audio` 的审计对象由 `Resources/` 改为 `artifacts/`：仍校验 11 张卡图登记存在、66 个 WAV 的 manifest `sha256` 与时长；不再比对仓库内副本（副本已不存在）。门禁输出与改动前逐字节一致。
- 新增 `python3 tools/production.py stage-app-resources --dest <bundle>/Contents/Resources`：打包期按同一份登记表从 `artifacts/**` 落资源并复核落盘 WAV 哈希；`scripts/build-app.sh` 已改为调用它，任何一步失败即中止打包。
- 验证：五门禁输出与改动前逐字节一致；`swift test` **87 passed / 0 failures**；`./scripts/build-app.sh debug` exit 0，`.app` 内 **CardArt 11 个 + Audio 66 个**，与登记表一致。
