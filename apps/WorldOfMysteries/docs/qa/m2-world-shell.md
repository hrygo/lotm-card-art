# M2 世界外壳 本机验收记录

日期：2026-09-15
依据：[`docs/product/macos-ux-interaction-prd-v1.0.md`](../../../../docs/product/macos-ux-interaction-prd-v1.0.md) §2 信息架构、§3.1–§3.7 界面规范、§9.1 机器可断言项。

## 验收范围

- 四个并列一级区域：世界 / 卡牌 / 人物 / 故事书，各自独立记忆选中项。
- 世界首页七个分区：世界状态头、最近事件、正在进行的命运、最近活跃人物、未解决事件、重要地点变化、最近完成的故事；无数据时为空态。
- 卡牌详情命运入口：措辞随身份类型变化（人物身份卡 / 序列原型卡 / 序列之上与真神），并显示该卡在世界里的位置。
- 命运生成界面：只呈现时间 / 地点 / 异常 / 压力四项可见种子，「换一个入口」在同一位格尺度内换处境。
- 人物列表与人物档案：身份切片、本机经历、关系（区分原著事实与本机经历）、该人物自己知道的事。
- 故事书列表与命运详情：阅读模式（已发生过的段落）、聆听模式（转入既有故事播放）、命运记录、秘密计数、关系变化、对世界的影响。
- 示例世界标记：世界 / 人物 / 故事书三处持续显示「示例」标记与说明。

## 自动化结果

在 `apps/WorldOfMysteries` 执行：

```text
swift build
[ok] no errors

swift test
Executed 142 tests, with 0 failures (0 unexpected)
```

其中世界外壳相关的两个测试目标（2026-09-15 17:24 实测）：

```text
WorldDomainTests   17 tests, 0 failures   （WorldOfMysteriesCoreTests）
WorldShellTests    28 tests, 0 failures   （WorldOfMysteriesFeaturesTests）
```

（首次记录曾把 `WorldDomainTests` 写成 23 条；那是把包内其它目标的用例一起计了。上表是按 `Test Suite 'WorldDomainTests' passed` 实测的行数，已按实际更正。）

覆盖的机器可断言项（PRD §9.1）：

- 四个一级区域存在且可切换；卡牌 / 人物 / 故事书的选中项互不影响。
- 示例世界下世界首页各分区均有数据；`WorldSnapshot.isEmpty` 为空态判据。
- 卡牌详情命运入口措辞随身份类型变化；缺少人物档案或身份切片时置灰并给出原因。
- 命运生成界面只暴露四个可见种子字段（断言字段数量与标签，且不含「秘密」「结局」等幕后词）。
- 命运详情包含命运记录、秘密计数、关系变化与世界影响；未揭开的秘密 `revealedText` 恒为 nil。
- 阅读模式优先使用这段命运自己的段落；回退到卡片叙事时界面明示来源；进行中的命运的段落不与卡片章节标题重合，同一张卡的两段命运不出现重复段落。
- 叙事状态提示为句子而非数值（断言不含 ASCII 数字），且不出现 `spirituality` / `exposure` / `corruption` / `danger` 等引擎变量名。
- 新增用户文案不含内部术语（fixture / session / seed / snapshot / draft / candidate 等）。
- 九位「序列之上」存在使用「祂」、无本机经历、不占序列卡槽；克莱恩·莫雷蒂按 `character_id` 聚合两张身份卡。

仓库级回归（内容层未改动，仅确认未被牵连）：

```text
python3 -m unittest discover -s tests
Ran 184 tests in 99.794s
OK (skipped=6)
```

## macOS 26-only 与打包

```text
./scripts/build-app.sh debug
输出：apps/WorldOfMysteries/.build/诡秘世界.app

./scripts/build-app.sh release
输出同上（同一路径的 release 产物，17:27 构建）
```

- `Package.swift` 仍为 Swift tools 6.2、`.macOS(.v26)`、Swift language mode 6。
- `.app` 由打包脚本按登记表（`tools/production.py stage-app-resources`）落卡图与批准音频，仓库内不重复存放副本。
- 2026-09-15 17:36 安装到 `/Applications/诡秘世界.app`：旧的 13:18 构建先移入废纸篓（可恢复），再用 `ditto` 覆盖安装 release 产物。安装后实测 `LSMinimumSystemVersion=26.0`、`CFBundleShortVersionString=0.1.0`、`codesign` 为 adhoc、`lipo -archs` 为 `arm64`，双击启动并渲染出 M2 世界外壳（四区导航与常驻「当前命运」可见）。

