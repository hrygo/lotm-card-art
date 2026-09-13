# LotmCardStudio 语音凭据与 Touch ID 闭环实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** 让 LotmCardStudio 在不需要远程语音时不弹钥匙串密码，并为 SpeechRail API key 提供用户主动启用的 Touch ID 优先保护闭环。

**Architecture:** 在 LotmCardStudioCore Ports 层增加可注入的 Keychain backend 和凭据存储边界；SpeechRailHTTPClient 使用异步、延迟 API key provider；macOS Settings 负责用户主动迁移或录入受保护条目。旧的普通条目保留但不自动删除，受保护条目存在时不静默回退。

**Tech Stack:** macOS 26 Tahoe、Swift 6.2 language mode、SwiftUI/AppKit、Security、LocalAuthentication、AVFoundation、XCTest、Swift Package Manager。

**Spec:** docs/superpowers/specs/2026-09-13-lotm-keychain-touchid-design.md

> **执行阶段决策覆盖（2026-09-13）：** 用户明确选择仓库外 `SpeechRail.json` 配置文件，当前 App 的运行时 provider 和 Settings 已切换到配置文件；旧 Keychain/Touch ID 实现仅保留为隔离回归材料，不会被当前 App 调用。当前方案细节见 `docs/superpowers/specs/2026-09-13-lotm-speechrail-config-file-override.md`。

> 本文件的混合 Touch ID 任务清单是历史执行记录；后续执行以 `docs/superpowers/plans/2026-09-13-lotm-speechrail-config-file.md` 为准。

## Global Constraints

- 最低部署版本固定为 macOS 26.0，默认使用 Xcode 26 / Swift 6 / Apple silicon arm64。
- 只访问 SpeechRail loopback；不得加入云端、自动启动服务或读取 .env。
- API key、Mac 登录密码、钥匙串密码和生物识别数据不得进入日志、测试输出、UserDefaults、Info.plist 或仓库。
- 不自动删除、覆盖或重置既有 login 钥匙串条目。
- 本地 WAV 播放不读取 Keychain；远程合成才读取凭据。
- 受保护条目使用 kSecAttrAccessibleWhenUnlockedThisDeviceOnly 与 kSecAccessControlUserPresence。
- 受保护条目存在且认证取消/失败时，不自动回退到旧条目。
- 每个行为变更先写回归测试，再实现，再运行聚焦测试和完整测试。

---

### Task 1: 建立可测试的凭据与 Keychain 边界

**Files:**
- Create: apps/LotmCardStudio/Sources/LotmCardStudioCore/Ports/SpeechRailCredentialStore.swift
- Create: apps/LotmCardStudio/Tests/LotmCardStudioCoreTests/SpeechRailCredentialStoreTests.swift
- Modify: apps/LotmCardStudio/Package.swift only if the new Core source is not automatically included by the existing target

**Interfaces:**

- Produces:
  - KeychainProtection: Sendable enum with legacy and userPresence cases.
  - KeychainItemState: Equatable, Sendable enum with present, missing and inaccessible cases.
  - SpeechRailCredentialState: Equatable, Sendable enum with protected, legacy, missing and unavailable cases.
  - SpeechRailCredentialError: Equatable, Sendable error with missing, unavailable, authenticationCancelled, authenticationFailed, invalidData, writeFailed and verificationFailed cases.
  - KeychainAccessing: Sendable protocol:
    
        func itemState(service: String, account: String) -> KeychainItemState
        func read(service: String, account: String, protection: KeychainProtection) async throws -> Data
        func write(_ data: Data, service: String, account: String, protection: KeychainProtection) throws

  - SpeechRailCredentialStore: @unchecked Sendable class:
    
        static let legacyService = "com.lotm.cardstudio.speechrail"
        static let protectedService = "com.lotm.cardstudio.speechrail.touchid"
        static let account = "api-key"

        init(keychain: any KeychainAccessing = SystemKeychainAccess())
        func state() -> SpeechRailCredentialState
        func readPreferredAPIKey() async throws -> String
        func saveProtectedAPIKey(_ value: String) async throws
        func migrateLegacyToProtected() async throws

- The production SystemKeychainAccess implements Security and LocalAuthentication. Tests inject an in-memory fake and never touch the real user keychain.

