---
title: "LotmCardStudio 语音凭据与 Touch ID 闭环设计"
status: superseded
version: "0.1.1"
date: 2026-09-13
audience: "macOS 客户端、语音服务与安全审查实现者"
---

# LotmCardStudio 语音凭据与 Touch ID 闭环设计

本设计记录了用户先前批准的混合方案：修复启动时不必要的钥匙串弹窗，
让远程语音失败可诊断，并为 SpeechRail API key 增加用户主动启用的
Touch ID 保护路径。执行阶段用户明确改为仓库外配置文件方案；本文件因此仅保留为历史设计与根因记录，当前运行时以
[`2026-09-13-lotm-speechrail-config-file-override.md`](2026-09-13-lotm-speechrail-config-file-override.md)
为准。本文件不包含真实密钥。

## 1. 当前实测与根因

2026-09-13 在当前 macOS 26.6.2 主机上完成以下只读排查：

- Touch ID 已录入 1 个生物识别模板，且系统允许用于解锁；
- com.lotm.cardstudio.speechrail / api-key 存在于当前用户的 login.keychain-db；
- 该条目为普通 genp，属性查询显示 hasAccessControl=false，没有
  biometryCurrentSet 或 userPresence 约束；
- App 的 SpeechRailConfiguration.makeClient() 在启动时直接调用
  SecItemCopyMatching，因此本地音频尚未需要远程服务时也可能弹出“登录”
  钥匙串密码框；
- SpeechRail /health 返回 ready；不带 Authorization 的 /v1/audio/speech
  返回 HTTP 401；
- S00 卡的本地 WAV 可以播放；没有本地音频的小丑卡会进入远程合成，
  当前 UI 将所有非 2xx 状态压缩为“SpeechRail 合成失败”。

结论：问题同时存在于凭据读取时机、凭据访问控制和错误语义三层，
不能只在 UI 上增加一个指纹按钮解决。

## 2. 目标

1. 打开 App 和播放已打包本地 WAV 时不读取 API key，不弹钥匙串授权框。
2. 只有进入需要 SpeechRail 的远程合成路径时才读取凭据。
3. 既有普通钥匙串条目继续可用，不自动删除、覆盖或重置用户钥匙串。
4. 用户可以在 App 的 macOS Settings 中主动创建 Touch ID 优先的受保护条目。
5. 受保护条目存在时，远程合成优先使用它；取消或失败时不暗中回退到旧条目。
6. 远程服务返回 401、403、422、5xx 时给出可执行的用户提示。
7. 不在日志、错误文本、测试输出或仓库中暴露 API key、登录密码或生物识别数据。

## 3. 非目标

- 不自动重置默认钥匙串；
- 不静默删除现有 login 条目；
- 不代替用户输入 Mac 登录密码、钥匙串密码或 API key；
- 不把 API key 写入 .env、Info.plist、UserDefaults、测试 fixture 或 .app 资源；
- 不调用云端认证服务，不改变 SpeechRail 的 loopback 边界；
- 不为 Touch ID 不可用的设备伪造兼容路径；
- 不引入 Foundation Models、云端 AI 或新的远程依赖。

## 4. 方案与选择

### 4.1 方案 A：只延迟读取旧条目

将 Keychain 查询从 App 启动移到远程合成时。实现最小、不会迁移数据，
但旧条目仍然只能使用钥匙串密码，不能获得 Touch ID。

### 4.2 方案 B：只增加 Touch ID 条目

新建带 SecAccessControl 的条目，但不修复启动时读取时机。可以使用指纹，
却仍会在打开 App 时触发旧条目的密码授权，不能解决当前用户体验。

### 4.3 方案 C：混合方案（已获用户批准）

采用方案 A，并增加用户主动迁移/录入入口。新条目使用
kSecAccessControlUserPresence 和 kSecAttrAccessibleWhenUnlockedThisDeviceOnly；
系统优先使用 Touch ID，必要时允许系统密码作为正常降级。旧条目保留为人工可控
的恢复来源，但受保护条目存在后远程播放不自动回退到旧条目。