## 实机观察（Agent 屏幕观察 + 可访问性树）

时间：2026-09-15 17:00–17:15。对象：仓库内构建的 `apps/WorldOfMysteries/.build/诡秘世界.app`（重建后重启，`kill` 旧实例 → `open` 新产物）。

方法：窗口截图（人眼观察渲染结果）＋ 可访问性树文本（逐条核对文案与结构）。

**边界**：这是 Agent 在实机上看到的结果，**不是**用户视觉批准，也不构成内容核验；`docs/DECISIONS.md` D16 的批准口径不变。另：`/Applications/诡秘世界.app` 是 13:18 的旧构建（早于本轮实现），本轮未安装新版本，也未运行该旧实例做判断。

### 逐区观察记录

| 区域 | 观察内容 | 结果 |
|---|---|---|
| 世界 | 头图区「这个世界 · 本机示例世界」＋ 第五纪 / 主线 / 示例三枚标记＋叙述句；最近事件 5 条（每条带时间地点与范围标签）；正在进行的命运 1 条 | 渲染完整，未见截断；事件可按下去查看 |
| 卡牌 | 每张卡带身份类型标签（身份卡 / 真神 / 序列之上）与「在世界里的位置」（有一段进行中的命运 / 已有 1 段历史 / 未进入世界） | 标签随卡正确变化 |
| 卡牌详情 · 命运入口 | 「命运 / 身份卡 / 有一段进行中的命运 / 雨夜的委托：…」＋「继续这段命运」「另起一段」；帮助文本说明会继承此刻的身份、能力边界与已经知道的事 | 入口措辞与继承说明都出现 |
| 卡牌详情 · 序列之上 | 「序列之上 / 未进入世界」＋「以祂的尺度介入世界」；六维里写「不适用普通魔药体系」 | 高位存在文案用「祂」，没有把「不适用」写成留空 |
| 命运生成 | 卡面缩略图＋「进入克莱恩·莫雷蒂」＋序列小字＋继承说明；只列时间 / 地点 / 异常 / 压力四项；「这里只显示你已经能察觉的部分；真相会在过程里慢慢展开。」；按钮为「编织命运」「换一个入口」「先不开始」 | 无秘密数量、无 NPC 目标、无结局列表；未真的开始一段新命运（点了「先不开始」） |
| 人物 | 克莱恩·莫雷蒂档案：两张身份切片（序列 9 身份卡「有一段进行中的命运」＋愚者先生「已有 1 段历史」）、本机经历 3 段、关系分「原著事实 / 本机经历」两栏、知识边界按公开 / 途径 / 秘密分级 | 分区与来源标注都在 |
| 故事书列表 | 「发生过的事」＋示例说明；三条命运：雨夜的委托（进行中，1 / 4 秘密）、档案馆的第七个抽屉（已完结 · 开放结局 · 4 / 7）、一次无人应答的回应（已完结 · 开放结局 · 1 / 3） | 进行中的排在最上 |
| 命运详情 | 三段齐全：阅读模式（段落）／聆听模式（「听这段命运」「打开这张卡」，进行中时为「继续这段命运」）／命运记录（逐次抉择＋策略＋代价）＋秘密计数＋关系变化＋对世界的影响（含「尚无结论」） | 未揭开的秘密只显示「这件事还没有被弄明白。」，**没有**答案 |
| 侧边栏常驻块 | 四个区域切换时，「当前命运 · 雨夜的委托 ＋ 继续」始终固定在侧边栏底部 | 切换区域时可见，不再随滚动消失 |

### 对应 PRD §9.2 的六条人工观察

