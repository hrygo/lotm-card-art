---
title: "LotmCardStudio SpeechRail 配置文件覆盖方案"
status: implemented
version: "1.0.0"
date: 2026-09-13
audience: "macOS 客户端与本机 SpeechRail 使用者"
---

# LotmCardStudio SpeechRail 配置文件覆盖方案

## 决策

用户在混合方案已实现后明确决定：旧登录钥匙串密码永远无法通过，SpeechRail API key 改由仓库外的本机配置文件提供。当前 App 运行时完全不读取旧 Keychain，不迁移、不删除，也不以 Keychain 作为 fallback。

## 文件契约

- 默认路径：`~/Library/Application Support/LotmCardStudio/SpeechRail.json`
- JSON 结构：

  ```json
  {"apiKey":"你的 SpeechRail API key"}
  ```

- 应用 Settings 页写入时创建父目录并设置 `0700`，文件设置 `0600`。
- key 只在配置文件读取、请求头构造和请求生命周期内进入内存；不写日志、UserDefaults、Info.plist、`.app` 资源或仓库。
- 空值、坏 JSON、读取失败都会转换为稳定错误；不会把错误响应体或 key 回显给用户。

## 运行时闭环

1. App 启动只创建 loopback `SpeechRailHTTPClient` 和延迟 provider，不读取配置文件。
2. 本地 WAV 命中时直接播放，不读取配置文件、不触发 SpeechRail。
3. 没有本地 WAV 的已批准台词在发起远程合成前读取 `SpeechRail.json`。
4. 文件缺失/无效显示“回到 Settings 配置文件”；HTTP 401 显示 key 缺失或无效；所有失败保留字幕和文字稿。
5. Settings 使用 `SecureField` 输入并在提交前清空临时输入；保存成功后刷新“配置文件已就绪”状态。

## 旧钥匙串处理

此前实现的 `SpeechRailCredentialStore` 和 Touch ID 代码保留为隔离、可测试的未来能力及回归材料，但不在当前 App 的 `SpeechRailConfiguration` 或 Settings 运行路径中实例化。这样旧条目的 ACL、登录钥匙串密码同步状态和 Touch ID 能力不会影响当前配置文件方案。

## 验收边界

- 已自动化验证配置文件读取/写入、权限、空值/坏文件、Settings 状态更新、延迟 provider、401 错误映射。
- 已通过原生 UI 验证启动、本地 S00 播放、Settings 入口和缺失配置状态不弹旧钥匙串密码框。
- 真实 API key 未由 Agent 读取或写入；用户需在 Settings 输入，或本人按上述格式编辑该文件。