选择 C 的理由：本地播放不应被远程凭据阻塞，同时为拥有 Touch ID 的用户提供
真实的 Keychain 访问控制，而不是仅在读取前调用一次无关的 LAContext。

## 5. 组件与接口边界

### 5.1 SpeechRailCredentialStore

在 LotmCardStudioCore 的 Ports 层新增凭据存储边界，负责：

- 读取旧服务 com.lotm.cardstudio.speechrail；
- 写入新服务 com.lotm.cardstudio.speechrail.touchid；
- 以稳定枚举返回 protected、legacy、missing、unavailable；
- 只在用户主动迁移或远程合成时读取秘密数据；
- 使用 SecAccessControlCreateWithFlags 创建 userPresence 保护；
- 受保护读取时把 LAContext 通过 kSecUseAuthenticationContext 传给 Security；
- 将底层 OSStatus 转成不包含秘密的领域错误。

受保护条目约束：

    service:    com.lotm.cardstudio.speechrail.touchid
    account:    api-key
    access:     kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    control:    kSecAccessControlUserPresence

userPresence 表示由系统选择 Touch ID 或系统密码，目标是“Touch ID 优先、
仍可正常使用”。如果未来明确要求强制指纹，再单独评审 biometryCurrentSet，
不在本次混合方案中默认启用。

### 5.2 SpeechRailHTTPClient

保留现有固定 apiKey 初始化方式，新增可选的异步 API key provider。

- makeSpeechRequest 在已有固定 key 的调用中保持同步行为；
- synthesize 在真正发起网络请求前解析 provider；
- provider 不在客户端初始化时执行；
- provider 错误向上保留为可分类的凭据错误；
- 既有 loopback、重定向阻断、输入长度和响应校验不改变。

这样既不破坏现有测试和 fake client，又能保证 SpeechPlaybackCoordinator 的本地
音频快速路径不会触发 Keychain。

### 5.3 LotmCardStudioApp

SpeechRailConfiguration.makeClient() 只组装 loopback client 和延迟 provider，
不在 body 初始化时读取 API key。应用启动阶段只检查本地 fixture 和 UI，
不要求用户先完成 SpeechRail 授权。

### 5.4 macOS Settings

增加原生 Settings scene 和 SpeechRailSettingsView：

- 显示当前凭据状态，不显示 key 内容；
- “迁移现有钥匙串项并启用 Touch ID”：用户主动点击后读取旧条目；
- “使用 API key 建立 Touch ID 保护”：用户可以在 SecureField 中自行输入；
- 保存后使用受保护读取完成一次验证；
- 失败时保留旧条目和文字说明；
- 不提供无确认的删除/重置默认钥匙串按钮。

设置页只处理配置和验证，不直接触发卡牌播放。

## 6. 运行时数据流

### 6.1 本地音频路径

    启动 App
      → 创建带延迟 provider 的 SpeechRail client
      → 用户点击 S00 / Audrey
      → 播放已批准本地 WAV
      → 不读取 Keychain，不请求 Touch ID，不访问 SpeechRail

### 6.2 远程 SpeechRail 路径

    用户点击无本地音频的已批准台词
      → SpeechPlaybackCoordinator 发布字幕并进入 loading
      → 本地 WAV 查找失败
      → provider 检查受保护条目
          ├─ 存在：用 LAContext + userPresence 读取
          └─ 不存在：按用户选择读取旧 login 条目
      → 请求 loopback /v1/audio/speech
      → HTTP 2xx：解码并播放
      → HTTP 401/403/422/5xx：显示稳定错误，保留文字稿

受保护条目存在但用户取消认证或认证失败时，当前请求直接失败，不再自动读取
旧条目，以免用户刚拒绝 Touch ID 又被迫看到另一个密码框。

### 6.3 迁移路径

    用户打开 Settings
      → 查看凭据状态
      → 点击迁移或输入 key
      → （迁移旧条目时）系统可能要求一次旧钥匙串密码
      → 写入 touchid 服务条目
      → 通过 LAContext 验证受保护读取
      → 验证成功才标记 protected 已启用

