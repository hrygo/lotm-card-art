# LotmCardStudio MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or **superpowers:executing-plans** to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在现有 `lotm-card-art` 内容仓库之上交付一个本地优先的原生 macOS 卡牌画册 MVP：可导入内容快照、浏览动态数量的卡牌、分离正式/候选收藏与愿望清单，并在用户主动唤醒后通过本机 SpeechRail 播放人工确认的台词和故事。

**Architecture:** 将内容事实源、App 管理的不可变快照、用户收藏数据库和音频缓存分成四个边界。SwiftPM 提供无第三方依赖的 macOS 可执行包：`LotmCardStudioCore` 负责领域模型、导入、持久化、SpeechRail HTTP 客户端和播放协调；`LotmCardStudioFeatures` 负责 SwiftUI 画册与状态视图；可执行 target 只负责 App 生命周期和依赖组装。导入器同时兼容当前旧式 `sequences/<seq>/card.json` 卡位和未来带 `card_id`/`character_id` 的多身份卡牌记录。

**Tech Stack:** Swift 6.3、SwiftUI、AppKit、SwiftData、Foundation、CryptoKit、AVFoundation、URLSession、Swift Package Manager、XCTest；macOS 14.0+，首期 `arm64`，不添加第三方运行时依赖。

**Spec:** `docs/superpowers/specs/2026-09-13-lotm-card-studio-design.md`

## Global Constraints

- 原生 macOS App 优先，未来再提供网页目录和分享能力。
- Git 仓库导入为 App 管理的内容库，不在 MVP 中直接编辑原始仓库。
- 内容数量为动态的 `0…N`，当前 220 个序列卡位只是脚手架容量，不是产品总数。
- 一卡一身份；一个序列可以有零张、一张或多张角色卡。
- 多张属于同一角色的卡通过 `character_id` 关联，但仍分别收藏、发声和展示。
- 默认静默，用户点击“唤醒”后卡牌才说话。
- 口头禅和唤醒语使用第一人称，故事采用第三人称档案叙述。
- MVP 只使用人工确认的台词与故事文本，由本机 SpeechRail 合成；不在 App 内实时调用 AI 生成内容。
- 正式收藏、候选收藏和愿望清单分开；正式收藏只统计确认的实际卡牌。
- SpeechRail 不可用时，画册、收藏和文字稿继续工作；只有播放能力进入不可用状态。
- 音频、收藏、笔记和播放历史只保存在 App 管理目录，不写入公开仓库；API key、模型路径、日志和原始音频不得进入 Git。
- App 使用 SpeechRail loopback HTTP API：`/health`、`/readyz`、`/v1/voices`、`/v1/audio/speech`；不复用 `SpeechRailApp` 的 XPC 控制协议，也不启动、停止或下载 SpeechRail runtime。
- 当前仓库的 `0.3.0` 旧卡位必须继续通过现有脚手架检查；新增多身份记录使用向后兼容的 `0.4.0` 扩展，不把旧 `card_id` 静默当作已确认的身份卡。
- 所有跨层接口先定义稳定 ID、输入校验和稳定错误码；外部 JSON、文件路径和 HTTP 响应在边界处校验。
- 每个任务先写失败测试，再写最小实现；每个任务单独运行测试并提交一个可回退的 Git commit。

---

## Scope Check

内容契约、导入快照、收藏持久化、语音播放和 Album UI 彼此有明确边界，但首个可运行垂直切片需要它们一起工作，因此保留在同一 MVP 计划中。每个任务都有独立测试和可回退提交；AI 工坊、网页、云同步和游戏规则不进入本计划。

## 文件清单与职责

### 内容仓库契约

- Modify: `schemas/card.schema.json` — 保留 `0.3.0` 旧卡位，增加 `0.4.0` 多身份卡的稳定 ID 字段和格式约束。
- Create: `schemas/narrative.schema.json` — 台词、口头禅、故事章节、来源状态和音色绑定的机器可读契约。
- Create: `schemas/library-manifest.schema.json` — App 快照归一化后的跨语言清单契约。
- Modify: `tools/cardctl.py` — 扫描旧卡位与多身份路径，校验新的 ID/旁车叙事记录，并保持标准库 Python 3.10+。
- Modify: `tests/test_cardctl.py` — 增加旧卡位兼容、多身份记录、同角色多卡和非法迁移的反例测试。
- Modify: `docs/DECISIONS.md` — 记录 `slot_id`、`card_id`、`character_id` 和叙事旁车文件的迁移决策。

### macOS App 包

- Create: `apps/LotmCardStudio/Package.swift` — SwiftPM 包、macOS 平台和三个 target。
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioCore/Domain/StableIDs.swift` — 稳定 ID 类型和边界校验。
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioCore/Domain/ContentStatus.swift` — `unfilled`、`proposed`、`unresearched`、`confirmed` 与收藏状态。
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioCore/Domain/CardModels.swift` — 途径、序列、卡牌身份、六维状态和内容快照。
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioCore/Domain/NarrativeModels.swift` — 台词、口头禅、故事章节和来源状态。
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioFeatures/Bootstrap.swift` — SwiftPM 初始 target 的可编译入口，后续由 Album UI 替换。
- Create: `apps/LotmCardStudio/Sources/LotmCardStudio/main.swift` — 初始可执行入口，后续接入真实 App 场景。
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioCore/Import/RawRepositoryModels.swift` — 当前仓库 JSON 的严格 `Codable` 解码模型。
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioCore/Import/RepositoryFileSystem.swift` — 文件系统抽象、相对路径保护和测试 fake。
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioCore/Import/RepositoryImporter.swift` — 目录导入、状态归类、资产复制清单和警告报告。
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioCore/Import/ContentHashing.swift` — 内容哈希、快照 ID 和音频缓存键。
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioCore/Import/SnapshotStore.swift` — 不可变快照写入、活动指针切换和失败回退。
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioCore/Collection/CollectionModels.swift` — 正式收藏、候选收藏、愿望清单和活动记录。
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioCore/Collection/CollectionReconciler.swift` — 新旧快照按稳定 `card_id` 对账。
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioCore/Persistence/UserStore.swift` — 用户数据端口和内存测试实现。
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioCore/Persistence/SwiftDataUserStore.swift` — SwiftData 模型与 App Support 存储。
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioCore/SpeechRail/SpeechRailTypes.swift` — HTTP 请求、音色能力和错误码。
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioCore/SpeechRail/SpeechRailClient.swift` — `URLSession` actor 客户端。
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioCore/SpeechRail/AudioCache.swift` — 本地音频缓存、元数据校验和原子写入。
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioCore/Playback/PlaybackCoordinator.swift` — 单播放焦点、唤醒、故事播放、暂停、停止和打断。
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioCore/Playback/AudioPlayer.swift` — `AVAudioPlayer` 适配器与 fake 播放器。

### Album UI 与交付

- Create: `apps/LotmCardStudio/Sources/LotmCardStudioFeatures/App/AppModel.swift` — 应用依赖、导入状态和选中对象。
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioFeatures/ViewModels/AlbumViewModel.swift` — 动态计数、路径筛选和画廊排序。
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioFeatures/ViewModels/CardDetailViewModel.swift` — 六维回读、收藏动作和声音状态。
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioFeatures/Views/AppShellView.swift` — Album 导航、书架和窗口布局。
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioFeatures/Views/LibraryHomeView.swift` — 书架与画廊首页。
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioFeatures/Views/CardGalleryView.swift` — 默认平铺卡牌网格和状态筛选。
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioFeatures/Views/CardTileView.swift` — 卡面缩略图、状态徽标和收藏提示。
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioFeatures/Views/CardDetailView.swift` — 秘史书页三栏布局。
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioFeatures/Views/CardFaceView.swift` — 大比例卡面、缺图状态和日常动效。
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioFeatures/Views/CharacterPanelView.swift` — 常驻身份、音色和收藏操作面板。
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioFeatures/Views/StoryDrawerView.swift` — 底部故事章节、文字稿和播放进度。
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioFeatures/Views/CharacterFamilyView.swift` — 可选的同 `character_id` 角色族谱/时间线。
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioFeatures/Views/CollectionViews.swift` — 正式收藏、候选收藏和愿望清单。
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioFeatures/Views/Motion/CardMotion.swift` — 微光呼吸、灵性脉动和特殊牌面显影。
- Modify: `apps/LotmCardStudio/Sources/LotmCardStudio/main.swift` — 将初始入口替换为 `@main` App 和菜单命令。
- Create: `apps/LotmCardStudio/Tests/LotmCardStudioCoreTests/` — Core 单元测试和资源 fixture。
- Create: `apps/LotmCardStudio/Tests/LotmCardStudioFeatureTests/` — ViewModel 与交互状态测试。
- Create: `apps/LotmCardStudio/scripts/build-app.sh` — 本地构建 `.app` bundle，不负责签名或发布。
- Create: `apps/LotmCardStudio/scripts/test-app.sh` — Swift 测试、构建和 bundle 检查入口。
- Create: `apps/LotmCardStudio/README.md` — App 本地运行、内容导入、SpeechRail 依赖和隐私边界。
- Create: `apps/LotmCardStudio/QA.md` — 手工验收路径和 SpeechRail 可用/不可用两套结果。
- Modify: `README.md` — 增加 App 入口、当前 MVP 范围和本地构建链接。
- Modify: `.gitignore` — 忽略 SwiftPM `.build`、本地 `.app` 输出和 App 测试临时目录。

