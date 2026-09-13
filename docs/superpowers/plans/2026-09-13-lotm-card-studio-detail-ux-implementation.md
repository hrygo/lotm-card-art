# LotmCardStudio 详情页固定舞台与交互反馈 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (- [ ]) syntax for tracking.

**Goal:** 将卡牌详情页重构为固定 420×630pt 动效围台与弹性信息轨，统一身份/故事布局、字幕位置、鼠标光标和交互反馈，消除容器重叠并为卡牌动效保留安全空间。

**Architecture:** 保留 AlbumViewModel 与 SpeechPlaybackCoordinator 的领域职责，只重组 ArchiveRootView 的详情页布局。新增可测试的详情几何契约和共享交互反馈修饰器；详情页以正常 SwiftUI 布局流在宽窗口使用双栏、窄窗口使用上下堆叠，固定围台永远不参与弹性压缩。

**Tech Stack:** Swift 6.2、SwiftUI、AppKit NSCursor、XCTest、macOS 26。

**Spec:** docs/superpowers/specs/2026-09-13-lotm-card-studio-detail-ux-design.md

## Global Constraints

- 最低部署版本为 macOS 26.0，使用当前 SDK 的 SwiftUI 能力。
- 详情页主卡面、信息轨和故事内容必须使用正常布局流，不使用绝对定位、负偏移、固定高度遮挡或依赖 z-index 解决重叠。
- 卡牌动效围台固定为 420×630pt，卡牌本体约 320×480pt，横向安全空间约 50pt、纵向安全空间约 75pt。
- 信息轨在双栏模式中保持 460–760pt 的有界宽度，内容变长时由信息轨所在的详情滚动容器承载。
- 只有真实可点击元素使用 pointing hand；普通背景、卡牌围台、卡面和文字使用普通箭头。
- 新增交互优先补测试；完成后必须运行 Swift 测试、仓库测试、debug/release 构建并更新本机 QA 记录。
- 不改变卡牌内容事实、收藏数据模型、SpeechRail API 或现有用户未提交改动。

---

## 文件边界

- Create: apps/LotmCardStudio/Sources/LotmCardStudioFeatures/CardDetailLayout.swift
  - 保存固定围台、卡牌、信息轨和响应式阈值；提供 CardDetailMode。
- Create: apps/LotmCardStudio/Sources/LotmCardStudioFeatures/InteractionFeedback.swift
  - 保存 AppKit 光标修饰器和统一 hover/pressed/focus 视觉反馈。
- Modify: apps/LotmCardStudio/Sources/LotmCardStudioFeatures/ArchiveRootView.swift
  - 重组 CardDetailView，新增 CardMotionViewport 与 DetailRail，调整身份/故事内容边界和按钮反馈。
- Modify: apps/LotmCardStudio/Tests/LotmCardStudioFeaturesTests/ArchiveRootViewTests.swift
  - 验证详情几何契约和宽窄布局阈值。
- Modify: apps/LotmCardStudio/docs/qa/m1-local-run.md
  - 记录新详情页的自动化结果、安装产物和原生手动验收结果。

## Task 1: 建立可测试的详情几何契约

**Files:**

- Create: apps/LotmCardStudio/Sources/LotmCardStudioFeatures/CardDetailLayout.swift
- Test: apps/LotmCardStudio/Tests/LotmCardStudioFeaturesTests/ArchiveRootViewTests.swift

**Interfaces:**

- Produces CardDetailMode.identity、CardDetailMode.story、CardDetailLayout.motionViewportSize、CardDetailLayout.cardSize 和 CardDetailLayout.usesTwoColumns(for:)。
- Consumes no model or network state；布局组件和测试只依赖常量。

- [ ] **Step 1: Write the failing geometry tests**

在 ArchiveRootViewTests.swift 增加：

