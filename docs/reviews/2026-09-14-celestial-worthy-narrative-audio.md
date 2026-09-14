# 福生玄黄天尊叙事与配音版本记录

日期：2026-09-14  
状态：本轮用户明确请求制作的新版本（文案由用户逐字批准原文）

## 范围

本记录只覆盖 App 内新增的第三张隔离候选卡：

- `lotm.celestial-worthy.primordial-01`：福生玄黄天尊，序列之上 · 诡秘之主（非序列卡位，`slotID: lotm.celestial-worthy`）。

不涉及既有 S09「克莱恩·莫雷蒂」与 S00「愚者先生」两张卡。

## 文案边界

本版本共 6 条：1 条问候语、2 条原创口头语、3 个解释性故事章节。口头语标记 `original`，故事标记 `interpretation`；不使用原著逐字引文，不把原创内容冒称正典。

故事只写第一部范围：源堡的茧与穿越者布局 → 以名字影响世界 → 第一部末尾“没有结束的失败”；不使用第二部《宿命之环》内容。

六维与证据边界见 `docs/research/2026-09-14-celestial-worthy-card-materials.md`；故事的证据定位见 `docs/research/2026-09-14-fool-known-characters-dossier.md` §4.5。天尊被定位为「序列之上」存在，本卡不按 9–0 任一序列卡位归档，也不降格为真神。

## 声音合同

- 使用 SpeechRail 本机 `/v1/voices` 上本轮注册的自定义 VoiceDesign 音色 `celestial-worthy`（极其古老、低沉、偏中性、空旷，`available=true`）；不做声音克隆，不注册除该音色外的其他音色。
- 每条完整台词单独生成 WAV；应用资源名与 `NarrativeLine.audioResourceName` 一一对应。
- 生成后必须通过真实 WAV 解码、`24kHz / Int16 / 单声道 PCM` 采样格式、时长与 SHA-256 校验；失败则保留文字稿而不宣称配音完成。

## 审核说明

文案由用户在本轮逐字批准（`review.by = project-editor`）。机器摘要只证明版本绑定一致，不替代事实核验或视觉批准。本卡仍保持视觉候选状态，不进入正式卡牌 release。