## Data and Interface Contract

### Source layout

当前 220 个文件继续使用：

```text
pathways/<pathway-id>/sequences/<sequence>/card.json
```

它们是旧式序列卡位。未来实际身份卡使用：

```text
pathways/<pathway-id>/sequences/<sequence>/cards/<card-slug>/card.json
pathways/<pathway-id>/sequences/<sequence>/cards/<card-slug>/narrative.json
```

旧式 `card.json` 中的 `card_id: lotm.fool.s09` 导入为 `slot_id`，不生成实际 `CardIdentity`；只有 `0.4.0` 记录中明确存在 `slot_id`、身份级 `card_id`、`character_id` 和 `identity_slice_id` 时，才生成实际卡牌。这样当前脚手架可以完整导入而不伪装成已确认卡牌。

### Normalized snapshot

App 内部统一为：

```swift
public struct LibrarySnapshot: Codable, Hashable, Sendable {
    public let snapshotID: String
    public let projectID: String
    public let sourceRootName: String
    public let sourceRevision: String?
    public let pathways: [PathwayNode]
    public let importedAt: Date
    public let warnings: [ImportWarning]
}

public struct SequenceNode: Codable, Hashable, Sendable {
    public let slotID: SlotID
    public let pathwayID: String
    public let sequence: Int
    public let cards: [CardIdentity]
    public let wishlistTarget: WishlistTarget
}

public struct CardIdentity: Identifiable, Codable, Hashable, Sendable {
    public let id: CardID
    public let slotID: SlotID
    public let characterID: CharacterID?
    public let identitySliceID: IdentitySliceID?
    public let variantID: VariantID?
    public let pathwayID: String
    public let sequence: Int
    public let nameZH: String?
    public let status: ContentStatus
    public let semanticStates: [SemanticDimension: KnowledgeState]
    public let visualAsset: ImportedAsset?
    public let narrative: NarrativePack?
    public let sourcePath: String
    public let contentHash: String
}

public struct PathwayNode: Codable, Hashable, Sendable {
    public let id: String
    public let nameZH: String
    public let sequences: [SequenceNode]
}

public extension LibrarySnapshot {
    var allSequences: [SequenceNode] { pathways.flatMap(\.sequences) }
    var allCards: [CardIdentity] { allSequences.flatMap(\.cards) }
    var confirmedCardCount: Int { allCards.filter { $0.status == .confirmed }.count }
}

Supporting types used by later tasks are defined in Core and not re-created by each module:

```swift
public enum WishlistTarget: Codable, Hashable, Sendable {
    case slot(SlotID)
    case character(CharacterID)
}

public struct NarrativeLine: Codable, Hashable, Sendable {
    public let id: String
    public let kind: NarrativeKind
    public let text: String
    public let contentStatus: NarrativeContentStatus
    public let sourceKind: NarrativeSourceKind
    public let claimRefs: [String]
    public let sourceRefs: [String]
}

public struct StoryChapter: Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let line: NarrativeLine
}

public struct NarrativePack: Codable, Hashable, Sendable {
    public let voiceProfileID: String
    public let voiceOverride: String?
    public let greeting: NarrativeLine?
    public let catchphrases: [NarrativeLine]
    public let stories: [StoryChapter]
    public var playableLines: [NarrativeLine] {
        let lines = [greeting].compactMap { $0 } + catchphrases + stories.map(\.line)
        return lines.filter { $0.contentStatus != .draft }
    }
}

public struct ImportReport: Codable, Hashable, Sendable {
    public let recordCount: Int
    public let identityCardCount: Int
    public let unfilledSlotCount: Int
    public let statusCounts: [ContentStatus: Int]
    public let warnings: [ImportWarning]
    public let invalidRecords: [String]
    public let copiedAssetCount: Int
}

public enum ImportFailure: Error, Equatable, Sendable {
    case invalidRoot(String)
    case invalidRecord(path: String, reason: String)
    case unsupportedSchema(String)
    case installFailed(String)
}
```

### Status mapping

`RepositoryImporter` 必须使用固定优先级，不按名称猜测：

1. 没有身份级 `card_id` 的旧卡位归为 `unfilled`，只作为 `SequenceNode.wishlistTarget`。
2. 有身份级 `card_id` 但 `name_status != verified`、生产阶段为 `scaffold/research` 或六维包含 `unresearched` 的记录归为 `unresearched`。
3. 有身份级 `card_id` 且有内容，但生产阶段尚未 `approved`、名称尚未全部核验或六维仍为 `partial` 的记录归为 `proposed`。
4. 只有身份级 `card_id`、`name_status == verified`、`production.stage == approved` 且六维均为 `supported`、`documented_absence` 或 `not_applicable` 的记录归为 `confirmed`。
5. `confirmed` 不能由存在图片、非空名称或 `card_id` 单独推导；导入器必须保留原始状态和警告。

### Stable public interfaces

```swift
public struct RepositoryImporter: Sendable {
    public init(fileSystem: any RepositoryFileSystem = LocalRepositoryFileSystem())
    public func importSnapshot(from root: URL) throws -> ImportResult
}

public struct ImportResult: Sendable {
    public let snapshot: LibrarySnapshot
    public let report: ImportReport
    public let copiedAssets: [ImportedAsset]
}

public protocol SpeechRailClient: Sendable {
    func health() async throws -> SpeechRailHealth
    func ready() async throws -> SpeechRailReadiness
    func voices() async throws -> [SpeechRailVoice]
    func synthesize(_ request: SpeechSynthesisRequest) async throws -> Data
}

public struct UserStoreSnapshot: Codable, Hashable, Sendable {
    public let entries: [CollectionEntry]
    public let wishlist: [WishlistEntry]
}

public enum UserStoreChange: Sendable {
    case replace(UserStoreSnapshot)
    case setCollection(cardID: CardID, kind: CollectionKind?)
    case setFavorite(cardID: CardID, value: Bool)
    case addWishlist(WishlistEntry)
    case mark(cardID: CardID, flag: ActivityFlag)
}

@MainActor
public protocol UserStore {
    func load() throws -> UserStoreSnapshot
    func save(_ change: UserStoreChange) throws
}
```

## Task 1: Extend the content contract without breaking the scaffold

**Files:**
- Modify: `schemas/card.schema.json`
- Create: `schemas/narrative.schema.json`
- Create: `schemas/library-manifest.schema.json`
- Modify: `tools/cardctl.py`
- Modify: `tests/test_cardctl.py`
- Modify: `docs/DECISIONS.md`

**Interfaces:**
- Consumes: 现有 `0.3.0` `card.json`、`config/project.json` 的 `expected_cards: 220`、`catalog/pathways.json` 和 `tools/cardctl.py` 的路径安全函数。
- Produces: 旧式卡位继续通过 `scaffold` 检查；未来身份卡有明确的 `slot_id` 与多角色字段；同序列多卡能被结构检查发现；叙事旁车文件有单独契约。

- [ ] **Step 1: Add the backward-compatible card ID fields**

在 `schemas/card.schema.json` 中把 `schema_version` 从单一 `const: 0.3.0` 扩展为只接受 `0.3.0` 和 `0.4.0`；保持旧字段和六维字段不变，增加 `slot_id`、`character_id`、`identity_slice_id`、`variant_id` 四个可选字段。`card_id` 接受旧式 `^lotm\\.[a-z-]+\\.s0[0-9]$` 或身份式 `^lotm\\.[a-z-]+\\.s0[0-9]\\.[a-z0-9][a-z0-9_-]*$`。`0.4.0` 记录必须非空提供前三个身份字段，不批量改写现有 220 个文件。

- [ ] **Step 2: Define the narrative sidecar schema**

新建 `schemas/narrative.schema.json`，要求 `schema_version: "1.0.0"`、`card_id`、`voice_profile_id`、`voice_override`、`greeting`、`catchphrases` 和 `stories`。每个条目必须包含 `id`、`kind`、`text`、`content_status`、`source_kind`、`claim_refs` 和 `source_refs`；`kind` 只允许 `greeting`、`catchphrase`、`story`，`content_status` 只允许 `canon`、`interpretation`、`original`、`draft`。故事文本必须作为第三人称档案文案保存。MVP 导入器拒绝 `draft` 进入可播放清单，但保留它们用于状态显示。

- [ ] **Step 3: Define the normalized manifest schema**

新建 `schemas/library-manifest.schema.json`，定义 `project_id`、`source_revision`、`pathways`、`sequences`、`cards` 和 `warnings`。`sequences[].cards` 允许空数组；`cards[].card_id` 必须唯一；`cards[].character_id` 可以重复；`cards[].status` 只允许 `unfilled`、`proposed`、`unresearched`、`confirmed`。该文件描述归一化结果，不改变当前仓库的 220 卡位基线。

- [ ] **Step 4: Add path iteration and identity validation**

在 `tools/cardctl.py` 增加并复用：

```python
def iter_card_paths(root: Path) -> list[Path]:
    legacy = sorted((root / 'pathways').glob('*/sequences/*/card.json'))
    identities = sorted((root / 'pathways').glob('*/sequences/*/cards/*/card.json'))
    return legacy + identities