~~~swift
    func testCardDetailLayoutReservesFixedMotionViewport() {
        XCTAssertEqual(CardDetailLayout.motionViewportSize, CGSize(width: 420, height: 630))
        XCTAssertEqual(CardDetailLayout.cardSize, CGSize(width: 320, height: 480))
        XCTAssertEqual(CardDetailLayout.horizontalSafeArea, 50)
        XCTAssertEqual(CardDetailLayout.verticalSafeArea, 75)
        XCTAssertEqual(CardDetailLayout.railMinimumWidth, 460)
        XCTAssertEqual(CardDetailLayout.railMaximumWidth, 760)
    }

    func testCardDetailLayoutStacksOnlyBelowTwoColumnContentWidth() {
        XCTAssertTrue(CardDetailLayout.usesTwoColumns(for: 912))
        XCTAssertFalse(CardDetailLayout.usesTwoColumns(for: 911))
    }
~~~

- [ ] **Step 2: Run the focused test and verify the new contract is absent**

Run: cd apps/LotmCardStudio && swift test --filter ArchiveRootViewTests.testCardDetailLayout

Expected: FAIL because CardDetailLayout and its constants do not exist yet.

- [ ] **Step 3: Add the minimal contract implementation**

创建 CardDetailLayout.swift：

~~~swift
import CoreGraphics

enum CardDetailMode: String, CaseIterable, Identifiable, Sendable {
    case identity
    case story

    var id: Self { self }

    var title: String {
        switch self {
        case .identity: return "身份"
        case .story: return "故事"
        }
    }
}

enum CardDetailLayout {
    static let contentMaximumWidth: CGFloat = 1240
    static let motionViewportSize = CGSize(width: 420, height: 630)
    static let cardSize = CGSize(width: 320, height: 480)
    static let horizontalSafeArea: CGFloat = 50
    static let verticalSafeArea: CGFloat = 75
    static let railMinimumWidth: CGFloat = 460
    static let railMaximumWidth: CGFloat = 760
    static let stageToRailGap: CGFloat = 32
    static let horizontalPadding: CGFloat = 40
    static let verticalPadding: CGFloat = 32

    static let twoColumnMinimumContentWidth =
        motionViewportSize.width + stageToRailGap + railMinimumWidth

    static func usesTwoColumns(for contentWidth: CGFloat) -> Bool {
        contentWidth >= twoColumnMinimumContentWidth
    }
}
~~~

- [ ] **Step 4: Run the focused test and verify it passes**

Run: cd apps/LotmCardStudio && swift test --filter ArchiveRootViewTests.testCardDetailLayout

Expected: PASS with both geometry tests passing.

- [ ] **Step 5: Commit the isolated contract**

~~~bash
git add apps/LotmCardStudio/Sources/LotmCardStudioFeatures/CardDetailLayout.swift apps/LotmCardStudio/Tests/LotmCardStudioFeaturesTests/ArchiveRootViewTests.swift
git commit -m "test: lock card detail layout contract"
~~~

若工作区已有未提交改动使按路径提交会混入其他内容，则保留本任务改动未提交，并在最终 QA 中列出实际提交边界；不得为了提交而重置或覆盖已有文件。

## Task 2: 统一光标和交互反馈

**Files:**

- Create: apps/LotmCardStudio/Sources/LotmCardStudioFeatures/InteractionFeedback.swift
- Modify: apps/LotmCardStudio/Sources/LotmCardStudioFeatures/ArchiveRootView.swift

**Interfaces:**

- Produces archiveCursor(_:) 和 archiveInteractiveSurface(accent:cornerRadius:hoverScale:) 两个 View 修饰器。
- Consumes accessibilityReduceMotion，不改变 Button 的 action、可访问性标签或领域状态。

- [ ] **Step 1: Add a cursor and hover behavior test seam**

保留 Task 1 的几何测试作为编译入口；在实现中将光标和 hover 逻辑集中到一个文件，避免每个按钮复制 onHover。手动验收用四类命中区域核对：侧栏项目、画册卡片、详情 CTA/章节行显示 pointing hand；卡牌围台和普通文字显示 arrow。

