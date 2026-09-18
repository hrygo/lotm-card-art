# 全局设计 token 合同

一句话：**`config/design-tokens.json` 是唯一事实源，Figma 与客户端都是它的投影**，两边都不许各存一套数值。

## 适用范围

- **适用**：`apps/WorldOfMysteries` 客户端界面——颜色、间距、圆角、描边、字号、结构尺寸、动效时长与弹簧。
- **不适用**：卡牌美术与五档边框，那属于内容生产面，色彩事实源是 `config/quality-color-tokens.json`。两者关系见文末。

## 事实源：`config/design-tokens.json`

| 段 | 内容 | 数量 |
|---|---|---|
| `color` | 语义色板；支持 `{ "ref": "…", "alpha": … }` 引用链，引用在投影时才展开 | 71 |
| `space` | 间距刻度，键即取值 | 27 |
| `radius` | 圆角；含 `card`/`panel`/`sheet`/`chip`/`rail`/`ridge` 语义槽 | 17 |
| `stroke` | 描边宽度 | 4 |
| `type.size` / `type.weight` / `type.design` / `type.lineHeight` | 字号刻度、字重名、字体设计（serif/rounded/default）、行高百分比 | 18 / 5 / 3 / 3 |
| `size` | 结构性尺寸（侧栏宽、窗口最小尺寸、命中目标、控件高度） | 8 |
| `motion.duration` / `motion.spring` | 动效时长（键为毫秒数字串）与两档弹簧参数 | 7 / 2 |
| `material.gradient` | 材质渐变的两端色名，**说明性**，不进 Figma 变量 | 3 |
| `reference.cardTierColors` | 指向 `config/quality-color-tokens.json`，声明二者不是同一件事 | — |

## 两个投影

| 消费者 | 产物 | 归属 |
|---|---|---|
| 客户端 | `apps/WorldOfMysteries/Sources/WorldOfMysteriesFeatures/DesignTokens.generated.swift` | 生成物，勿手改；对外是 `DesignTokens.Palette / Space / Radius / Stroke / FontSize / Size / MotionDuration / MotionSpring` |
| Figma | `design/figma-kit/tokens.js` | 生成物，勿手改；插件运行时读作 `TOKEN_DATA` |

命名规则：`a.b-c` → `aBc`；数字键加类型前缀——`space` 是 `Space.s12`，`radius` 是 `Radius.r14`，字号是 `FontSize.s13`，时长是 `MotionDuration.ms160`。

客户端视图通过 `ArchiveTheme` 这一层语义取色，不直接在视图里写色值；`ArchiveTheme` 内部才引用 `DesignTokens.Palette`。

## Figma 侧怎么用

`design/figma-kit/` 是这个文件对应的 Figma 生成器（插件源码，生成物只落到临时目录，不写回仓库）。

```bash
node design/figma-kit/build.js
```

这一步先跑冒烟测试，再把 `tokens.js + main.js` 合成 `code.js`，连同 `manifest.json` 落到 `~/Downloads/mysteries-figma-kit/`（ASCII 目录名：Figma 的清单选择器在中文路径上会卡住）。

然后在 Figma 桌面：

1. `Plugins → Development → Import plugin from manifest…`，选该目录下的 `manifest.json`；
2. `Plugins → Development → Mysteries Design Tokens`（或 ⌥⌘P 运行上一个插件）。

产出：变量集合「卡牌演示」（单 mode `Dark`）、`type/*` 文字样式 10 条、`00 Foundations` 页面（分组色板 + 间距/圆角/描边/字号/行高/结构尺寸刻度 + 文字样式样本 + 说明），以及一个自检面板。重跑幂等：同名变量与样式复用，`00 Foundations` 页每次清空重建。

2026-09-15 首次实测结果：COLOR 71 · FLOAT 75（合计 146）、文字样式 10 条、色板 71 张且全部绑定变量、自检问题 0。

之后 token 增加两项（`space.60`、`radius.ridge`），本地冒烟测试现在报「COLOR 71 · FLOAT 77（合计 148）」；**Figma 文档里仍是上次运行留下的 75 个 FLOAT**，需要在 Figma 桌面重跑一次插件才会补齐——那一步是手动操作，不由本文件或 CI 代跑，因此这里不写成「Figma 已实测 77」。

## 什么不进 Figma 变量

渐变材质、阴影扩散、动效时长与弹簧参数。Figma 变量只能表达 COLOR/FLOAT，这些参数留在 config 与代码里，Figma 侧只用等价色板示意，避免看起来像被 token 化。