def card_identity_kind(card: dict) -> str:
    if card.get('schema_version') == '0.3.0':
        return 'legacy_slot'
    if card.get('schema_version') == '0.4.0':
        return 'identity_card'
    raise DataError('不支持的卡牌 schema_version')
```

旧式记录的 `card_id` 必须等于目录推导的序列 ID；身份式记录必须有 `slot_id`，且 `card_id` 前缀与 `slot_id` 一致，`character_id` 和 `identity_slice_id` 非空；同一 `card_id` 在全仓库重复时返回非零错误。`check_repository()` 仍要求 220 个旧式路径全部存在，但允许额外身份卡只出现在 `cards/*/card.json`。

- [ ] **Step 5: Validate optional narrative sidecars safely**

增加 `validate_narrative(root, card_path, card, errors)`：仅检查卡牌旁的 `narrative.json`，使用 `safe_path()` 防止越界，核对 `card_id`、条目 ID 唯一性、内容状态和 `claim_refs`/`source_refs` 是否存在。没有旁车文件不是错误；有旁车但 JSON 非法或 ID 不匹配时返回稳定错误码；含 `draft` 条目时保留结构通过并追加不可播放 warning。不得读取或复制运行缓存、模型和原始音频。

- [ ] **Step 6: Add regression tests**

在 `tests/test_cardctl.py` 增加 synthetic fixture 测试：旧记录返回 `legacy_slot`；同一序列新增 `lotm.fool.s09.klein-clown` 和 `lotm.fool.s09.klein-seer` 后 `cards_checked == 222`；重复身份级 ID 返回 `card.id_duplicate`；身份卡缺少 `slot_id` 返回 `card.identity_fields`；旁车 `card_id` 不匹配返回 `narrative.card_mismatch`。fixture 明确写入“仅供软件测试，不代表原著事实”。

- [ ] **Step 7: Record the migration decision and verify**

在 `docs/DECISIONS.md` 记录旧 `card_id` 作为兼容 `slot_id`、身份卡必须使用身份级 ID、同一 `character_id` 可以有多个切片、`narrative.json` 不从角色名推导。运行：

```bash
python3 tools/cardctl.py check --level scaffold
python3 -m unittest discover -s tests -v
git diff --check
```

Expected：现有脚手架和测试全部通过；然后提交：

```bash
git add schemas/card.schema.json schemas/narrative.schema.json schemas/library-manifest.schema.json tools/cardctl.py tests/test_cardctl.py docs/DECISIONS.md
git commit -m "feat: extend card identity import contract"
```

## Task 2: Bootstrap the native Swift package and domain layer

**Files:**
- Create: `apps/LotmCardStudio/Package.swift`
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioCore/Domain/StableIDs.swift`
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioCore/Domain/ContentStatus.swift`
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioCore/Domain/CardModels.swift`
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioCore/Domain/NarrativeModels.swift`
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioFeatures/Bootstrap.swift`
- Create: `apps/LotmCardStudio/Sources/LotmCardStudio/main.swift`
- Create: `apps/LotmCardStudio/Tests/LotmCardStudioCoreTests/DomainTests.swift`
- Create: `apps/LotmCardStudio/Tests/LotmCardStudioCoreTests/FixtureLibrary.swift`

**Interfaces:**
- Consumes: Task 1 的 ID/状态契约、`config/project.json` 的六维名称和 `schemas/library-manifest.schema.json`。
- Produces: Core target 可被 UI、导入器、收藏和播放模块复用；所有 ID 和枚举可 `Codable`、`Hashable`、`Sendable`。

- [ ] **Step 1: Create the SwiftPM package with no external dependencies**

`Package.swift` 使用 Swift tools 6.0、`.macOS(.v14)`，提供 `LotmCardStudioCore`、`LotmCardStudioFeatures` library 和 `LotmCardStudio` executable；五个 target 分别为两个生产 target、一个 executable target 和两个 XCTest target。生产 target 路径固定为 `Sources/LotmCardStudioCore`、`Sources/LotmCardStudioFeatures`、`Sources/LotmCardStudio`。同时创建 `Bootstrap.swift` 和最小可编译的初始 `main.swift`，避免 SwiftPM 因 target 无源文件而无法构建；Task 9 将其替换为真实 Album 场景。`Bootstrap.swift` 只导出 `public enum LotmCardStudioFeaturesBootstrap {}`，初始 `main.swift` 只提供 `@main struct LotmCardStudioApp { static func main() {} }`。

- [ ] **Step 2: Implement throwing stable ID wrappers**

在 `StableIDs.swift` 定义 `SlotID`、`CardID`、`CharacterID`、`IdentitySliceID`、`VariantID`。每个类型提供：

```swift
public init(_ rawValue: String) throws
public var rawValue: String { get }
```

初始化拒绝空白、路径分隔符、`..` 和控制字符；`Codable` 解码复用同一校验。ID 类型不能自动从角色展示名生成。

- [ ] **Step 3: Implement enums and normalized structs**

`ContentStatus` 固定为 `.unfilled`、`.proposed`、`.unresearched`、`.confirmed`；`KnowledgeState` 与仓库五种状态一一对应；`SemanticDimension` 使用 `identity`、`acting`、`abilities`、`potion`、`ascension`、`limitations`。实现 `PathwayNode`、`SequenceNode`、`CardIdentity`、`ImportedAsset`、`ImportWarning`、`LibrarySnapshot`、`NarrativeLine`、`StoryChapter` 和 `NarrativePack`。`SequenceNode.cards` 允许为空，`NarrativePack.playableLines` 过滤 `draft`。

- [ ] **Step 4: Add domain tests**

```swift
func testStableIDRejectsTraversal() {
    XCTAssertThrowsError(try CardID("../card"))
    XCTAssertThrowsError(try SlotID(""))
}

func testSameCharacterHasSeparateCardIDs() throws {
    let cards = FixtureLibrary.makeCards(characterID: try CharacterID("klein"), ids: ["klein-clown", "klein-seer"])
    XCTAssertEqual(Set(cards.compactMap(\.characterID)), Set([try CharacterID("klein")]))
    XCTAssertEqual(Set(cards.map(\.id)).count, 2)
}

func testConfirmedCountIsDynamic() {
    let snapshot = FixtureLibrary.make(statuses: [.confirmed, .proposed, .unfilled])
    XCTAssertEqual(snapshot.confirmedCardCount, 1)
}
```

运行：`swift test --package-path apps/LotmCardStudio --filter LotmCardStudioCoreTests.DomainTests`。初次实现前应失败；实现后全部通过。

- [ ] **Step 5: Build and commit**

```bash
swift build --package-path apps/LotmCardStudio
swift test --package-path apps/LotmCardStudio
git add apps/LotmCardStudio/Package.swift apps/LotmCardStudio/Sources/LotmCardStudioCore/Domain apps/LotmCardStudio/Sources/LotmCardStudioFeatures/Bootstrap.swift apps/LotmCardStudio/Sources/LotmCardStudio/main.swift apps/LotmCardStudio/Tests/LotmCardStudioCoreTests/DomainTests.swift apps/LotmCardStudio/Tests/LotmCardStudioCoreTests/FixtureLibrary.swift
git commit -m "feat: add LotmCardStudio Swift package core"
```

## Task 3: Import repository snapshots and reconcile content updates

**Files:**
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioCore/Import/RawRepositoryModels.swift`
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioCore/Import/RepositoryFileSystem.swift`
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioCore/Import/ContentHashing.swift`
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioCore/Import/RepositoryImporter.swift`
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioCore/Import/SnapshotStore.swift`
- Create: `apps/LotmCardStudio/Tests/LotmCardStudioCoreTests/ImportTests.swift`
- Create: `apps/LotmCardStudio/Tests/LotmCardStudioCoreTests/Fixtures/RepositoryFixture.swift`

**Interfaces:**
- Consumes: Task 1 的仓库布局和 Task 2 的领域类型；现有 `catalog/pathways.json`、`config/project.json`、`sources/registry.json`、`references/manifest.json`、各途径 `direction.json`/`canon.json` 与卡牌 JSON。
- Produces: `RepositoryImporter.importSnapshot(from:)` 返回完整 `ImportResult`；快照替换失败时活动快照仍不变；路径、结构和状态警告可供 UI 展示。

- [ ] **Step 1: Implement strict raw decoders**

在 `RawRepositoryModels.swift` 逐字段解码当前 `card.json` 的顶层字段、`semantics` 六维、`composition`、`production` 和可选身份字段；不要使用 `[String: Any]` 逃避类型校验。未知字段允许被忽略以保持前向兼容，但缺少现有必需字段、类型不对或重复 JSON key 必须形成 `ImportFailure.invalidRecord(path:reason:)`。
`ImportTests.setUp()` 必须创建临时 root、`RepositoryFixtureFileSystem`、`RepositoryImporter(fileSystem:)` 和内存 `SnapshotStore`，每个测试结束删除临时目录；测试 fixture 提供 `addIdentityCard`、`setArtifactPath`、`makeInstalledSnapshot` 和 `importResult` 四个明确 helper。

`narrative.json` 使用独立的 `RawNarrativePack`，旁车 `card_id` 必须与身份卡一致；旧卡位旁车不能被当作身份卡。

- [ ] **Step 2: Implement a root-scoped file system**

`RepositoryFileSystem` 至少提供：

```swift
public protocol RepositoryFileSystem: Sendable {
    func read(relativePath: String, under root: URL) throws -> Data
    func list(relativeDirectory: String, under root: URL) throws -> [String]
    func isFile(relativePath: String, under root: URL) -> Bool
}
```

`LocalRepositoryFileSystem` 只接受相对路径；拒绝绝对路径、`..`、符号链接解析后越出 root 的路径和 App 不允许的敏感目录。`RepositoryFixtureFileSystem` 在测试中返回内存 Data，确保导入器不依赖真实用户目录。

- [ ] **Step 3: Implement deterministic content hashing**

使用 `CryptoKit.SHA256` 计算：

```swift
public enum ContentHasher {
    public static func sha256(_ data: Data) -> String
    public static func snapshotID(records: [CardIdentity], narratives: [NarrativePack]) -> String
    public static func audioCacheKey(cardID: CardID, contentID: String, textHash: String, voiceID: String, model: String, format: String, speed: Double) -> String
}
```

快照 ID 的输入按相对路径排序后拼接规范化 JSON；不包含 `importedAt`、用户收藏或本机路径。音频缓存键必须包含 `card_id`、内容 ID、文本哈希、实际 voice ID、模型、输出格式和速度。

- [ ] **Step 4: Implement the importer and fixed status mapping**

`RepositoryImporter` 校验 root markers 后按 `catalog/pathways.json.production_order` 读取途径，按序列读取旧卡位和 `cards/*/card.json`。对每条结构合法记录：

1. 计算 `slotID`；旧记录取旧 `card_id`，身份记录取显式 `slot_id`。
2. 只有身份记录创建 `CardIdentity`；旧卡位进入对应 `SequenceNode` 的愿望目标。
3. 按计划中的五条固定状态规则归类。
4. 只复制 `production.artifact.path` 指向的允许图片，并验证记录中的 SHA-256；跳过 `generated/`、`.env`、模型、日志和运行缓存。
5. 读取可选 `narrative.json`，将 `draft` 条目保留为不可播放审阅数据。
6. 把每个结构错误加入 `ImportReport.invalidRecords`；若根结构、项目身份或所有快照记录无法解析，抛出失败并不创建活动快照。

`ImportReport` 至少包含 `recordCount`、`identityCardCount`、`unfilledSlotCount`、四种状态计数、`warnings`、`invalidRecords` 和 `copiedAssetCount`。

- [ ] **Step 5: Implement atomic snapshot storage**

`SnapshotStore` 将新快照写入 `Application Support/LotmCardStudio/libraries/<library-id>/snapshots/<snapshot-id>.staging`，写完 `manifest.json` 和资产后再原子移动为正式目录，并最后更新 `active-snapshot.json`。任何写入、哈希或移动失败都删除 staging 目录并继续返回旧活动快照。

接口如下：

```swift
public protocol SnapshotStore: Sendable {
    func activeSnapshot(libraryID: String) throws -> LibrarySnapshot?
    func install(_ result: ImportResult, libraryID: String) throws
}
```

不将用户收藏写入 snapshot 目录；不把 App Support 绝对路径写入公开日志或内容 JSON。

- [ ] **Step 6: Test legacy slots, multi-card sequences, and bad paths**

```swift
func testLegacyRepositoryImports220SlotsAsUnfilledTargets() throws {
    let result = try importer.importSnapshot(from: fixture.rootURL)
    XCTAssertEqual(result.report.unfilledSlotCount, 220)
    XCTAssertEqual(result.snapshot.allCards.count, 0)
    XCTAssertEqual(result.snapshot.allSequences.count, 220)
}

