# 奥黛丽·心理医生语音生成记录

卡牌：`lotm.visionary.s07.audrey-01`  
生成日期：2026-09-13  
服务：本机 SpeechRail loopback `http://127.0.0.1:8201`  
服务版本/profile：`2.5.1` / `quality`  
模型：`speechrail/qwen3-tts`  
音色：`serena`（实际 `/v1/voices` 返回 `available=true` 的系统音色）  
参数：`response_format=wav`、`speed=0.96`、`language=zh`；未发送 `instructions`。  
鉴权：使用已授权的本机运行时配置一次性调用；密钥未写入记录、源代码或 App bundle。

## 文件校验

所有文件均为单声道、24 kHz、Int16 WAV，并通过 macOS `afinfo` 解码检查。

| 内容ID | 音频资源名 | 时长 | SHA-256 |
| --- | --- | ---: | --- |
| `audrey-greeting` | `audrey-greeting-v1` | 5.52 s | `cfd3bdbd7a7b95e7f013c203a12b436d5223af1cd1cba10cb123d158c6c87955` |
| `audrey-catchphrase-01` | `audrey-catchphrase-01-v1` | 4.56 s | `c3b4436c8e629bdd69d1a1e1bf431e564bd320e6e2ed78a5181dfff7f4be69e2` |
| `audrey-catchphrase-02` | `audrey-catchphrase-02-v1` | 2.96 s | `b9ccfbb27f0c30844601af3834fcedae79989311b07774caa4f8c8994f83fbfa` |
| `audrey-story-01` | `audrey-story-01-v1` | 18.40 s | `25af48016a4bf2c525b01f8012e62a7a60b63958fcbfe63a48c4e23d91b5b48c` |
| `audrey-story-02` | `audrey-story-02-v1` | 21.60 s | `767ab317ee7fbc69a6fbc509d4653ab9c5f4f8e95c49ec85bdd5f399fd5fb1b0` |
| `audrey-story-03` | `audrey-story-03-v1` | 22.08 s | `b6a7390321ab33dc2d6291b35f3f68ecea8232c77e47758e629f8f4e19d045f8` |

文本审批由用户在当前任务中确认；App 只对摘要匹配的 `NarrativeReview.approved` 内容开放播放。