| 条目 | 本轮实机观察 | 是否仍需用户确认 |
|---|---|---|
| 1 世界首页是否给人「回到同一个世界」的感受 | 首页由世界状态头、事件、进行中的命运、人物、未解决事件、地点变化、完成的故事组成，读起来像同一个世界的近况，而不是内容列表 | 是（感受类判断保留给用户） |
| 2 人物页能否在不看名字的情况下认出人物 | 身份切片、经历、关系、知识边界四段齐备，关系区分原著事实与本机经历 | 是（同上） |
| 3 选择项是否代表不同策略 | 已完结命运的六次抉择带不同意图与代价（信息优先 / 掩藏行踪 / 借他人之力 / 保存自己 / 先护住人 / 谨慎观察），不是同一行为换措辞 | 实时选择交互属 Story Player（M1），本轮按 `m1-local-run.md` 沿用，未重测 |
| 4 是否出现 RPG HUD 感 | 全流程未见数值、进度条、任务列表；状态提示是句子（「你的灵性已经接近枯竭。」＋来源） | 是（主观判断保留给用户） |
| 5 高位存在的位格感 | 「以祂的尺度介入世界」、六维「不适用普通魔药体系」；愚者先生的命运文案用「祂」，而祈祷等物用「它」 | 是（同上） |
| 6 `.app` 实机运行与 VoiceOver 抽查 | 新构建可双击启动，跨四个区域反复切换未崩溃；可访问性树给出的按钮名称、帮助文本与状态值可读（VoiceOver 读的就是这棵树） | **VoiceOver 实际朗读走查未做**（未在本机开启 VoiceOver），须由用户完成 |

## 观察中发现并修复的问题

**进行中的命运误用卡片章节（已修）**

- 现象：命运详情的「阅读模式」原先直接渲染 `card.narrative.readableChapters`。于是进行中的「雨夜的委托」（当时只有 1 次抉择）也会显示「第三章 · 回家之前」这类尚未发生的段落，与同一面板上「只呈现已经发生过的段落」的说明自相矛盾；同一张卡的两段命运还会显示完全相同的段落。
- 修复：`EpisodeRecord` 增加 `recordedPassages`；新增 `EpisodeReadingResolver`（Core，纯逻辑）——命运自己的段落优先，只有它没有段落时才回退到卡片叙事，并由界面明说「这段命运还没有留下自己的段落；下面是这张卡片的叙事段落。」；`SampleWorld` 为三段命运各写了独立段落。
- 防回归：新增断言要求进行中命运的段落不与卡片章节标题重合、同一张卡的两段命运不出现重复段落文本、解析器在无来源时保持空态。
- 验证：`swift test` **142 tests / 0 failures**（新增 6 条）；重建 `.app` 后逐段复核：雨夜的委托 2 段、档案馆的第七个抽屉 4 段、一次无人应答的回应 2 段，均与各自抉择记录对应。

## 仍需用户完成

1. **视觉批准**：以上是 Agent 观察，不构成视觉验收。界面是否「够好」仍由用户判断；未获用户确认前，本轮改动不得被表述为「已通过视觉验收」。
2. **VoiceOver 朗读走查**（PRD §9.2-6）：本轮只核对了可访问性树文本，没有开启 VoiceOver 实际走一遍朗读顺序。
3. **Story Player 的实时选择交互**：属 M1 链路，本轮未复核，沿用 `m1-local-run.md` 的记录。
4. **重新安装提醒**（不是待办）：`/Applications/诡秘世界.app` 已是 2026-09-15 18:16 的 release 构建（17:27 与 13:18 两次旧构建都在废纸篓里，可恢复）。若之后又改了源码，记得重新 `./scripts/build-app.sh release` 并 `ditto` 覆盖，否则会对着旧界面做视觉测试。

## 2026-09-15 18:16 · 全局设计 token 投影与重装

本轮不改布局、不改交互，只把界面数值收拢到唯一事实源 `config/design-tokens.json`（合同见 `design/design-tokens.md`，决策见 `docs/DECISIONS.md` D21）。

**Agent 侧已核（机器证据）**

- `python3 tools/design_tokens.py check` → `[ok] 投影一致；10 条文字样式复用 token；无字面量绕过（color 71, space 26, radius 16, stroke 4, size 8）`，退出 0。
- `swift test --package-path apps/WorldOfMysteries` → **Executed 142 tests, with 0 failures**。
- `./scripts/build-app.sh release` 退出 0；产物 `.build/诡秘世界.app`，`LSMinimumSystemVersion=26.0`，staged 资源含卡图 11 张、音频 66 条。
- `ditto` 安装到 `/Applications/诡秘世界.app`，`pgrep -x WorldOfMysteries` 在启动 10 秒后仍有进程（未崩溃退出）。
- Figma 侧：`design/figma-kit` 生成的插件在 Figma 桌面运行成功，产出变量集合「诡秘世界」（单 mode `Dark`）COLOR 71 + FLOAT 75、`type/*` 文字样式 10 条、`00 Foundations` 页面，插件自检面板报「问题：0」。