- [x] Step 1: Write failing tests for the state machine and migration contract.

  Add an in-memory fake backend in SpeechRailCredentialStoreTests with independent legacy/protected Data slots and switches for read/write failures. Cover:

        func testStatePrefersProtectedItemOverLegacyItem()
        func testStateReportsLegacyWhenOnlyLegacyItemExists()
        func testStateReportsMissingWhenNoItemExists()
        func testReadPreferredDoesNotFallbackAfterProtectedAuthenticationFailure()
        func testSaveProtectedAPIKeyTrimsInputAndVerifiesProtectedRead()
        func testMigrationWritesProtectedItemBeforeVerificationAndKeepsLegacyItem()
        func testEmptyAPIKeyIsRejectedWithoutWriting()

  Expected first run: FAIL because the credential types and store do not exist.

- [x] Step 2: Run the focused test to confirm the failure.

  Run from apps/LotmCardStudio:

        swift test --filter SpeechRailCredentialStoreTests

  Expected: compile errors for the missing types or methods.

- [x] Step 3: Implement the domain state machine and fake-compatible store.

  Required behavior:

  - state checks protectedService first, then legacyService.
  - readPreferredAPIKey reads only the source selected by state.
  - a protected read error is returned directly; it never falls through to legacy.
  - saveProtectedAPIKey trims whitespace/newlines, rejects empty input, writes the protected service, then reads it back for verification.
  - migrateLegacyToProtected reads the legacy item, writes the protected item, reads the protected item for verification, and never deletes the legacy item.
  - API key decoding is UTF-8 and empty decoded values are invalidData.

- [x] Step 4: Implement SystemKeychainAccess.

  Required Security behavior:

  - itemState uses kSecReturnAttributes and kSecUseAuthenticationUI = kSecAuthenticationUISkip so Settings status never opens a password prompt.
  - read uses kSecReturnData and kSecMatchLimitOne.
  - userPresence reads create an LAContext with a user-facing reason and pass it using kSecUseAuthenticationContext.
  - protected writes use SecAccessControlCreateWithFlags with kSecAttrAccessibleWhenUnlockedThisDeviceOnly and .userPresence.
  - duplicate protected writes update only kSecValueData for the protected service.
  - map errSecItemNotFound, errSecUserCanceled, errSecAuthFailed and errSecInteractionNotAllowed to stable credential errors without returning OSStatus text or secret data.

- [x] Step 5: Run the focused tests to confirm they pass.

  Run:

        swift test --filter SpeechRailCredentialStoreTests

  Expected: all credential-store tests PASS.

- [ ] Step 6: Commit the atomic credential boundary change.

        git add apps/LotmCardStudio/Sources/LotmCardStudioCore/Ports/SpeechRailCredentialStore.swift apps/LotmCardStudio/Tests/LotmCardStudioCoreTests/SpeechRailCredentialStoreTests.swift apps/LotmCardStudio/Package.swift
        git commit -m "feat: add Touch ID protected SpeechRail credentials"

---

### Task 2: Add delayed API key resolution to SpeechRailHTTPClient

**Files:**
- Modify: apps/LotmCardStudio/Sources/LotmCardStudioCore/Ports/SpeechRailClient.swift
- Modify: apps/LotmCardStudio/Tests/LotmCardStudioCoreTests/SpeechRailClientTests.swift

**Interfaces:**

- Add:

        public typealias APIKeyProvider = @Sendable () async throws -> String?

  to SpeechRailHTTPClient.

- Extend the existing initializer without breaking fixed-key callers:

        public init(
            baseURL: URL,
            apiKey: String? = nil,
            apiKeyProvider: APIKeyProvider? = nil,
            session: URLSession? = nil
        ) throws

- Keep public makeSpeechRequest synchronous and fixed-key compatible.
- synthesize resolves the provider only immediately before creating the network request.
- A non-nil fixed apiKey takes precedence and does not call the provider.

- [x] Step 1: Write failing provider timing and request tests.

  Extend the existing SpeechRailURLProtocol fake with a configurable HTTP status and non-empty response data. Add an actor probe:

        actor ProviderProbe {
            private(set) var calls = 0

            func resolve() -> String? {
                calls += 1
                return "test-key"
            }

            func callCount() -> Int { calls }
        }

  Add:

        func testMakeSpeechRequestDoesNotResolveAsyncProvider() async throws
        func testSynthesizeResolvesAsyncProviderAtRequestTime() async throws
        func testFixedAPIKeyTakesPrecedenceOverAsyncProvider() async throws

  Expected first run: FAIL because the initializer has no provider parameter.