- [ ] **Step 2: Implement the shared modifiers**

创建 InteractionFeedback.swift：

~~~swift
import AppKit
import SwiftUI

private struct ArchiveCursorModifier: ViewModifier {
    let cursor: NSCursor

    func body(content: Content) -> some View {
        content.onHover { isHovering in
            if isHovering {
                cursor.set()
            } else {
                NSCursor.arrow.set()
            }
        }
    }
}

private struct ArchiveInteractiveSurfaceModifier: ViewModifier {
    let accent: Color
    let cornerRadius: CGFloat
    let hoverScale: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .onHover { isHovered = $0 }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(accent.opacity(isHovered ? 0.62 : 0), lineWidth: 1)
            }
            .scaleEffect(isHovered && !reduceMotion ? hoverScale : 1)
            .animation(
                reduceMotion ? nil : .easeOut(duration: 0.16),
                value: isHovered
            )
            .modifier(ArchiveCursorModifier(cursor: .pointingHand))
    }
}

extension View {
    func archiveCursor(_ cursor: NSCursor) -> some View {
        modifier(ArchiveCursorModifier(cursor: cursor))
    }

    func archiveInteractiveSurface(
        accent: Color,
        cornerRadius: CGFloat,
        hoverScale: CGFloat = 1
    ) -> some View {
        modifier(
            ArchiveInteractiveSurfaceModifier(
                accent: accent,
                cornerRadius: cornerRadius,
                hoverScale: hoverScale
            )
        )
    }
}
~~~

- [ ] **Step 3: Apply feedback only to real interactive surfaces**

在 ArchiveRootView.swift：

- SidebarButton 的 label 使用 archiveInteractiveSurface(accent: ArchiveTheme.amber, cornerRadius: 12)。
- 已启用的 PathwayButton 使用途径颜色；禁用项目只保留 disabled、透明度和普通箭头。
- CardTileView 使用卡牌状态色、圆角 17、hover scale 1.01。
- PrimaryButtonStyle、SecondaryButtonStyle 使用圆角 12 的统一反馈；IconButtonStyle 使用圆角 10。
- 故事章节行使用圆角 8 的反馈。
- CardMotionViewport、信息轨背景、字幕和语义文本显式调用 archiveCursor(.arrow)，不把整块面板变成可点击区域。

- [ ] **Step 4: Build the feature target**

Run: cd apps/LotmCardStudio && swift test --filter ArchiveRootViewTests

Expected: PASS；没有 AppKit/SwiftUI 类型错误。

## Task 3: 用固定动效围台替换详情页左列

**Files:**

- Modify: apps/LotmCardStudio/Sources/LotmCardStudioFeatures/ArchiveRootView.swift:534-602

**Interfaces:**

- Produces CardMotionViewport(card:)，其内部固定视口为 CardDetailLayout.motionViewportSize，卡面为 CardDetailLayout.cardSize。
- CardDetailView 继续接收 AlbumCard、AlbumViewModel 和 SpeechPlaybackCoordinator，不改变播放领域接口。

- [ ] **Step 1: Add the fixed viewport view**

在 ArchiveRootView.swift 中新增 CardMotionViewport：

~~~swift
private struct CardMotionViewport: View {
    let card: AlbumCard

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(ArchiveTheme.coal.opacity(0.72))
                Circle()
                    .fill(ArchiveTheme.amber.opacity(0.18))
                    .frame(width: 260, height: 260)
                    .blur(radius: 48)
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(ArchiveTheme.amber.opacity(0.22), lineWidth: 1)
                    .padding(24)
                ArchiveArtworkView(
                    theme: card.visualTheme,
                    compact: false,
                    resourceName: card.artworkResourceName
                )
                .frame(
                    width: CardDetailLayout.cardSize.width,
                    height: CardDetailLayout.cardSize.height
                )
            }
            .frame(
                width: CardDetailLayout.motionViewportSize.width,
                height: CardDetailLayout.motionViewportSize.height
            )
            .archiveCursor(.arrow)

            HStack {
                Text(card.identity.sequenceName.uppercased())
                    .foregroundStyle(ArchiveTheme.amber)
                Spacer()
                Text(card.identity.displayName)
                    .foregroundStyle(ArchiveTheme.primary)
            }
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .frame(width: CardDetailLayout.motionViewportSize.width)
            .archiveCursor(.arrow)
        }
    }
}
~~~

