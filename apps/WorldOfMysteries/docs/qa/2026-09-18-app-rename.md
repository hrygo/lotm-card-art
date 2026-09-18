# App 更名「卡牌演示」·机器观察记录（2026-09-18）

对象：`apps/WorldOfMysteries` 客户端应用（更名前显示名「诡秘世界」；决策见 `docs/DECISIONS.md` D26）。
范围：只改应用显示名与 bundle 标识——界面、功能、卡片 fixture、音频与 SpeechRail 行为零改动。

## 改动对照

| 面 | 改前 | 改后 |
| :--- | :--- | :--- |
| 应用显示名（`CFBundleDisplayName`／`CFBundleName`／`Resources/zh-Hans.lproj/InfoPlist.strings`） | 诡秘世界 | **卡牌演示** |
| bundle id | `com.hrygo.world-of-mysteries` | `com.hrygo.lotm-card-art` |
| 打包产物 | `.build/诡秘世界.app` | `.build/卡牌演示.app` |
| 安装路径 | `/Applications/诡秘世界.app` | `/Applications/卡牌演示.app` |
| 窗口标题（`WindowGroup`） | 诡秘世界 | 卡牌演示 |
| 进程名／SwiftPM 模块名／源码目录 | `WorldOfMysteries` | 不变（有意保留 ASCII） |
| SpeechRail 配置目录与 Keychain 服务名 | `…/Application Support/WorldOfMysteries/`、`com.hrygo.world-of-mysteries.speechrail*` | 不变（有意：改名会让已存凭据失联） |

## 验证

环境：Apple silicon、macOS 26（本机），2026-09-18 13:56 起。

- `swift test`（在 `apps/WorldOfMysteries`）：XCTest **55 用例 / 0 失败**，与改动前基线一致。
  **如实说明**：同一命令下 Features 目标的 Swift Testing 用例报告 `Test run with 0 tests in 0 suites`——**改动前即如此**，属既有缺口，本次未修，因此这 95 条不能算作本次已验证的证据。
- `python3 -m unittest discover -s tests`：**222 tests OK（skipped=6）**。
- `python3 tools/selfcheck.py`：**7/7 步通过**（scaffold → pins → design-tokens → required-checks → fool-materials → fool-cards → suite）。
- `./scripts/build-app.sh debug` 与 `./scripts/build-app.sh release`：均退出 0。
- 产物核对：`plutil -p` 显示 `CFBundleDisplayName`／`CFBundleName` = 「卡牌演示」、`CFBundleIdentifier` = `com.hrygo.lotm-card-art`、`LSMinimumSystemVersion` = 26.0；`Contents/Resources` 含 `CardArt`（22 个文件 = 11 张 × 2 档）、`Audio`（66）、`zh-Hans.lproj`；`lipo -archs` = `arm64`；`codesign --verify --deep --strict` 通过。
- 安装与启动：`ditto` 复制到 `/Applications/卡牌演示.app`；`open` 后 8 秒进程仍在（未崩溃退出），`lsappinfo find bundleid=com.hrygo.lotm-card-art` 返回 `ASN:0x0-0x3c03c00-"卡牌演示"`，`LSDisplayName=卡牌演示`、`LSBundlePath=/Applications/卡牌演示.app`；随后按 bundle id 正常退出（`tell application id … to quit` 成功）。

## 边界与未完成

- 以上均为**机器与 Agent 观察**，不构成用户视觉批准（`docs/DECISIONS.md` D16 口径不变）；菜单栏与窗口标题在屏幕上的实际渲染仍需要人看一眼。
- **未验证**：窗口内标题渲染（未读辅助功能树、未截图）；更名不影响 220 张规模、包体与内存的既有结论。
- `/Applications/诡秘世界.app`（2026-09-15 的 release 构建）当时正在被用户运行（13:41 启动），因此没有当场移走；用户退出该实例后，于 14:03 移入废纸篓 `~/.Trash/诡秘世界-20260918-1403-app-renamed-to-卡牌演示.app`（可恢复）。`/Applications` 下现在只剩 `/Applications/卡牌演示.app`。
- 本次改动**未提交**；工作区另有一批在途文档改动（`AGENTS.md`／`README.md`／`docs/` 索引，非本次会话产生）。