func testTwoCardsShareCharacterButRemainSeparate() throws {
    fixture.addIdentityCard(id: "lotm.fool.s09.klein-clown", character: "klein", slice: "klein-clown")
    fixture.addIdentityCard(id: "lotm.fool.s09.klein-seer", character: "klein", slice: "klein-seer")
    let snapshot = try importer.importSnapshot(from: fixture.rootURL).snapshot
    let cards = snapshot.allCards.filter { $0.sequence == 9 }
    XCTAssertEqual(cards.count, 2)
    XCTAssertEqual(Set(cards.compactMap(\.characterID)), Set([try CharacterID("klein")]))
    XCTAssertEqual(Set(cards.map(\.id)).count, 2)
}

func testImportRejectsArtifactOutsideRepository() throws {
    fixture.setArtifactPath("../../private.wav")
    XCTAssertThrowsError(try importer.importSnapshot(from: fixture.rootURL))
}

func testFailedInstallLeavesPreviousSnapshotActive() throws {
    let old = try fixture.makeInstalledSnapshot("old")
    fixture.failNextMove = true
    XCTAssertThrowsError(try store.install(fixture.importResult("new"), libraryID: "lotm-card-art"))
    XCTAssertEqual(try store.activeSnapshot(libraryID: "lotm-card-art")?.snapshotID, old.snapshotID)
}
```

- [ ] **Step 7: Run tests and commit**

运行：

```bash
swift test --package-path apps/LotmCardStudio --filter LotmCardStudioCoreTests.ImportTests
python3 tools/cardctl.py check --level scaffold
git diff --check
```

然后提交：

```bash
git add apps/LotmCardStudio/Sources/LotmCardStudioCore/Import apps/LotmCardStudio/Tests/LotmCardStudioCoreTests/ImportTests.swift apps/LotmCardStudio/Tests/LotmCardStudioCoreTests/Fixtures/RepositoryFixture.swift
git commit -m "feat: import repository content snapshots"
```

## Task 4: Persist collections and preserve user data across snapshots

**Files:**
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioCore/Collection/CollectionModels.swift`
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioCore/Collection/CollectionReconciler.swift`
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioCore/Collection/CollectionService.swift`
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioCore/Persistence/UserStore.swift`
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioCore/Persistence/SwiftDataUserStore.swift`
- Create: `apps/LotmCardStudio/Tests/LotmCardStudioCoreTests/CollectionTests.swift`

**Interfaces:**
- Consumes: `LibrarySnapshot`、`ContentStatus`、`SlotID`/`CardID` 和 Task 3 的快照替换结果。
- Produces: 用户数据与内容快照分离；正式/候选收藏和愿望清单有独立存储；按 `card_id` 对账并保留移除记录。

- [ ] **Step 1: Define collection and activity types**

在 `CollectionModels.swift` 定义：

```swift
public enum CollectionKind: String, Codable, Sendable { case formal, candidate }
public enum ActivityFlag: String, Codable, Sendable { case discovered, awakened, storyHeard }
public struct CollectionEntry: Codable, Hashable, Sendable {
    public let cardID: CardID
    public var kind: CollectionKind?
    public var isFavorite: Bool
    public var tags: [String]
    public var note: String
    public var activity: Set<ActivityFlag>
    public var sourceRemoved: Bool
}
public struct WishlistEntry: Codable, Hashable, Sendable {
    public let target: WishlistTarget
    public var note: String
}
```

