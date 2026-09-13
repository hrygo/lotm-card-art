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