**仍未完成（不得被上述证据替代）**

- 用户视觉判断：本轮替换了 11 个 Features 文件里的数值引用，界面是否与改动前一致、是否可接受，仍须由用户看图确认；Agent 的截图与插件自检面板不构成视觉批准。
- VoiceOver 朗读走查仍未做（与上一节第 2 条同一件事）。
- 替换是机械投影，色值与尺寸取自改动前的真实数值，但**没有**做过像素级前后对比，不能声称「视觉零变化」。

## 2026-09-15 19:35 · 侧边栏命中修复 + 设计 token 接入门禁

**现象（用户报告）**：左侧菜单「点击时灵时不灵」。

**代码层定位（只读审查，不是实测复现）**——`apps/WorldOfMysteries/Sources/WorldOfMysteriesFeatures/InteractionFeedback.swift` 与 `ArchiveRootView.swift`：

1. `archiveInteractiveSurface` 的装饰层（悬停描边 + 焦点环）画在控件边界上，焦点环还向外多占 3pt（`.padding(-3)`），且没有退出命中测试；`contentShape(Rectangle())` 又声明在装饰层之前。描边正好压在行边界上，是贴在每一行边上的一条死带。
2. `SidebarTactileButtonStyle` 按下时把整行标签缩到 0.96：命中几何跟着渲染几何一起缩小，一条 202pt 宽的行两端各有约 4pt 的死带——贴边按下会在松手前移出区域，这次点击作废。
3. 三个侧边栏行组件（`ShellAreaButton` / `SidebarButton` / `PathwayButton`）没有在标签层声明整行命中区域，实际可点范围是画出来的圆角背景与文字图标——圆角外侧与文字右侧的留白点不动。
4. 选中行与「愚者」行的 `glassEffect(..., .interactive())` 在按钮内部自带指针响应。

**改动**：

1. 装饰层 `.allowsHitTesting(false)`，`contentShape` 移到装饰之后（`InteractionFeedback.swift`）；
2. 三个侧边栏行组件在标签层声明 `.contentShape(Rectangle())`，整行矩形可点；
3. `SidebarTactileButtonStyle` 的按下反馈改为亮度 + 不透明度，取消几何缩放；
4. 侧边栏行的材质去掉 `.interactive()`（卡片瓦片与故事节点保留自己的交互材质）；
5. 同类行级样式 `ShellRowButtonStyle` 的 0.99 按下缩放也改为不透明度反馈（世界首页 / 人物 / 故事书的行），瓦片与离散按钮的小幅缩放保留。

PRD 同步新增 §4.6「命中与反馈」，把这四条写成规范，避免同类问题在别的列表行上重现。同轮把设计 token 检查接进门禁（见下）。

**本轮机器证据**：

```text
swift test --package-path apps/WorldOfMysteries   → 142 tests, 0 failures
python3 tools/selfcheck.py                        → 自证通过：6/6 步（新增 design-tokens 步骤）
python3 tools/design_tokens.py check              → 退出 0
  [ok] 投影一致；10 条文字样式复用 token；无未登记的字面量（color 71, space 27, radius 17, stroke 4, size 8）
  [note] 未刻度类别冻结在内：不透明度 126 处 / 45 个取值；阴影半径 1 处 / 1；模糊半径 2 处 / 1；位移 1 处 / 1；结构性尺寸 83 处 / 35
./scripts/build-app.sh release                    → 退出 0；ditto 安装到 /Applications/诡秘世界.app
  安装后实测 LSMinimumSystemVersion=26.0、arm64；旧构建移入废纸篓（可恢复）
```

设计 token 门禁的接入面：`tools/selfcheck.py` 的 `design-tokens` 步骤（6 步）＋ CI Python job 的 `python tools/design_tokens.py check`；字面量扫描面扩到 `.cornerRadius(_)` 修饰符写法，并新增 `config/design-token-baseline.json` 冻结「尚无刻度」的类别（不透明度、阴影/模糊半径、位移、其它结构尺寸）——基线外的新取值会失败，删减放行。