- [x] Step 2: Run the focused test to confirm the failure.

        swift test --filter SpeechRailClientTests

  Expected: compile errors for APIKeyProvider or the new initializer.

- [x] Step 3: Implement the minimal provider extension.

  Refactor request construction into a private overload:

        private func makeSpeechRequest(_ speech: SpeechRequest, apiKey: String?) throws -> URLRequest

  Keep the public method delegating to the fixed property. In synthesize:

        let resolvedAPIKey: String?
        if let apiKey {
            resolvedAPIKey = apiKey
        } else {
            resolvedAPIKey = try await apiKeyProvider?()
        }
        let request = try makeSpeechRequest(speech, apiKey: resolvedAPIKey)

  Preserve all existing loopback, redirect, input-length, speed, response and audio-data checks.

- [x] Step 4: Run the focused client tests.

        swift test --filter SpeechRailClientTests

  Expected: all client tests PASS.

- [ ] Step 5: Commit the client contract change.

        git add apps/LotmCardStudio/Sources/LotmCardStudioCore/Ports/SpeechRailClient.swift apps/LotmCardStudio/Tests/LotmCardStudioCoreTests/SpeechRailClientTests.swift
        git commit -m "feat: resolve SpeechRail credentials lazily"

---

### Task 3: Wire lazy credentials and actionable SpeechRail errors

**Files:**
- Modify: apps/LotmCardStudio/Sources/LotmCardStudioCore/Ports/SpeechRailConfiguration.swift
- Modify: apps/LotmCardStudio/Sources/LotmCardStudioFeatures/SpeechPlaybackCoordinator.swift
- Create: apps/LotmCardStudio/Tests/LotmCardStudioCoreTests/SpeechRailConfigurationTests.swift
- Modify: apps/LotmCardStudio/Tests/LotmCardStudioFeaturesTests/SpeechPlaybackCoordinatorTests.swift

**Interfaces:**

- SpeechRailConfiguration.makeClient() creates a client with an async provider that calls SpeechRailCredentialStore.shared.readPreferredAPIKey(). It must not call the store while makeClient() is executing.
- Keep apiKeyFromKeychain() as a legacy-only helper for existing callers, but do not use it in LotmCardStudioApp.
- Extend SpeechRailError only if needed for stable credential failures; otherwise let SpeechRailCredentialError pass to the coordinator and map it without exposing details.
- SpeechPlaybackCoordinator.message(for:) must map:
  - missing / unavailable → SpeechRail API key 缺失，请在设置中配置
  - authenticationCancelled → 未完成钥匙串认证，文字稿仍可阅读
  - authenticationFailed → 钥匙串认证失败，文字稿仍可阅读
  - HTTP 401 → SpeechRail API key 缺失或无效，请在设置中配置
  - HTTP 403 → SpeechRail API key 无权访问
  - HTTP 422 → SpeechRail 拒绝了当前语音请求，请检查 voice 或文本
  - HTTP 408 → SpeechRail 请求超时，文字稿仍可阅读
  - HTTP 500…599 → SpeechRail 服务暂时不可用，请稍后重试
  - other HTTP status → SpeechRail 请求失败（HTTP status）

- [x] Step 1: Write failing tests for lazy configuration and error messages.

  Add a test-only injectable store/provider seam or a pure error-message helper, then cover:

        func testMakeClientDoesNotReadKeychainDuringInitialization()
        func testCredentialErrorsRemainActionable()
        func testHTTP401IsReportedAsMissingOrInvalidAPIKey()
        func testHTTP422IsReportedAsRequestValidationFailure()

  Expected first run: FAIL until the lazy provider and mappings exist.

- [x] Step 2: Run the focused tests.

        swift test --filter SpeechRailConfigurationTests
        swift test --filter SpeechPlaybackCoordinatorTests

- [x] Step 3: Implement lazy configuration and mappings.

  SpeechRailConfiguration.makeClient() should only capture the Sendable credential store in the provider closure. Do not call readPreferredAPIKey() from App.body or makeClient().

  Update the existing message(for:) switch from the generic HTTP case to associated-status cases. Keep captions/currentText set before remote work and keep text visible for every error path.

- [x] Step 4: Run the focused tests again.

        swift test --filter SpeechRailConfigurationTests
        swift test --filter SpeechPlaybackCoordinatorTests

  Expected: all focused tests PASS.

