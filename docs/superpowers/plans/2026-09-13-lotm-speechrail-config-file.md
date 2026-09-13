# LotmCardStudio SpeechRail 配置文件覆盖实施记录

> **For agentic workers:** This is the execution record for the user's later decision to bypass the legacy Keychain path.

**Goal:** 让用户无需输入失效的旧“登录”钥匙串密码，即可通过仓库外的本机 `SpeechRail.json` 配置 SpeechRail API key，并完成远程语音闭环。

**Current decision:** 配置文件方案覆盖此前已实现的混合 Touch ID 方案；当前 App 不读取、迁移或删除旧 Keychain 条目。旧 Touch ID 代码仅保留为隔离回归材料，不在运行时 provider 或 Settings 中实例化。

**Spec:** `docs/superpowers/specs/2026-09-13-lotm-speechrail-config-file-override.md`

## Implementation

- [x] Add `SpeechRailConfigurationFileStore` with default path `~/Library/Application Support/LotmCardStudio/SpeechRail.json`.
- [x] Use JSON `{ "apiKey": "..." }`, trim input, reject empty/bad data, create directory `0700`, and write the file `0600`.
- [x] Make `SpeechRailHTTPClient` resolve the file provider only at synthesis time; preserve loopback and fixed-key tests.
- [x] Replace Settings' migration UI with a native configuration-file status/path/secure-input flow; clear the input immediately after submission.
- [x] Keep captions/transcripts visible and map missing/invalid config plus HTTP 401/422 to actionable messages.
- [x] Split local-audio / remote-SpeechRail / pending readiness states and clear stale playback when switching cards.
- [x] Update README and QA records without writing any real API key.

## Verification

- [x] Focused file-store, configuration, settings, playback, and UI-state tests pass.
- [x] Run final full `swift test`, debug/release builds, release metadata/signature checks, install, and CUA closed-loop check.
- [ ] User personally supplies the real API key through Settings or the documented file format; Agent does not read or write the secret.
