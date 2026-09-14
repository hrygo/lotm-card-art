# 上帝叙事与配音版本记录

日期：2026-09-14  
状态：本轮用户明确请求制作的新版本（文案由用户逐字批准原文）

## 范围

本记录只覆盖 App 内新增的第四张隔离候选卡：

- `lotm.god-almighty.primordial-01`：上帝，序列之上 · 星界支柱（非序列卡位，`slotID: lotm.god-almighty`）。

不涉及既有 S09「克莱恩·莫雷蒂」、S00「愚者先生」与「福生玄黄天尊」三张卡。

## 文案边界

本版本共 6 条：1 条问候语、2 条原创口头语、3 个解释性故事章节。口头语标记 `original`，故事标记 `interpretation`；不使用原著逐字引文，不把原创内容冒称正典。

故事只写第一部范围：站在混沌海之上 → 全知与全能不是动作 → 星界的主人；不使用第二部《宿命之环》内容。

六维与证据边界见 `docs/research/2026-09-14-god-almighty-card-materials.md`（sha256 `4addcfb48d9fb90244f98bfd162474a50cd3b2dddec2dd22edbd7e7b5f34288d`），三条故事的 `evidenceRefs` 均指向该包并逐项标注定位。上帝与福生玄黄天尊按「双支柱对照」处理：天尊＝源堡／诡秘／时空／错误，上帝＝混沌海／全知全能／创造／星界之主；本卡不按 9–0 任一序列卡位归档，也不降格为真神。

## 声音合同

- 使用 SpeechRail 本机 `/v1/voices` 上本轮注册的自定义 VoiceDesign 音色 `god-almighty`（无面光辉、古老、克制、陈述式而非宣告式）；不做声音克隆，不注册除该音色外的其他音色。
- 每条完整台词单独生成 WAV；应用资源名与 `NarrativeLine.audioResourceName` 一一对应。
- 生成后必须通过真实 WAV 解码、`24kHz / Int16 / 单声道 PCM` 采样格式、时长与 SHA-256 校验；失败则保留文字稿而不宣称配音完成。

## 审核说明

文案由用户在本轮逐字批准（`review.by = project-editor`）。机器摘要只证明版本绑定一致，不替代事实核验或视觉批准。本卡仍保持视觉候选状态，不进入正式卡牌 release。

卡图来源与落盘见 `artifacts/production/god-almighty-card-v1/v001/provenance.json`；本轮为 no-compose 整卡直出，`intermediate_2k_count = 0`。