- [ ] Step 5: Commit the lazy startup and error semantics change.

        git add apps/LotmCardStudio/Sources/LotmCardStudioCore/Ports/SpeechRailConfiguration.swift apps/LotmCardStudio/Sources/LotmCardStudioFeatures/SpeechPlaybackCoordinator.swift apps/LotmCardStudio/Tests/LotmCardStudioCoreTests/SpeechRailConfigurationTests.swift apps/LotmCardStudio/Tests/LotmCardStudioFeaturesTests/SpeechPlaybackCoordinatorTests.swift
        git commit -m "fix: defer SpeechRail keychain access and explain failures"

---

### Task 4: Add a native macOS Settings flow for Touch ID migration

**Files:**
- Create: apps/LotmCardStudio/Sources/LotmCardStudioFeatures/SpeechRailSettingsView.swift
- Create: apps/LotmCardStudio/Tests/LotmCardStudioFeaturesTests/SpeechRailSettingsViewModelTests.swift
- Modify: apps/LotmCardStudio/Sources/LotmCardStudio/LotmCardStudioApp.swift

**Interfaces:**

- Create @MainActor SpeechRailSettingsViewModel with:
  - @Published private(set) var state: SpeechRailCredentialState
  - @Published var apiKeyInput: String
  - @Published private(set) var isWorking: Bool
  - @Published private(set) var message: String?
  - init(store: SpeechRailCredentialStore)
  - func refresh()
  - func saveInput()
  - func migrateLegacy()

- SaveInput captures the SecureField text, clears apiKeyInput immediately, and then performs saveProtectedAPIKey asynchronously.
- MigrateLegacy performs migrateLegacyToProtected asynchronously.
- Both operations update state only after the operation returns and never include the key or password in message.
- The view contains:
  - credential status;
  - a SecureField;
  - “保存并启用 Touch ID” button;
  - “迁移现有钥匙串项” button when state is legacy;
  - a concise explanation that Touch ID is preferred and the system password remains the fallback;
  - an error/success message with no secret.
- Add a macOS Settings scene:

        Settings {
            SpeechRailSettingsView()
        }

- [x] Step 1: Write failing ViewModel tests using the fake KeychainAccessing backend.

  Cover:

        func testSavingInputClearsSecretImmediately()
        func testSavingInputRefreshesProtectedStateAfterVerification()
        func testMigrationKeepsLegacyAndReportsProtectedState()
        func testFailedMigrationLeavesStateLegacy()

  Expected first run: FAIL because the ViewModel and view do not exist.

- [x] Step 2: Run focused tests.

        swift test --filter SpeechRailSettingsViewModelTests

- [x] Step 3: Implement the ViewModel and view.

  Use Settings-friendly Form layout and no API key echo. Use Task { } from the @MainActor model, set isWorking before awaiting, and update state/message on MainActor after completion. Disable buttons while working or when SecureField is empty.

- [x] Step 4: Add the Settings scene to LotmCardStudioApp.

  Keep the existing WindowGroup unchanged except for the lazy client from Task 3. Settings must be a second scene, not a replacement for the main window.

- [x] Step 5: Run settings tests and build the app target.

        swift test --filter SpeechRailSettingsViewModelTests
        swift build

  Expected: focused tests PASS and the macOS 26 app target compiles.

- [ ] Step 6: Commit the Settings flow.

        git add apps/LotmCardStudio/Sources/LotmCardStudioFeatures/SpeechRailSettingsView.swift apps/LotmCardStudio/Tests/LotmCardStudioFeaturesTests/SpeechRailSettingsViewModelTests.swift apps/LotmCardStudio/Sources/LotmCardStudio/LotmCardStudioApp.swift
        git commit -m "feat: add Touch ID credential settings"

---

### Task 5: Correct voice readiness UI and document the user path

**Files:**
- Modify: apps/LotmCardStudio/Sources/LotmCardStudioFeatures/ArchiveRootView.swift
- Modify: apps/LotmCardStudio/docs/qa/m1-local-run.md
- Modify: apps/LotmCardStudio/README.md only if the Settings path is not documented there

**Interfaces:**

- Separate these three states in IdentityPanel:
  - approved greeting with an audioResourceName: “本地音频优先”;
  - approved greeting without a local resource: “需要 SpeechRail”;
  - no approved greeting: “待审批”.
- The “唤醒卡牌” help/accessibility text must describe local playback versus SpeechRail synthesis accurately.
- HTTP 401 must be visible as the actionable API key message from Task 3.
- Add an accessible Settings entry through the native app Settings menu or toolbar action; do not add an empty button.
- Keep story transcript readable when remote authentication or synthesis fails.