`WishlistTarget` 只允许 `slot(SlotID)` 或 `character(CharacterID)`；正式收藏和候选收藏只能引用 `CardID`。

- [ ] **Step 2: Add the pure reconciliation function**

在 `CollectionReconciler.swift` 实现：

```swift
public enum CollectionReconciler {
    public static func reconcile(
        oldSnapshot: LibrarySnapshot?,
        newSnapshot: LibrarySnapshot,
        user: UserStoreSnapshot
    ) -> ReconciledUserData
}
```

补充定义 `ReconciledUserData` 为 `entries: [CollectionEntry]`、`wishlist: [WishlistEntry]`、`orphanedCardIDs: [CardID]` 的 `Codable/Hashable/Sendable` 值类型；`UserStoreError` 固定包含 `formalRequiresConfirmed`、`candidateRequiresActualCard`、`persistenceFailed(String)` 三个分支。

规则固定为：相同 `card_id` 保留全部收藏、笔记、标签和活动状态；新增卡牌没有收藏状态；新快照移除的卡牌保留 `CollectionEntry` 并设置 `sourceRemoved = true`；`slot_id` 愿望目标只要序列仍存在就保留；名称相似、角色名相同或序列相同都不能自动迁移。

- [ ] **Step 3: Implement SwiftData entities and local store**

使用 `@Model` 创建 `CollectionEntryEntity` 和 `WishlistEntryEntity`，以 `cardID`/`targetID` 设置唯一约束。数据库位置为 `FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]/LotmCardStudio/UserStore.store`。初始化 `ModelContainer` 时使用 `ModelConfiguration(isStoredInMemoryOnly: false)`；单元测试使用内存配置。

`SwiftDataUserStore` 实现 `@MainActor UserStore` 的 `load()` 和 `save(_:)`，每次变更后调用 `ModelContext.save()`；保存失败返回 `UserStoreError.persistenceFailed`，不得吞掉异常。

- [ ] **Step 4: Enforce formal/candidate/wishlist rules at the service boundary**

增加 `CollectionService`：

```swift
@MainActor
public struct CollectionService {
    public init(store: any UserStore)
    public func setCollection(_ kind: CollectionKind?, for card: CardIdentity) throws
    public func addWishlist(_ target: WishlistTarget, note: String) throws
    public func mark(_ flag: ActivityFlag, for cardID: CardID) throws
}
```

`setCollection(.formal, for: card)` 只接受 `card.status == .confirmed`；`setCollection(.candidate, for: card)` 只接受 `proposed` 或 `unresearched`；`unfilled` 不接受收藏，只能进入愿望清单。`isFavorite` 可以独立于 `kind` 保存。
`CollectionTests.setUp()` 使用 `InMemoryUserStore` 创建 `CollectionService(store:)`；该测试实现只存在于测试 target，不触碰 App Support 数据库。

- [ ] **Step 5: Test preservation and counters**

```swift
func testSameCardIDPreservesNotesAndActivity() throws {
    let old = FixtureLibrary.snapshot(cardID: "lotm.fool.s09.klein-clown")
    let user = UserStoreSnapshot(entry: .fixture(note: "我的记录", activity: [.awakened]))
    let reconciled = CollectionReconciler.reconcile(oldSnapshot: old, newSnapshot: old, user: user)
    XCTAssertEqual(reconciled.entries[0].note, "我的记录")
    XCTAssertTrue(reconciled.entries[0].activity.contains(.awakened))
}

func testRemovedCardBecomesSourceRemoved() throws {
    let old = FixtureLibrary.snapshot(cardID: "lotm.fool.s09.klein-clown")
    let new = FixtureLibrary.snapshot(cardID: "lotm.fool.s09.klein-seer")
    let reconciled = CollectionReconciler.reconcile(oldSnapshot: old, newSnapshot: new, user: .fixtureFor(old))
    XCTAssertTrue(reconciled.entries[0].sourceRemoved)
}

func testFormalCollectionRejectsCandidate() throws {
    let card = FixtureLibrary.card(status: .proposed)
    XCTAssertThrowsError(try service.setCollection(.formal, for: card))
}

func testUnfilledSlotCanOnlyEnterWishlist() throws {
    let target = WishlistTarget.slot(try SlotID("lotm.fool.s08"))
    try service.addWishlist(target, note: "等待身份卡")
    XCTAssertThrowsError(try service.setCollection(.candidate, for: FixtureLibrary.unfilledCard()))
}
```

- [ ] **Step 6: Run tests and commit**

运行：`swift test --package-path apps/LotmCardStudio --filter LotmCardStudioCoreTests.CollectionTests`，确认内存测试不创建用户目录；然后提交：

```bash
git add apps/LotmCardStudio/Sources/LotmCardStudioCore/Collection apps/LotmCardStudio/Sources/LotmCardStudioCore/Persistence apps/LotmCardStudio/Tests/LotmCardStudioCoreTests/CollectionTests.swift
git commit -m "feat: persist collection state"
```

## Task 5: Integrate SpeechRail HTTP and cache synthesized audio

**Files:**
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioCore/SpeechRail/SpeechRailTypes.swift`
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioCore/SpeechRail/SpeechRailClient.swift`
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioCore/SpeechRail/AudioCache.swift`
- Create: `apps/LotmCardStudio/Tests/LotmCardStudioCoreTests/SpeechRailClientTests.swift`
- Create: `apps/LotmCardStudio/Tests/LotmCardStudioCoreTests/AudioCacheTests.swift`

**Interfaces:**
- Consumes: `NarrativePack.voiceProfileID`/`voiceOverride`、SpeechRail `contracts/openapi.yaml` 和 `docs/users/api-contract.md`。
- Produces: 可替换的 `SpeechRailClient`、稳定 App 错误码和可验证的本地 MP3 缓存；真实服务不可用时不影响文字阅读。

- [ ] **Step 1: Define the client configuration and wire contract**

在 `SpeechRailTypes.swift` 定义默认配置和请求模型：

```swift
public struct SpeechRailConfiguration: Sendable {
    public var baseURL: URL = URL(string: "http://127.0.0.1:8201")!
    public var model: String = "speechrail/qwen3-tts"
    public var responseFormat: String = "mp3"
    public var timeout: Duration = .seconds(20)
}

public struct SpeechSynthesisRequest: Codable, Sendable {
    public let input: String
    public let voice: String
    public let speed: Double
    public let language: String
}
```

请求必须发送到 `POST /v1/audio/speech`，JSON 为 `model`、`input`、`voice`、`response_format: "mp3"`、`speed` 和 `language`；MVP 不发送 `instructions`、`seed` 或克隆参数。合成前通过 `GET /v1/voices` 验证 `available == true`；应用不把 `quality/balanced/light` 拼入 voice ID。

- [ ] **Step 2: Implement the actor client and stable error mapping**

实现 `URLSessionSpeechRailClient: SpeechRailClient` actor。`health()` 调 `/health`，`ready()` 调 `/readyz`，`voices()` 调 `/v1/voices`，`synthesize()` 调 `/v1/audio/speech`。验证 HTTP status、Content-Type 和非空 Data；读取 SpeechRail error envelope 的 `code`，映射为：

```swift
public enum SpeechRailError: Error, Equatable, Sendable {
    case unavailable
    case notReady
    case voiceUnavailable
    case synthesisFailed
    case audioDecodeFailed
    case requestTimeout
    case invalidResponse
}
```

补充定义 `SpeechRailHealth`、`SpeechRailReadiness` 和 `SpeechRailVoice` 的 `Codable/Sendable` 字段：健康状态保留原始 `tts_ready`/`tts_warm`/`tts_state`，ready 状态保留 HTTP 就绪布尔值，音色保留 `id`、`available` 和 `capabilities.supports_instruction`。`AudioCacheMetadata` 为 `Codable/Sendable` 值类型，包含 `key`、`contentHash`、`voiceID`、`model`、`format`、`createdAt` 和 `audioSHA256`；缓存损坏使用独立的 `AudioCacheError.cacheCorrupt`。

`voice_not_available` 映射 `.voiceUnavailable`，`backend_timeout` 映射 `.requestTimeout`，连接拒绝/非 JSON 响应映射 `.unavailable` 或 `.invalidResponse`。客户端不重试超过一次，且不在失败时修改卡牌内容状态。

- [ ] **Step 3: Implement atomic audio caching**

`AudioCache` 使用 `Application Support/LotmCardStudio/AudioCache`，每个缓存条目为 `<cache-key>.mp3` 和 `<cache-key>.json`。元数据至少记录 cache key、content hash、voice ID、model、format、createdAt 和 audio SHA-256。写入使用临时文件后移动；读取时验证文件存在、哈希匹配和 MP3 非空，不匹配则抛 `.cacheCorrupt` 并删除该条目的临时副本。

```swift
public protocol AudioCache: Sendable {
    func data(for key: String) throws -> Data?
    func insert(_ data: Data, metadata: AudioCacheMetadata, for key: String) throws
}
```

- [ ] **Step 4: Test HTTP requests with `URLProtocol`**

```swift
func testSynthesizeUsesSpeechRailContract() async throws {
    let client = makeClient { request in
        XCTAssertEqual(request.url?.path, "/v1/audio/speech")
        XCTAssertEqual(request.httpMethod, "POST")
        let body = try XCTUnwrap(request.httpBody).jsonObject()
        XCTAssertEqual(body["model"] as? String, "speechrail/qwen3-tts")
        XCTAssertEqual(body["voice"] as? String, "serena")
        XCTAssertEqual(body["response_format"] as? String, "mp3")
        return .audio(Data("mp3-fixture".utf8), status: 200)
    }
    let data = try await client.synthesize(.init(input: "欢迎。", voice: "serena", speed: 1, language: "zh"))
    XCTAssertFalse(data.isEmpty)
}