**未验证（必须如实记录）**：

- **没有做真实鼠标点击验证**。本机合成点击只送到「最上面那个窗口」：测试期间应用窗口被 Chrome / ChatGPT / 微信盖住，坐标点击根本到不了侧边栏；用于验证的若干次坐标点击实际落在其它应用的窗口上（未观察到破坏性结果，但这段尝试不构成任何验证，也不再重复）。因此「时灵不灵」是否由上述四条造成、修复后是否消失，**须由用户在应用窗口最前时用真鼠标实测**。
- 一个仍需用户确认的旁路假设：若「应用不在最前时，回到应用的第一次点击必然无效、第二次才生效」，那是 macOS 的激活点击（acceptsFirstMouse）行为，与本次改动无关，需要单独处理。
- 视觉判断仍由用户进行：`SidebarTactileButtonStyle` 的按下反馈从「缩小」改成「变亮 + 变淡」是可见变化，是否可接受由用户决定。

## 2026-09-15 20:33 · 打开卡牌 / 人物页面卡顿：把卡图解码移出主线程

**现象（用户报告）**：「卡牌和人物页面打开为何会卡顿？」「必须优化性能，现在才多少卡啊」「不降低打开单卡品质的前提下，优化性能」。

**代码层定位（只读审查）**：`BundledArtworkView` 的 `body` 里直接 `NSImage(contentsOf:)` 并交给 `Image(nsImage:)`。

关键点是 **`NSImage(contentsOf:)` 本身不解码**：它只建立对文件的引用，真正的 PNG 解码被推迟到绘制那一刻——也就是帧提交路径上；而且每次 `body` 重新求值都会新建一个 `NSImage`，于是同一张卡的解码会被反复付钱（画册首屏 11 张、每次重绘都要重来）。

**实测（本机 Apple silicon，取 App 内 11 张真实卡图 1024×1536）**：

```text
解码发生在哪一步（/tmp/eagercheck2，单张平均）
  CGImageSourceCreateImageAtIndex + kCGImageSourceShouldCacheImmediately
      创建 20.5 ms/张  ｜ 之后首次绘制 1.9 ms/张      ← 解码在「创建」这一步（可放后台）
  不指定 ShouldCacheImmediately（对照组）
      创建  0.07 ms/张 ｜ 首次绘制 21.3 ms/张          ← 解码被推到「绘制」（旧代码就是这条路）

旧路径成本（/tmp/perfbench、/tmp/eagercheck，11 张真实卡图）
  画册一屏 11 张（NSImage 载入 + 绘制到 546×819）      282–296 ms
  同一批再渲染两次（body 重新求值 = 全部重解）         502–525 ms
  打开单卡 1 张（载入 + 绘制到 460×690）                23.4–23.8 ms
  打开单卡 1 张（载入 + 绘制到 920×1380，即 2x 背板）   57.5 ms

新路径成本
  冷解码 11 张瓦片档（后台线程、一次性）                286–300 ms
  之后 11 次缓存命中（主线程同步读）                     0.002 ms
  详情档全分辨率解码 11 张                               20.5 ms/张（同样在后台一次性完成）
```

**尺寸核对**：瓦片档 683×1024；详情档 1024×1536，与源图逐张一致（不一致 0 张）——**打开单卡不降品质**这一条有实测支撑。

**改动**：

1. 新增 `Sources/WorldOfMysteriesFeatures/ArtworkStore.swift`：`CGImageSource` 解码（瓦片档走 `CGImageSourceCreateThumbnailAtIndex` 上限 1024px；详情档 `thumbnailMaxPixel = nil`，按源图全分辨率解码）+ 两张 `NSCache`（瓦片按数量、详情按字节数限流）；解码一律在 `Task.detached` 里，主线程只同步读缓存；同一张同一档并发请求共用一份解码结果。
2. `BundledArtworkView` 不再在 `body` 里建 `NSImage`：命中缓存直接画，未命中先保留卡面底色，解码完成后淡入；文件确实缺失才回退程序化卡面。
3. 启动时预热画册卡图（先瓦片档、后详情档）；详情档预热张数设上限，卡图变多后改为按需后台解码。
4. 画册网格与人物档案分别套 `GlassEffectContainer` 合并渲染玻璃面，**容器 spacing（8pt）特意小于内部布局间距（16pt / 20pt）**：Apple 文档写明「容器 spacing 大于内部布局 spacing 会让相邻玻璃在静止时融合成一片」，取小于间距的值才既不融合、又能合并渲染。
5. 网格瓦片的发光由离屏模糊（`.blur(radius: 24)` ×11）改为同层径向渐变。**这一条对当前 11 张卡不改变可见像素**：11 张 CardArt PNG 实测 `hasAlpha: no`（`sips` 逐张核对），且卡图以 `scaledToFill` 铺满卡面区域，整层发光被不透明卡图完全遮住。详情页的发光保持原样（`.blur(radius: 44)`），未做替换。

