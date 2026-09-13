# S00「愚者」音频生成记录

- 生成日期：2026-09-13
- 服务：本机 SpeechRail `2.5.1`，`POST /v1/audio/speech`
- 模型：`speechrail/qwen3-tts`
- 音色：`uncle_fu`（SpeechRail 系统音色；醇厚中文男声）
- 参数：`response_format=wav`、`speed=0.94`、`language=zh`
- 认证：从 SpeechRail 运行时 `.env` 读取，仅用于当前生成与本机 Keychain 配置；密钥未写入本记录、仓库或 `.app`
- 文案来源：本仓库 `DemoContent.swift` 中经用户批准的 6 条文案；`sourceKind` 保持 `.original` / `.interpretation`
- 处理：问候语和口头禅各单次生成；三章故事按自然句切分生成，再用 `ffmpeg` 合并为每章一个 WAV，以适配当前运行时的实际单次文本长度限制。卡面文字与内容摘要没有被切分或改写。

## 资产校验

| 内容摘要 | 本地资源 | 时长 | SHA-256 |
| --- | --- | ---: | --- |
| `s00-greeting-approved-v1` | `s00-greeting-v1.wav` | 10.000 s | `189c3fe6ea6332b6dc895608fc4ae5dc120a82ae2f346b55142963b8957c36a4` |
| `s00-catchphrase-01-approved-v1` | `s00-catchphrase-01-v1.wav` | 5.520 s | `9e5db26bfabddda632a9ce161c0c67006ff2d2ed5a56d33f6439ed01de5bbf4c` |
| `s00-catchphrase-02-approved-v1` | `s00-catchphrase-02-v1.wav` | 7.840 s | `ca7ba8d53bf825dd8c4b33da32611837297cdeab28f10182cf0b0d58f928bd79` |
| `s00-story-01-approved-v1` | `s00-story-01-v1.wav` | 34.560 s | `5bb1a16ba550dae2a5844c01cbd4928acc97abfac2dd45e080af92d085a081c2` |
| `s00-story-02-approved-v1` | `s00-story-02-v1.wav` | 27.600 s | `a49226757341c341794f11f703bfabcd4e96cf5a921acb6ae88c7460f544b791` |
| `s00-story-03-approved-v1` | `s00-story-03-v1.wav` | 30.080 s | `6b028b2aeefddbbd937983c41e26f0715a564be02fb335a7da39d4c561dc3c4b` |

## 范围与限制

- 这是用户批准的 S00 试听资产，不代表视觉卡已正式批准，也不计为 220 张最终高清卡面。
- `uncle_fu` 是可用系统音色，不是注册成功的 Klein 专属自定义音色，也不模仿任何真实演员或现有角色声线。
- 自定义 voice design 未写入本仓库；应用仍允许在本地资源缺失时回退到已配置的 SpeechRail loopback 客户端。