func testVoiceUnavailableMapsToStableError() async {
    let client = makeClient { _ in .json(["error": ["code": "voice_not_available"]], status: 400) }
    do {
        _ = try await client.synthesize(.init(input: "x", voice: "missing", speed: 1, language: "zh"))
        XCTFail("expected voiceUnavailable")
    } catch {
        XCTAssertEqual(error as? SpeechRailError, .voiceUnavailable)
    }
}
```

再测试 `/health`/`/readyz` 连接失败、服务返回 503、超时和空音频；测试不得访问真实模型或读取任何 API key。
`SpeechRailClientTests` 提供 `makeClient(handler:)`，用自定义 `URLProtocol` 返回状态码、headers 和 Data；`PlaybackCoordinatorTests` 不共享该网络 fixture，所有 fake 依赖在测试文件中显式注入。

- [ ] **Step 5: Test cache key invalidation**

验证文本哈希、voice override、模型、格式和速度任意一项变化都会产生不同 key；相同 key 可以命中缓存；文件被截断或哈希不符时返回 `.cacheCorrupt`。缓存测试使用临时目录，结束时删除临时目录。

- [ ] **Step 6: Run tests and commit**

运行：`swift test --package-path apps/LotmCardStudio --filter SpeechRail`。然后提交：

```bash
git add apps/LotmCardStudio/Sources/LotmCardStudioCore/SpeechRail apps/LotmCardStudio/Tests/LotmCardStudioCoreTests/SpeechRailClientTests.swift apps/LotmCardStudio/Tests/LotmCardStudioCoreTests/AudioCacheTests.swift
git commit -m "feat: integrate SpeechRail audio synthesis"
```

## Task 6: Coordinate single-focus playback and explicit wake-up

**Files:**
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioCore/Playback/AudioPlayer.swift`
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioCore/Playback/PlaybackCoordinator.swift`
- Create: `apps/LotmCardStudio/Tests/LotmCardStudioCoreTests/PlaybackCoordinatorTests.swift`

**Interfaces:**
- Consumes: Task 4 的 `CollectionService`、Task 5 的 SpeechRail client/cache、`NarrativePack` 和 `CardIdentity`。
- Produces: `PlaybackCoordinator` 的状态机；默认不播放；任一时刻只有一个卡牌占用播放焦点；故事失败时文字稿仍然可读。

- [ ] **Step 1: Define the player abstraction and states**

```swift
public protocol AudioPlayer: AnyObject {
    var isPlaying: Bool { get }
    var currentTime: TimeInterval { get }
    var duration: TimeInterval { get }
    var onFinish: (() -> Void)? { get set }
    func load(data: Data) throws
    func play()
    func pause()
    func stop()
}

public enum PlaybackState: Equatable, Sendable {
    case idle
    case synthesizing(contentID: String)
    case playing(contentID: String)
    case paused(contentID: String)
    case noPlayableContent
    case failed(SpeechRailError)
}
```

`AVAudioPlayerAdapter` 只负责音频数据加载和播放控制；不读取麦克风、不创建 SpeechRail runtime。`FakeAudioPlayer` 记录 load/play/pause/stop 事件供测试使用。

- [ ] **Step 2: Implement the coordinator with cancellation generation**

实现 `@MainActor final class PlaybackCoordinator: ObservableObject`，并暴露 `@Published private(set) var state`、`private(set) var currentCardID` 和 `private(set) var progress`：

```swift
@Published public private(set) var state: PlaybackState = .idle
public private(set) var currentCardID: CardID?
public private(set) var progress: Double = 0

public func awaken(card: CardIdentity) async
public func playCatchphrase(_ line: NarrativeLine, for card: CardIdentity) async
public func playStory(_ chapter: StoryChapter, for card: CardIdentity) async
public func pause()
public func stop()
public func replay()
```

每次新请求先停止旧播放器、取消旧 Task、递增 generation token；旧 Task 完成时如果 token 不匹配，不得覆盖当前状态。生成优先查 `AudioCache`，未命中才调 SpeechRail；失败状态只显示错误码和重试入口，不写入 `awakened`/`storyHeard`。
`PlaybackHarness` 必须在测试 target 中组合 fake SpeechRail client、fake AudioCache、fake AudioPlayer、内存 UserStore 和真实的 `PlaybackCoordinator`；它公开 `card`、`cardA`、`cardB`、`chapter` 以及 fake 调用记录。

- [ ] **Step 3: Enforce narrative rules**

`awaken(card:)` 只选择 `greeting`；口头禅从 `playableLines` 中选择并保持第一人称原文；故事只接受 `NarrativeKind.story`，在 `StoryDrawerView` 展示第三人称文字稿。没有 `NarrativePack` 或所有条目均为 `draft` 时，协调器保持 `.idle` 并返回“暂无可播放内容”，不发空请求。

- [ ] **Step 4: Write playback tests**

```swift
func testOpeningCardDoesNotRequestSpeech() async {
    let harness = PlaybackHarness()
    harness.openCard(FixtureLibrary.cardWithNarrative())
    XCTAssertEqual(harness.client.synthesisRequests.count, 0)
    XCTAssertEqual(harness.coordinator.state, .idle)
}

func testAwakenSynthesizesAndMarksActivityOnlyAfterPlaybackStarts() async throws {
    let harness = PlaybackHarness()
    await harness.coordinator.awaken(card: harness.card)
    XCTAssertEqual(harness.client.synthesisRequests.count, 1)
    XCTAssertTrue(harness.player.events.contains(.play))
    XCTAssertTrue(harness.user.activity(for: harness.card.id).contains(.awakened))
}

func testNewCardStopsPreviousPlayback() async {
    let harness = PlaybackHarness()
    await harness.coordinator.awaken(card: harness.cardA)
    await harness.coordinator.awaken(card: harness.cardB)
    XCTAssertEqual(harness.player.events.filter { $0 == .stop }.count, 1)
    XCTAssertEqual(harness.coordinator.currentCardID, harness.cardB.id)
}

func testSpeechRailFailureLeavesTranscriptAvailable() async {
    let harness = PlaybackHarness(clientError: .unavailable)
    await harness.coordinator.awaken(card: harness.card)
    XCTAssertEqual(harness.coordinator.state, .failed(.unavailable))
    XCTAssertFalse(harness.card.narrative!.playableLines.isEmpty)
}
```

- [ ] **Step 5: Run tests and commit**

运行：`swift test --package-path apps/LotmCardStudio --filter PlaybackCoordinatorTests`；然后提交：

```bash
git add apps/LotmCardStudio/Sources/LotmCardStudioCore/Playback apps/LotmCardStudio/Tests/LotmCardStudioCoreTests/PlaybackCoordinatorTests.swift
git commit -m "feat: coordinate card audio playback"
```

## Task 7: Build the Album shell, bookshelf, gallery, and collection views

**Files:**
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioFeatures/App/AppModel.swift`
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioFeatures/ViewModels/AlbumViewModel.swift`
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioFeatures/Views/AppShellView.swift`
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioFeatures/Views/LibraryHomeView.swift`
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioFeatures/Views/CardGalleryView.swift`
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioFeatures/Views/CardTileView.swift`
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioFeatures/Views/CollectionViews.swift`
- Create: `apps/LotmCardStudio/Tests/LotmCardStudioFeatureTests/AlbumViewModelTests.swift`

