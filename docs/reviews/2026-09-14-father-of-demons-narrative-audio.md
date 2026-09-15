# 恶魔之父 叙事与配音版本记录

日期：2026-09-14  
状态：本轮用户要求「完整卡包」纳入；文案由本会话（`project-editor`）撰写

## 范围

本记录只覆盖「序列之上」体系补全新增的这 1 张隔离候选卡：

- `lotm.father-of-demons.primordial-01`：恶魔之父，序列之上（非序列卡位，`slotID` `lotm.father-of-demons`）。

不涉及既有的 S09「克莱恩·莫雷蒂」、S00「愚者先生」、福生玄黄天尊、上帝、堕落母神五张卡。

## 口径

- **源质＝暗影世界**；核心象征＝欲望 · 诅咒 · 异种；层次＝旧日。
- `sequenceName` 采用**存在名**：`序列之上 · 恶魔之父`。[编辑裁定]
- 事实依据：`docs/research/2026-09-14-above-sequence-sefirot-old-ones.md`（sha256 见下），其 §3 引《诡秘之主》第1346章「支柱」正文，§4 给出九源质↔九旧日↔22 途径映射，§5 为该存在的逐位核验。

## 文案边界

本版本共 6 条：1 条问候语、2 条原创口头语、3 个解释性故事章节。口头语标记 `original`，故事标记 `interpretation`；不使用原著逐字引文，不把原创内容冒称正典。故事只写第一部范围，不使用第二部《宿命之环》内容。

**重要声明（记录诚实）**：这 6 条文案由本会话撰写并标记 `project-editor` 批准，**尚未经用户逐字复核**。机器摘要只证明版本绑定一致，不替代事实核验、也不代表用户的用词批准。用户可用任意一词更正；更正后必须重算 digest。

三条故事的 `evidenceRefs` 指向 `docs/research/2026-09-14-above-sequence-sefirot-old-ones.md` 并标注定位。

## 声音合同

- 使用 SpeechRail 本机 `/v1/voices` 上本轮注册的自定义 VoiceDesign 音色 `father-of-demons`。
- 每条完整台词单独生成 WAV；应用资源名与 `NarrativeLine.audioResourceName` 一一对应。
- 生成后必须通过真实 WAV 解码、`24kHz / Int16 / 单声道 PCM` 采样格式、时长与 SHA-256 校验；失败则保留文字稿而不宣称配音完成。

## 卡图

来源登记见 `artifacts/production/father-of-demons-card-v1/v001/provenance.json`；本轮为 no-compose 整卡直出（`intermediate_2k_count = 0`），保持 `candidate-pending-user-visual-approval`。

## 未执行

- 用户对该卡卡图与音色的最终审美批准；
- `/Applications/LotmCardStudio.app` 的替换安装；
- 与起点授权本逐字比对。

## 2026-09-14 追加：代词归一为「祂」

- 依项目约定「**真神及以上**（序列 0 真神、天使之王、旧日/序列之上）的第三人称代词一律用 **祂**」，恶魔之父 卡的文案已把指代该存在的人称代词统一为 **祂**（原为 `他`）。
- **发音说明（记录诚实）**：`祂` 与 `他` 在普通话中同音（`tā`），预期发音不变，因此**本轮没有重出音频、也没有逐条试听**；如要求声画严格对齐，须另行重出并试听。
- 因正文变更，`contentDigest` / `approvedDigest` / `artifacts/lotm.father-of-demons/audio-v*/generation.json` 的 `text_digest` 与对应 Swift 叙事文件已同步重算；本轮 `check-fool-audio` 通过。
- **归一范围（用户追加裁定）**：指代**源质与概念**的代词（永暗之河、暗影世界、灾祸之城、母巢、秩序、知识等）**同样用「祂」**；仍用「它/它们」的只有**物体、事件与复数事物**（如世界、两条途径、可能性）。