- [ ] **Step 2: Replace the old card column in CardDetailView**

保留外层垂直 ScrollView，使用 GeometryReader 读取详情可用宽度。内容容器设置最大宽度 1240pt、水平 40pt 和垂直 32pt 内边距；宽度判断使用：

~~~swift
let contentWidth = max(
    0,
    min(
        proxy.size.width - CardDetailLayout.horizontalPadding * 2,
        CardDetailLayout.contentMaximumWidth
    )
)
~~~

双栏时使用：

~~~swift
HStack(alignment: .top, spacing: CardDetailLayout.stageToRailGap) {
    CardMotionViewport(card: card)
    DetailRail(card: card, model: model, playback: playback, mode: detailMode)
}
~~~

窄栏时使用同一两个组件的 VStack(alignment: .center, spacing: 28)，不改变围台的固定尺寸。删除原先 VStack(width: 340) 和底部 StoryDrawer 兄弟节点。

- [ ] **Step 3: Run the layout tests and feature tests**

Run: cd apps/LotmCardStudio && swift test --filter ArchiveRootViewTests

Expected: PASS；详情视图可构造，几何阈值保持稳定。

## Task 4: 将身份与故事收束到弹性信息轨

**Files:**

- Modify: apps/LotmCardStudio/Sources/LotmCardStudioFeatures/ArchiveRootView.swift:602-1208

**Interfaces:**

- Produces DetailRail，提供 身份/故事 两段式模式切换，保持同一个信息轨容器。
- Consumes model.isStoryDrawerPresented 作为与现有 toolbar 的兼容状态；设置模式时同步该属性，保留 Escape 返回画册和 toolbar 故事按钮。
- LiveCaptionRail 继续是身份模式中语音操作下方的唯一实时字幕轨；故事模式只保留紧凑播放状态和全文。

- [ ] **Step 1: Add the rail mode binding**

在 CardDetailView 中增加：

~~~swift
private var detailMode: Binding<CardDetailMode> {
    Binding(
        get: { model.isStoryDrawerPresented ? .story : .identity },
        set: { model.isStoryDrawerPresented = $0 == .story }
    )
}
~~~

在 DetailRail 顶部使用系统 segmented picker：

~~~swift
Picker("详情模式", selection: mode) {
    ForEach(CardDetailMode.allCases) { detailMode in
        Text(detailMode.title).tag(detailMode)
    }
}
.pickerStyle(.segmented)
.labelsHidden()
.accessibilityLabel("详情模式")
~~~

- [ ] **Step 2: Implement the single information rail surface**

DetailRail 的根视图使用一个圆角 22pt 的 glassEffect 容器，设置 frame(minWidth: 460, maxWidth: 760, alignment: .topLeading)；宽度不足的上下布局由父视图移除最小宽度约束。

身份模式顺序固定为：模式切换、身份标题、角色族谱、语音配置和 CTA、LiveCaptionRail、六维语义。故事模式顺序固定为：模式切换、故事标题、章节正文、播放控制和章节列表。

- [ ] **Step 3: Remove nested outer surfaces from IdentityPanel and StoryDrawer**

保留两者的内容与播放逻辑，移除其根部重复的 padding、background、glassEffect 和外框；这些内容由 DetailRail 的单一外层容器承载。保留字幕失败时的文字稿、故事章节的审批状态和当前章节保护。

- [ ] **Step 4: Make mode switching motion-safe**