**Interfaces:**
- Consumes: `LibrarySnapshot`、`SnapshotStore`、`UserStore`、`CollectionService` 和 `PlaybackCoordinator`。
- Produces: 首页“书架与画廊”、动态完成度、导入入口、正式/候选/愿望清单导航；默认卡牌网格平铺，不因同 `character_id` 自动合并。

- [ ] **Step 1: Compose dependencies without global singletons**

`AppModel` 持有 `@Published var snapshot: LibrarySnapshot?`、`selectedCardID`、`importState`、`playbackState` 和 `appMode`，并提供 `static func live() -> AppModel`、`func requestImport()`、`func importRepository(from: URL) async`。依赖通过 `AppDependencies` 传入；生产组装使用真实文件系统/SwiftData/URLSession，Preview 和测试使用 fake。首次启动没有内容库时显示导入引导，不自动扫描任意目录。

- [ ] **Step 2: Implement dynamic home metrics**

`AlbumViewModel` 暴露 `confirmedCount`、`candidateCount`、`wishlistCount`、`pathwayCounts` 和 `filteredCards`。`confirmedCount` 只对 `snapshot.allCards` 过滤 `.confirmed`；代码中不得出现 `220` 作为分母或网格卡牌数量。
其初始化接口为 `init(snapshot: LibrarySnapshot?, user: UserStoreSnapshot, filters: AlbumFilters = .default)`；`AlbumFilters` 明确包含 pathway、sequence、status、collectionKind、characterID 和 searchText，所有筛选都在内存快照上执行。

```swift
public var confirmedCount: Int {
    snapshot?.allCards.filter { $0.status == .confirmed }.count ?? 0
}
```

- [ ] **Step 3: Implement bookshelf and gallery navigation**

`AppShellView` 使用 `NavigationSplitView`：左侧显示途径书架和 Album/收藏/愿望清单入口；中心显示首页或选中详情；工坊入口显示为不可编辑的后续工作区提示，不暴露写入 `card.json` 的控件。`LibraryHomeView` 中央区域按最近浏览、最近收藏和继续探索排列；`CardGalleryView` 支持途径、序列、状态、收藏类型、角色和文本搜索筛选。

- [ ] **Step 4: Render status honestly**

`CardTileView` 对 `unfilled` 显示“等待身份卡”、对 `unresearched` 显示“尚未研究”、对 `proposed` 显示“候选”、对 `confirmed` 显示“已确认”。无 `visualAsset` 时使用明确的缺图卡面，不把渐变或图标标成正式艺术成品；候选和愿望清单计数不并入正式收藏进度。

- [ ] **Step 5: Implement collection screens**

`CollectionViews.swift` 分成三个明确区域：正式收藏只显示 confirmed card、候选收藏显示 proposed/unresearched card、愿望清单显示空序列或角色目标。用户可以在卡牌详情中把候选卡标记为喜欢，但不能把它写入正式收藏；收藏操作失败时显示 `UserStoreError` 的用户可读文案。

- [ ] **Step 6: Test view-model counts and flat card behavior**

```swift
func testHomeUsesConfirmedCardsAsDenominator() {
    let model = AlbumViewModel(snapshot: FixtureLibrary.snapshot(statuses: [.confirmed, .proposed, .unfilled]))
    XCTAssertEqual(model.confirmedCount, 1)
    XCTAssertNotEqual(model.confirmedCount, 220)
}

func testTwoCardsWithSameCharacterRemainSeparateInGallery() {
    let model = AlbumViewModel(snapshot: FixtureLibrary.twoCardsSameCharacter())
    XCTAssertEqual(model.filteredCards.count, 2)
    XCTAssertEqual(Set(model.filteredCards.map(\.id)).count, 2)
}

func testUnfilledSequenceAppearsInWishlistNotFormalCollection() {
    let model = AlbumViewModel(snapshot: FixtureLibrary.emptySequence())
    XCTAssertTrue(model.wishlistTargets.contains(.slot(try! SlotID("lotm.fool.s08"))))
    XCTAssertTrue(model.formalCards.isEmpty)
}
```

- [ ] **Step 7: Run tests and commit**

运行：`swift test --package-path apps/LotmCardStudio --filter AlbumViewModelTests`；然后提交：

```bash
git add apps/LotmCardStudio/Sources/LotmCardStudioFeatures/App apps/LotmCardStudio/Sources/LotmCardStudioFeatures/ViewModels/AlbumViewModel.swift apps/LotmCardStudio/Sources/LotmCardStudioFeatures/Views/AppShellView.swift apps/LotmCardStudio/Sources/LotmCardStudioFeatures/Views/LibraryHomeView.swift apps/LotmCardStudio/Sources/LotmCardStudioFeatures/Views/CardGalleryView.swift apps/LotmCardStudio/Sources/LotmCardStudioFeatures/Views/CardTileView.swift apps/LotmCardStudio/Sources/LotmCardStudioFeatures/Views/CollectionViews.swift apps/LotmCardStudio/Tests/LotmCardStudioFeatureTests/AlbumViewModelTests.swift
git commit -m "feat: add album and collection UI"
```

## Task 8: Build the card detail page, voice panel, story drawer, and motion

**Files:**
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioFeatures/ViewModels/CardDetailViewModel.swift`
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioFeatures/Views/CardDetailView.swift`
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioFeatures/Views/CardFaceView.swift`
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioFeatures/Views/CharacterPanelView.swift`
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioFeatures/Views/StoryDrawerView.swift`
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioFeatures/Views/CharacterFamilyView.swift`
- Create: `apps/LotmCardStudio/Sources/LotmCardStudioFeatures/Views/Motion/CardMotion.swift`
- Create: `apps/LotmCardStudio/Tests/LotmCardStudioFeatureTests/CardDetailViewModelTests.swift`
- Create: `apps/LotmCardStudio/QA.md`

**Interfaces:**
- Consumes: `CardIdentity`、`NarrativePack`、`CollectionService` 和 `PlaybackCoordinator`。
- Produces: “秘史书页”三栏关系；右侧角色面板常驻；故事播放时底部抽屉展开；平铺卡牌和可选角色族谱共存；默认静默。

- [ ] **Step 1: Implement the detail view model**

`CardDetailViewModel` 负责六维状态列表、当前收藏类型、音色可用性、可播放台词、故事章节、`isStoryDrawerPresented` 和 `specialEvent`，并提供 `appear()`、`wake()`、`playCatchphrase(_:)`、`playStory(_:)`。它不在初始化或 `onAppear` 中调用 `PlaybackCoordinator`；只有这四个显式动作中的后三个触发播放。
初始化接口为 `init(card: CardIdentity, userStore: any UserStore, collectionService: CollectionService, playback: PlaybackCoordinator)`；`appear()` 只刷新本地派生状态，不产生网络请求或播放副作用。

- [ ] **Step 2: Implement the large card and everyday motion**

`CardFaceView` 保持 2:3 比例，优先展示真实导入资产；没有资产时显示状态明确的内容卡面。`CardMotion` 的默认状态只包含微光呼吸和灵性脉动；`plateReveal` 只在 `specialEvent == true` 时触发，并通过 `withAnimation` 或 `phaseAnimator` 限制在牌面显影，不作为打开详情的自动声音触发器。

- [ ] **Step 3: Implement the always-visible character panel**

`CharacterPanelView` 右侧固定显示身份、途径、序列、六维状态、内容状态、收藏动作、音色状态和“唤醒 / 口头禅 / 故事”按钮。按钮在没有可播放文本时禁用并显示原因；语音服务故障只禁用播放，不禁用文字稿、收藏和导航。

- [ ] **Step 4: Implement the story drawer and transcript-first fallback**

`StoryDrawerView` 从底部展开，展示章节标题、第三人称文字稿、来源状态、播放进度、暂停/停止/重播和错误重试。音频失败时抽屉仍保持打开；`NarrativeContentStatus` 用徽标区分 `canon`、`interpretation`、`original` 和 `draft`，`draft` 不显示播放按钮。

- [ ] **Step 5: Implement optional character family view**

`CharacterFamilyView` 按 `characterID` 聚合当前快照中的卡牌，按 pathway/sequence 排序，显示身份切片和收藏进度；默认详情和网格仍然是一卡一项。角色族谱不修改任何 `card_id` 或收藏记录。

- [ ] **Step 6: Add detail-state tests and manual QA cases**