## 检查

```bash
python3 tools/design_tokens.py check      # 投影漂移 + 字面量绕过 + Figma 文字样式复用
python3 tools/design_tokens.py baseline   # 只在这一步显式重写冻结登记时使用
node design/figma-kit/build.js            # Figma 生成器冒烟测试
```

`check` 覆盖三件事：① 两份投影与事实源逐字一致；② 客户端 Features 里的设计字面量（`0` 放行）；③ Figma 生成器里 10 条 `type/*` 用到的字号、字重、行高都在 config 里，手写表不能自己发明数值。

第 ② 件分两档，区别在于**这个类别有没有刻度**：

| 档 | 类别 | 判据 |
|---|---|---|
| 有刻度 | 字号、内边距与轴内边距、堆叠间距、弹性间距（`Spacer(minLength:)`）、圆角（`cornerRadius:` 与 `.cornerRadius(_)` 两种写法）、描边、等于某个 `size` token 的 `width`/`height`/`minWidth`/`minHeight`/`maxWidth`/`maxHeight` | 出现字面量即失败；值等于现有 token 时提示改用 `DesignTokens.*` |
| 尚无刻度 | 不透明度、阴影半径、模糊半径、位移、其它结构尺寸 | 按 `config/design-token-baseline.json` **冻结**：基线外的新取值失败，删减放行；同一取值多用一处也算新增 |

`build.js` 的冒烟测试在 Node 里用 figma stub 跑完整流程，并复刻两条 Figma 契约：插件沙箱是严格模式（未声明的标识符直接 `ReferenceError`）、任何 `fontName` 赋值前必须先 `loadFontAsync`。这两类问题编辑器语法检查看不出来，只能在运行时暴露。

**边界**：Figma 那一步不在 CI 里，真实产出仍需在 Figma 桌面里跑。`check` 通过只证明数值一致、没有绕过，不证明设计好坏，也不构成任何视觉批准。

**冻结不是批准**：`config/design-token-baseline.json` 只是把还没有刻度的数字留在可见处——新增一个不透明度或阴影半径必须显式重跑 `baseline`，diff 进评审。等这些类别真正定出刻度（例如不透明度档位、层级阴影档位），基线应随之缩到空。

**接入位置**：`tools/selfcheck.py` 的 `design-tokens` 步骤与 CI 的 Python job 都会跑 `check`，两者都是硬门禁，失败即非零退出。

## 改 token 的流程

1. 改 `config/design-tokens.json`；
2. `python3 tools/design_tokens.py generate`；
3. `python3 tools/design_tokens.py check`；
4. `node design/figma-kit/build.js`，在 Figma 重跑插件；
5. 客户端 `swift test --package-path apps/WorldOfMysteries` 与 `apps/WorldOfMysteries/scripts/build-app.sh release`。

只改 Figma、只改 Swift 或只改 config 其中一边，都会被 `check` 判为漂移。

若新增写法落在「尚无刻度」的类别里（例如新写 `.opacity(0.37)`），`check` 会拒绝。两条合法出路是：改用已有取值，或先给这个类别定刻度再登记新值；最后才是显式重跑 `baseline` 并把 diff 交给评审。

## 与 `config/quality-color-tokens.json` 的关系

两份文件管的对象不同：`quality-color-tokens.json` 是卡牌五档边框的生产配色（内容生产面）；本文件里的 `tier.*` 是客户端图鉴里的档位标签与发光色。改动其中一个不影响另一个，不要互相引用数值。

## 已知边界

- Figma 生成器依赖 Figma 桌面手动运行，不在 CI 覆盖范围内。
- 免费版 Figma 每个变量集合只允许 1 个 mode，因此这里只有 `Dark`；产品本身也只有深色一档，不做浅色克隆。
- 字体：Figma 里用 Inter 呈现，生产实现是 SF Serif / SF Rounded，文字样式说明里写明对应关系；本文件不涉及字体授权。
- 冻结基线只约束 `apps/WorldOfMysteries/Sources/WorldOfMysteriesFeatures/*.swift`：Core/App 目标与 `tools/render/**` 不在扫描面内。
- 未刻度类别（不透明度、阴影/模糊半径、位移、其它结构尺寸）目前只是**被冻结**，不是被 token 化；给它们定刻度是设计决策，尚未做。
- 光标样式、`.help()` 文案、`glassEffect` 材质参数属于交互与材质，不是数值 token，本文件不管。
- `check` 通过不等于设计被批准：视觉判断由用户做。