**本轮机器证据**：

```text
swift test --package-path apps/WorldOfMysteries   → 150 tests, 0 failures
  新增 Tests/WorldOfMysteriesFeaturesTests/ArtworkStoreTests.swift（8 条）：
  详情档不设缩略图上限 / 瓦片档上限存在且小于源图 / 同图同档只解一次 /
  两档分开缓存 / 解码失败不写缓存 / 预热两档各一次且不重复 / 超上限不预热详情档 / 并发请求共用一次解码
python3 tools/selfcheck.py                        → 自证通过：6/6 步
python3 tools/design_tokens.py check              → 退出 0（无未登记字面量）
python3 -m unittest discover -s tests             → 201 tests OK（skipped=6）
./scripts/build-app.sh release                    → 退出 0；20:39 安装到 /Applications/诡秘世界.app
  旧构建（20:14）移入废纸篓：~/.Trash/诡秘世界-20260915-2033.app（可恢复）
  安装产物与 .build 产物逐字节一致（sha256 e730fc4d…a2d5）
```

**未验证（必须如实记录）**：

- **没有做端到端的真机帧时间测量**。`sample <pid>` 采样法这次不可用：采样时 App 窗口被最前面的应用（Baldur's Gate 3 全屏）完全遮住，被遮挡的窗口会被系统跳过合成，采样数字只能当成**下限**，不能用来判断改善。因此本轮改为用上面那组确定的微基准（同一批真实卡图、同一台机器、同一进程内对比两条路径）来说明「解码成本从哪一步挪到了哪一步」。
- **人物页面的卡顿没有独立实测数据**。人物页没有卡图，与解码无关；它的成本在视图图重建与逐面板玻璃采样上，本轮只做了玻璃容器化。**人物页是否明显变快，须由用户实测判断**；若仍卡，下一步应从 `AG::Graph::UpdateStack` 的视图图重建入手（侧栏行数、`.searchable` 重挂载、`detailContent` 整体换子树）。
- **玻璃容器化的净收益未测**。`GlassEffectContainer` 是 Apple 对「同屏多个玻璃效果」的推荐做法，但本机没有拿到可信的前后帧时间对比；容器 spacing 取小值保证的是**不产生视觉融合**，不是性能结论。
- **视觉判断仍由用户进行**（D16 口径不变）。本轮可视觉检查的三处：①打开单卡是否与之前完全一样（预期一致，有尺寸实测支撑）；②画册网格瓦片有无变化（发光层被卡图遮住，预期无变化）；③人物档案四个面板是否仍各自独立（预期独立，容器 spacing 8 < 面板间距 20）。

## 2026-09-15 21:33 · 卡图改走打包成片（App 内不放母版）

依据：用户「调研最佳实践，怎么解决多图高清，速度问题」→ 研究稿 `docs/research/2026-09-15-client-image-delivery-and-decode-research.md` → 「按照调研最佳实践处理」；决策记录 D23。

**改动**

1. `tools/production.py`：新增 `APP_IMAGE_TIERS`（tile 长边 1200 / JPEG q85、hero 长边 1536 / JPEG q88）与 `APP_IMAGE_DISPLAY_MINIMUM_LONG_EDGE = 960`；新增 `stage_app_card_art`，在 `stage-app-resources` 里按档生成成片，**母版 PNG 不再进包**。只缩不放（`long_edge = min(档位, 母版长边)`）。
2. `ArtworkStore.swift`：`ArtworkVariant` 改为解析 `<resource>-<tier>.jpg`；解码不再有任何缩放或缩略图上限；两档缓存改为按**字节成本**限流（tile 96MB / hero 128MB），并新增 `DispatchSourceMemoryPressure` 响应（warning/critical 时整体丢弃解码结果）；**两档预热都设 24 张上限**（今天 11 张卡时上限不生效，卡数上来后避免解了就淘汰）。
3. `ArchiveRootView.swift`：画册网格四列加列宽上限 `albumTileMaxDisplayWidth`（400pt）。