```swift
func testDetailAppearDoesNotAwakenCard() async {
    let harness = DetailHarness()
    harness.viewModel.appear()
    XCTAssertEqual(harness.playback.awakenCalls, 0)
}

func testWakeUsesOverrideVoiceWhenPresent() async {
    let harness = DetailHarness(voiceOverride: "uncle_fu")
    await harness.viewModel.wake()
    XCTAssertEqual(harness.client.lastVoice, "uncle_fu")
}

func testStoryDrawerKeepsTranscriptWhenSpeechRailUnavailable() async {
    let harness = DetailHarness(clientError: .unavailable)
    await harness.viewModel.playStory(harness.chapter)
    XCTAssertTrue(harness.viewModel.isStoryDrawerPresented)
    XCTAssertFalse(harness.viewModel.transcript.isEmpty)
}
```

在 `QA.md` 记录：打开卡牌不会发声；点击唤醒才发起请求；连续点击另一张卡会停止上一张；右侧面板始终可见；故事抽屉从底部出现；同角色两张卡在网格分开、族谱合并；四种内容状态标签不混淆。

- [ ] **Step 7: Run tests and commit**

运行：`swift test --package-path apps/LotmCardStudio --filter CardDetailViewModelTests`；然后提交：

```bash
git add apps/LotmCardStudio/Sources/LotmCardStudioFeatures/ViewModels/CardDetailViewModel.swift apps/LotmCardStudio/Sources/LotmCardStudioFeatures/Views/CardDetailView.swift apps/LotmCardStudio/Sources/LotmCardStudioFeatures/Views/CardFaceView.swift apps/LotmCardStudio/Sources/LotmCardStudioFeatures/Views/CharacterPanelView.swift apps/LotmCardStudio/Sources/LotmCardStudioFeatures/Views/StoryDrawerView.swift apps/LotmCardStudio/Sources/LotmCardStudioFeatures/Views/CharacterFamilyView.swift apps/LotmCardStudio/Sources/LotmCardStudioFeatures/Views/Motion/CardMotion.swift apps/LotmCardStudio/Tests/LotmCardStudioFeatureTests/CardDetailViewModelTests.swift apps/LotmCardStudio/QA.md
git commit -m "feat: add card detail narrative UI"
```

## Task 9: Add App entry, local bundle scripts, documentation, and full acceptance

**Files:**
- Modify: `apps/LotmCardStudio/Sources/LotmCardStudio/main.swift`
- Create: `apps/LotmCardStudio/scripts/build-app.sh`
- Create: `apps/LotmCardStudio/scripts/test-app.sh`
- Create: `apps/LotmCardStudio/README.md`
- Modify: `README.md`
- Modify: `.gitignore`

**Interfaces:**
- Consumes: Tasks 1–8 的 Core、Features、导入和播放实现。
- Produces: 可在本机打开的 `.app` bundle、可复现的构建/测试入口、非技术用户可理解的导入与 SpeechRail 限制说明。

- [ ] **Step 1: Compose the SwiftUI App and macOS commands**

`main.swift` 使用 `WindowGroup("诡秘卡牌画册")`，窗口最小尺寸为 `1180×760`，提供“导入内容库…”菜单命令和 `⌘⇧I` 快捷键。`AppModel.live()` 只组装本地依赖；不在 `init` 中自动播放、自动上传或自动创建 SpeechRail 进程。

- [ ] **Step 2: Add the local `.app` build script**

`build-app.sh` 接受 `--configuration Debug|Release`，运行 `swift build --package-path apps/LotmCardStudio --product LotmCardStudio --configuration <configuration>`，再创建：

```text
dist/LotmCardStudio.app/Contents/
├── MacOS/LotmCardStudio
├── Resources/
└── Info.plist
```

`Info.plist` 至少包含 `CFBundleIdentifier=com.hrygo.LotmCardStudio`、`CFBundleName=LotmCardStudio`、`CFBundlePackageType=APPL`、`LSMinimumSystemVersion=14.0` 和 `NSHighResolutionCapable=true`。脚本不签名、不公证、不复制 SpeechRail 模型或 `.env`。

- [ ] **Step 3: Add the test script and ignore generated app output**

`test-app.sh` 依次运行 `swift test --package-path apps/LotmCardStudio`、`swift build --package-path apps/LotmCardStudio`、Debug bundle 构建和 `plutil -lint`。根 `.gitignore` 增加：

```gitignore
apps/LotmCardStudio/.build/
apps/LotmCardStudio/dist/
apps/LotmCardStudio/.test-tmp/
```

- [ ] **Step 4: Write user-facing App documentation**

`apps/LotmCardStudio/README.md` 说明：Xcode/Swift 版本和 macOS 14.0+ / `arm64` 目标；运行命令；选择本仓库后旧 220 卡位显示为未形成实际身份卡的愿望目标；候选收藏不等于正式收藏；SpeechRail 默认 `http://127.0.0.1:8201`，不可用时仍可浏览/收藏/读文字；音频与用户数据位置；当前不包含 AI 工坊、卡牌游戏、网页和同步。根 `README.md` 只增加 App 入口和 MVP 状态链接，不把 220 卡位写成 220 张完成卡牌。

- [ ] **Step 5: Run the complete acceptance matrix**

运行本地自动检查：

```bash
python3 tools/cardctl.py check --level scaffold
python3 -m unittest discover -s tests -v
swift test --package-path apps/LotmCardStudio
swift build --package-path apps/LotmCardStudio
apps/LotmCardStudio/scripts/build-app.sh --configuration Debug
plutil -lint apps/LotmCardStudio/dist/LotmCardStudio.app/Contents/Info.plist
git diff --check
```

SpeechRail 可用时只做受控本机验收：

```bash
curl --fail --silent http://127.0.0.1:8201/health
curl --fail --silent http://127.0.0.1:8201/readyz
curl --fail --silent http://127.0.0.1:8201/v1/voices
```

若任一服务检查失败，仍必须验收导入、浏览、收藏、愿望清单和文字稿；把播放结果记录为“服务不可用路径通过”，不把失败伪装成语音通过。

- [ ] **Step 6: Perform the vertical-slice manual acceptance**

使用一个途径、1–3 张实际身份卡或明确标记的演示记录，完成：选择仓库 → 导入报告 → 书架与画廊 → 打开详情 → 默认无声 → 点击唤醒 → 播放人工确认台词 → 展开故事抽屉 → 读文字稿 → 收藏/候选收藏/愿望清单 → 修改输入快照 → 重新导入 → 验证相同 `card_id` 的笔记和收藏保留。若当前没有已批准正典内容，演示数据必须标记 `proposed`/`original`，并在 QA 记录中明确不能证明原著正确性。

- [ ] **Step 7: Commit the delivery surface**

```bash
git add apps/LotmCardStudio/Sources/LotmCardStudio/main.swift apps/LotmCardStudio/scripts/build-app.sh apps/LotmCardStudio/scripts/test-app.sh apps/LotmCardStudio/README.md README.md .gitignore
git diff --cached --check
git commit -m "docs: document LotmCardStudio MVP"
```

## Verification and Handoff

实施者在最后一个任务后必须重新运行：

```bash
git status --short --branch
git log -10 --oneline
python3 tools/cardctl.py check --level scaffold
python3 -m unittest discover -s tests -v
swift test --package-path apps/LotmCardStudio
swift build --package-path apps/LotmCardStudio
git diff --check
```

完成条件是：

- 当前仓库 220 个旧卡位仍通过结构检查；
- 一个序列可以有 0、1 或多张身份卡，同 `character_id` 的卡在网格独立、在族谱聚合；
- 导入状态、正式收藏、候选收藏和愿望清单分离且计数正确；
- 新快照按 `card_id` 保留个人记录，移除卡牌留存为来源已移除；
- 打开卡牌不自动发声，唤醒后单焦点播放，SpeechRail 失败不阻塞阅读与收藏；
- App bundle 可以在目标 Mac 上启动；
- 没有把模型、音频、凭据、运行缓存或用户数据提交到仓库；
- QA 记录区分结构检查、自动化测试、SpeechRail 本机实测和人工视觉/听感验收。

不以“220 张完成卡牌”、AI 自动生成、游戏规则或网页同步作为本 MVP 的完成条件。

## Known Risks and Explicit Follow-ups

- 当前内容源缺少已批准卡面和完整叙事时，App 可以验证导入与状态展示，但不能宣称正典完成；垂直切片需要后续提供真实研究/批准记录。
- SwiftData 的 schema 迁移和 macOS 14/新系统兼容性需要在真实安装路径上验收；若本地数据库迁移失败，必须保留旧数据库并显示恢复提示。
- SpeechRail 的 `quality` VoiceDesign 目前不保证跨文本同一 speaker；MVP 应使用稳定 `voice_profile_id`，特殊身份才使用明确的 `voice_override`，不要在 App 内宣称声纹已通过身份稳定性验收。
- 首期只构建 `arm64`；发布 universal binary、签名、公证和网页版本属于单独计划。