使用 @Environment(\.accessibilityReduceMotion)；减少动态效果时直接更新模式，不使用 transition。常规模式切换只允许 0.16–0.22 秒的淡入或内容替换，不改变 CardMotionViewport 的位置和尺寸。

- [ ] **Step 5: Run all Swift tests**

Run: cd apps/LotmCardStudio && swift test

Expected: 所有现有字幕、故事章节、SpeechRail 回退和新增布局测试 PASS。

## Task 5: 构建、安装和原生 QA

**Files:**

- Modify: apps/LotmCardStudio/docs/qa/m1-local-run.md

**Interfaces:**

- Consumes the release app produced by scripts/build-app.sh and the current installed SpeechRail loopback configuration.
- Produces a QA record with exact commands, package metadata, visual geometry observations, cursor/feedback observations, and any lock-screen limitation.

- [ ] **Step 1: Run repository and app regression tests**

Run:

~~~bash
cd apps/LotmCardStudio
swift test
cd ../..
python3 -m unittest discover -s tests -v
~~~

Expected: both commands exit 0；记录实际测试数量，不用计划中的旧数字代替实测结果。

- [ ] **Step 2: Build debug and release apps**

Run:

~~~bash
cd apps/LotmCardStudio
./scripts/build-app.sh debug
./scripts/build-app.sh release
~~~

Expected: 两个命令都生成 .build/LotmCardStudio.app，release 主程序为 arm64，LSMinimumSystemVersion=26.0。

- [ ] **Step 3: Install and verify the release app**

Run:

~~~bash
ditto apps/LotmCardStudio/.build/LotmCardStudio.app /Applications/LotmCardStudio.app
codesign --verify --deep --strict --verbose=2 /Applications/LotmCardStudio.app
open -na /Applications/LotmCardStudio.app
~~~

Expected: 签名验证通过，应用启动；不读取或写入 SpeechRail 密钥。

- [ ] **Step 4: Perform native manual acceptance**

在已解锁桌面中检查：

1. 详情页宽窗口显示固定围台与右侧信息轨；围台四周有可见安全留白，右栏不无限拉伸。
2. 窄窗口切换为上下布局；固定围台不压缩，信息轨不覆盖卡面。
3. 身份/故事切换只替换信息轨；卡面位置和围台尺寸不变。
4. 字幕位于 CTA 下方，故事全文只在故事模式出现；章节变长不遮挡按钮。
5. 侧栏、卡片、CTA、章节行显示 pointing hand；围台、卡面和普通文字显示 arrow。
6. hover、pressed、selected 和键盘 focus 都有可见反馈；开启减少动态效果后不出现缩放动画。

若 CUA 或系统仍处于锁屏，记录为“自动化和静态检查已完成，点击式原生验收待解锁”，不得把未观察到的点击结果写成通过。

- [ ] **Step 5: Update the QA record and run final diff checks**

在 QA 文件新增“固定动效围台与信息轨重构”小节，记录实际窗口、固定尺寸、交互反馈和手动验收状态。运行：

~~~bash
git diff --check
git status --short
~~~

Expected: 无 whitespace 错误；只报告本轮预期的 UI、测试和 QA 改动以及已有工作区改动。

## Self-review checklist

- Spec coverage: Task 1 covers all fixed geometry and responsive threshold rules; Task 2 covers cursor, hover, pressed, selected, focus and reduce-motion behavior; Task 3 covers the non-overlapping fixed stage; Task 4 covers identity/story/subtitle ownership; Task 5 covers tests, builds, installation and native QA.
- Type consistency: CardDetailMode and CardDetailLayout are defined in Task 1; Tasks 3 and 4 consume those exact names; DetailRail receives Binding<CardDetailMode>; no task introduces a second story state.
- No placeholder steps: every test, implementation, command and acceptance check names its file, symbol, expected result or concrete visual observation.
- Scope safety: no task changes card facts, SpeechRail protocol, collection persistence, content approval, or existing unrelated dirty files.