**包内档位（实测，11 张卡）**

| 档 | 像素 | 编码 | 合计 | 单张 |
|---|---|---|---|---|
| tile | 800×1200 | JPEG q85 | 5.75MB | 0.35–0.66MB |
| hero | 1024×1536 | JPEG q88 | 9.48MB | 0.55–1.10MB |

`CardArt` 合计 **15.22MB**（改动前约 33MB PNG，22 个 `.jpg`、0 个 `.png`）；`.app` 总量 60MB；打包时生成 22 档耗时 **1.1s**（`sips`，单张 2K → 800×1200 约 0.09s）。

**端到端校验（对已安装的 `/Applications/诡秘世界.app`，用与 `ArtworkDecoder` 逐字一致的 Bundle 查表方式）**

```text
11 张 × 2 档 = 22 次解码，全部命中；失败 0
  合计 111.1ms（首次冷启动 19.9ms，其余 3.0–6.6ms）
  hero 档每张 3.0–3.8ms；tile 档每张 3.9–6.6ms
负例：不存在的资源名 → 查不到 ✓
```

对照改动前：同一张卡按母版尺寸解码 17–21ms，且 2K PNG 现缩到 800×1200 要 65.8ms（研究稿）。本轮把这段成本从运行时整体搬到了打包时。

**列宽与显示尺寸（实测）**

- 窗口 1576×971pt（`CGWindowList`），四列时列宽约 **293pt**、卡面约 **269pt**（窗口截图逐列扫描，pt 由 2x 折算）。
- 269pt 在 2x 下需要 539px，瓦片成片是 800px 宽（余量 1.48×），**不会糊**。
- 列宽上限 400pt 在当前窗口**不生效**；按 `(窗口宽 − 266 − 72 − 48) ÷ 4 ≤ 400` 反解，窗口宽超过约 1986pt 才开始收敛。

**机器证据**

```text
swift test                                    → 152 tests, 0 failures（ArtworkStoreTests 10 条）
python3 -m unittest discover -s tests          → 209 tests OK（skipped=6）
python3 tools/selfcheck.py                     → 自证通过：6/6 步
python3 tools/design_tokens.py check           → 退出 0（无未登记字面量）
./scripts/build-app.sh release                 → 退出 0；21:45 安装到 /Applications/诡秘世界.app
  旧构建（20:39 / 21:33，后者含预热上限之前的版本）依次移入废纸篓：
    ~/.Trash/诡秘世界-20260915-2133-pre-image-derivatives.app
    ~/.Trash/诡秘世界-20260915-2145-pre-preload-cap.app        （均可恢复）
  安装产物与 .build 产物逐字节一致（sha256 bbb60a4a…107d）
  bundlecheck 复测该安装产物：11 张 × 2 档全部命中，22 次解码合计 99.5ms，负例正确
```

**Agent 屏幕观察（不是视觉批准）**：画册页四列排布正常、11 张卡图全部渲染出成片（无程序化占位）；打开「克莱恩·莫雷蒂」详情，卡面显示的是打包的 hero 成片，命运入口、六维信息、声音区均正常。人物页本轮未改动。

**未验证（必须如实记录）**

- **有损编码的视觉可接受性须由用户判定**（D16）：JPEG 相对 PNG 是有损的，Agent 的抽查（按显示尺寸比 MAE 6.46 / 4.45）**不构成**视觉批准。建议 1:1 对比三处：最暗的大面积渐变、最细的金饰线、最亮的高光。
- **没有端到端真机帧时间**（D22 的采样限制不变）。
- **列宽上限在多宽窗口下开始生效，Agent 只做了算式反解，没有在 1986pt 以上的窗口实测**（本机屏幕 1920pt 宽，拉不到那个尺寸）。
- **220 张规模下的包体与内存没有实测**，均按单张实测值外推。