写入顺序必须是“新条目写入并验证成功，再更新 App 偏好”；旧条目始终不先删，
避免迁移中断造成凭据丢失。迁移过程中不打印或展示 API key。

## 7. 错误语义

当前 SpeechRailError.httpStatus 保留原始状态码，UI 映射至少包括：

| 条件 | 用户提示 |
|---|---|
| 401 | SpeechRail API key 缺失或无效，请在设置中配置 |
| 403 | SpeechRail API key 无权访问 |
| 422 | SpeechRail 拒绝了当前语音请求，请检查 voice 或文本 |
| 408/超时 | SpeechRail 请求超时，文字稿仍可阅读 |
| 5xx | SpeechRail 服务暂时不可用，请稍后重试 |
| Keychain 认证取消 | 未完成钥匙串认证，文字稿仍可阅读 |
| 音频解码失败 | SpeechRail 返回的音频无法播放 |

错误提示不包含 HTTP response body、Authorization header、Keychain data 或
底层路径。

## 8. 安全约束

- apiKey 只存在于必要的内存生命周期，不写日志；
- Settings 使用 SecureField，提交后清空临时输入；
- 受保护条目使用 ThisDeviceOnly，不引入不必要的跨设备迁移；
- 旧条目保持用户原有状态，不做隐式覆盖；
- 失败、取消和超时都保留文字稿，不伪造播放成功；
- 所有外部 SpeechRail 响应只使用状态码和已验证音频数据；
- 单元测试使用 fake Keychain backend / fake provider，不读写真实用户钥匙串；
- 手动迁移由用户在本机完成，Agent 不接触密码或 API key。

## 9. 测试与验收

### 单元测试

- SpeechRailHTTPClient 的异步 provider 只在 synthesize 路径调用；
- 本地 WAV 命中时 SpeechPlaybackCoordinator 不触发 provider；
- provider 缺失/认证取消能转成稳定错误；
- 401、403、422、408 和 5xx 映射为对应用户提示；
- fake Keychain backend 能覆盖 legacy、protected、missing 和迁移失败；
- 迁移失败时旧条目仍可读取，且不会标记 protected；
- 用户拒绝受保护认证时不会自动回退旧条目；
- 原有批准门槛、字幕保留、停止/取消和 loopback 安全测试继续通过。

### 本机闭环验收

1. 关闭 App 后重新打开：不出现 Keychain 密码框。
2. S00 / Audrey 的本地问候语和故事可以直接播放。
3. 未配置或无效 key 的远程卡显示 401 的明确提示，文字稿仍保留。
4. 在 Settings 迁移旧条目或输入 key，完成一次 Touch ID/系统认证验证。
5. 再次播放远程卡：出现系统 Touch ID 优先授权，成功后请求 SpeechRail。
6. 点击拒绝/取消：不播放、不清空文字稿、不弹第二个旧条目密码框。
7. SpeechRail 健康检查、HTTP 请求、音频解码和停止播放均有可见结果。
8. 更新 apps/LotmCardStudio/docs/qa/m1-local-run.md，记录实际使用的安装包、
   授权结果和未覆盖项。

## 10. 交付顺序

1. 先增加 fake provider / Keychain backend 契约和回归测试；
2. 实现 HTTP client 延迟 provider 与错误映射；
3. 修改 App 初始化，消除启动期 Keychain 读取；
4. 实现受保护条目读写和迁移服务；
5. 增加 Settings scene；
6. 运行 swift test、debug/release .app 构建；
7. 安装并手动执行本机闭环，用户亲自完成 Touch ID/密码输入；
8. 更新 QA 记录并进行代码审查。

本设计不授权 Agent 自动迁移、删除或重置用户钥匙串。只有用户在 App 设置页
明确点击并亲自完成认证后，才执行实际的受保护条目写入。

## 11. 参考

- https://developer.apple.com/documentation/security/restricting-keychain-item-accessibility
- https://developer.apple.com/documentation/security/secaccesscontrolcreateflags/biometrycurrentset
- https://developer.apple.com/documentation/security/ksecuseauthenticationcontext