- [x] Step 1: Write a regression test or pure state assertion for the three voice readiness cases.

  Extend the existing feature test fixture or add a small pure helper in the feature module so tests assert that approved/local, approved/remote and draft states produce distinct labels. The test must not load a real audio file or keychain item.

- [x] Step 2: Run the focused feature tests and confirm the assertion fails before the UI state split.

        swift test --filter SpeechPlaybackCoordinatorTests
        swift test --filter ArchiveRootViewTests

- [x] Step 3: Implement the state split and accessible copy.

  Do not use hasPlayableGreeting as a proxy for local audio. Use the approved line’s audioResourceName separately from its approval state. Preserve the existing local-audio-first behavior in SpeechPlaybackCoordinator.

- [x] Step 4: Run the feature tests again.

        swift test --filter SpeechPlaybackCoordinatorTests
        swift test --filter ArchiveRootViewTests

- [x] Step 5: Update QA and README with the user path.

  Document:

  - normal launch does not access Keychain;
  - local WAV cards do not require SpeechRail credentials;
  - remote cards use Settings-configured credentials;
  - existing legacy item migration requires the user to complete one local authentication;
  - Touch ID is preferred for protected items and the system password is an intentional fallback;
  - no automatic keychain reset or deletion.

- [ ] Step 6: Commit the user-facing status and documentation change.

        git add apps/LotmCardStudio/Sources/LotmCardStudioFeatures/ArchiveRootView.swift apps/LotmCardStudio/docs/qa/m1-local-run.md apps/LotmCardStudio/README.md
        git commit -m "fix: clarify local and SpeechRail voice readiness"

---

### Task 6: Full verification and manual closed-loop acceptance

**Files:**
- Modify: apps/LotmCardStudio/docs/qa/m1-local-run.md
- Inspect only: all changed Swift files, Package.swift, Resources/Info.plist and build script

- [ ] Step 1: Run the complete Swift test suite.

        swift test

  Expected: every test passes with zero failures. Record the exact count.

- [ ] Step 2: Build both app configurations.

        ./scripts/build-app.sh debug
        ./scripts/build-app.sh release

  Expected: both exit 0 and produce .build/LotmCardStudio.app.

- [ ] Step 3: Verify the release artifact without reading secrets.

        plutil -p .build/LotmCardStudio.app/Contents/Info.plist
        file .build/LotmCardStudio.app/Contents/MacOS/LotmCardStudio
        otool -l .build/LotmCardStudio.app/Contents/MacOS/LotmCardStudio
        codesign --verify --deep --strict --verbose=2 .build/LotmCardStudio.app

  Confirm LSMinimumSystemVersion=26.0, arm64, LC_BUILD_VERSION minos 26.0, valid code signature, and no API key in bundle resources.

- [ ] Step 4: Install the verified app only after the release artifact passes.

  Copy the exact release bundle to /Applications/LotmCardStudio.app, then use native app inspection. Do not copy keychain data or any environment file.

- [ ] Step 5: Perform the UI closed loop with CUA and fresh AX state after each action.

  Verify:

  1. Launch: no Keychain password dialog.
  2. S00/Audrey local playback: works without Touch ID or SpeechRail.
  3. Open Settings: state is legacy/protected/missing without a startup password prompt.
  4. If migrating or saving, stop before credential entry and let the user personally enter any Mac/keychain password, API key or Touch ID.
  5. After user completes the local authentication, return to the app and verify state is protected.
  6. Open a remote card: Touch ID/system authentication is requested only at remote synthesis.
  7. Cancel authentication: transcript stays visible, no legacy fallback prompt appears.
  8. Invalid key / HTTP 401: UI says the key is missing or invalid and offers Settings.
  9. Stop/replay and SpeechRail failure preserve transcript and leave no stuck loading state.

- [ ] Step 6: Run formatting and repository checks.

        git diff --check
        git status --short

  Ensure no generated .build output, secret, password, API key, or unrelated worktree change is staged.

- [ ] Step 7: Complete the QA record and code review.

  Record exact command outputs and manual coverage in apps/LotmCardStudio/docs/qa/m1-local-run.md. Mark Touch ID as manually verified only if the user completes the system prompt; otherwise record the exact remaining user action.

- [ ] Step 8: Do not commit unrelated pre-existing worktree changes.

  Before any commit, inspect git diff --staged and only stage the files listed by the task. Existing repository changes remain untouched unless explicitly part of this plan.
