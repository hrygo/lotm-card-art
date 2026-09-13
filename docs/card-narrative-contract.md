# 单卡角色叙事合同

版本：1.0.0。当前生产 SOP 的内容分支，覆盖问候、口头语和角色故事。叙事与卡面共用身份，独立审核；不占主插画文字区域，不替代卡面六维语义。

按 [开工与交付检查表](production-preflight.md) 区分完整人物卡、视觉试装和物料任务；叙事内容的逐项质量标准与返修影响见该表第4–6节。纯物料不强制创建故事，完整人物卡不以空模板代替成稿。

## 输入与交付

结构以 `production/schemas/card-narrative.schema.json` 为准；空模板为 `production/templates/card-narrative.json`。复制到本卡独立文件后绑定真实身份，不把模板当成已完成文案。

| 数据 | 生产要求 |
| --- | --- |
| identity | cardID、slotID、characterID、identitySliceID、准确姓名、timeScope、spoilerBoundary；与主体任务身份一致，不混用不同化名、时期或未来能力 |
| greeting | 当前身份自然说出的简短问候；避免通用客服口吻，与口头语分工明确 |
| catchphrase | 有记忆点、符合语气与性格的短句；可有多条。原著口头语须有出现位置，单次台词不能未经判断就称为惯常口头禅 |
| story | 一章一个事件或心理转折：处境、行动、变化和代价；标题与正文分离，可多章，不是能力百科或剧情年表 |
| sourceKind | canon 为可定位核验的原文；interpretation 为基于证据的概括；original 为明确原创的角色化表达。不可把拟写台词标成原著引文 |
| evidenceRefs | 仓库内证据文件路径、SHA-256、locator（章节/段落/断言 ID）；引用范围与逐字文案对应 |
| gap | 尚未研究或创作的内容留下具体缺口，不造台词补齐；有缺口的条目不批准 |
| review | draft/approved/rejected；批准绑定 contentDigest、批准人及可追溯依据，不由 Agent 自批 |

三类内容都必须有条目；尚未制作时允许空正文加明确 gap，表示待办而非成品。多章故事共用当前身份边界，每章有唯一 ID。角色原型可使用 characterID=null，但名称必须明确其原型身份。

## 执行顺序

1. **身份与研究。** 读取本卡事实、时间段与禁止剧透内容。分别记录台词原文、解释性概括与原创表达；不凭模型记忆伪造章节，遵守引文与再分发限制。
2. **内容设计。** 写问候、口头语及故事章节方案，确认角色视角、语气、事件、情绪和与画面主事件的关系。原创表达也不得违背已知事实或提前泄露高序列能力。
3. **逐字成稿。** 正文是将来展示与发声的准确文本，不混入 TTS 指令。别名、多音字、专有名词另建读音表，不擅改显示姓名来迁就读音。
4. **检查与批准。** 运行结构检查，核对证据、角色口吻、时间线、剧透、重复与故事完整性，再提交逐字文案给用户。真实批准后记录摘要和依据。批量认可须明确覆盖条目及摘要。
5. **声音生产。** 只对已批准条目且当前请求授权的声音任务执行。另行确认可用音色、语速/情绪/停顿、读音与模型参数；文字批准不自动授权创建新音色、克隆声音或全量 TTS。
6. **试听与登记。** 校对发音、遗漏、断句、情绪、响度与削波；音频记录绑定条目 ID、文案摘要、音色/参数、实际文件摘要、格式、时长和试听结论。文字通过不等于声音通过。
7. **交付与接入。** 交付当前卡内容包和独立音频清单；仅请求包含 App 时进行导入、资源绑定和播放验证。服务失败保留可读文案，不伪造音频完成。

## 可执行检查

```bash
python3 tools/production.py check-content production/templates/card-narrative.json
python3 tools/production.py check-content production/templates/card-narrative.json --ready-for-audio
```

第一条只校验结构、摘要与已有批准的一致性，输出待办及各条目的计算摘要；第二条要求包内全部条目已有当前逐字批准，空模板应失败。两者均不调用声音服务。单条已批准、其他仍草稿时，不用全包失败推翻已有批准；声音执行者逐条按同一规则检查，暂不提供自动批量声音命令。

摘要算法是 UTF-8 JSON（sort_keys=true、ensure_ascii=false、separators=(",", ":")）的 SHA-256；输入包含 identity 和该条目除 contentDigest/review 外的全部字段。正文、章节标题、身份阶段、剧透边界、来源或证据摘要变化，原批准失效。不得仅替换批准摘要来“修复”失配；重新审核。

机器检查记录一致性，不能认证批准人的真实身份、证据内容或语气质量。`--ready-for-audio` 表示文字门槛通过，不表示已获得本轮声音授权或声音已生成。

该检查是独立入口，旧图像 release 不会自动替你执行全文案与声音审核。完整内容交付须分别记录视觉、叙事、音频结论；纯物料任务不强制创作角色故事。

## 与图像任务及 App 的边界

subject 任务可用 `narrative: {path, sha256}` 引用本包，编译时核对 cardID/slotID/characterID/name 并追踪叙事文件及证据。它不是图像附件，不将口头语/故事全文自动写入生图 prompt；只转译获准的动作、物件与情绪意向。其他文字 brief 用 `contracts: [{path, sha256}]` 追踪，与实际图像 `references` 分开。

本生产 JSON 不是 App 的直接 Codable 输入。目前仅复用 App 既有 greeting/catchphrase/story 与 canon/interpretation/original 枚举语义；接入时非 story 条目映射 NarrativePack.lines，story 条目映射 StoryChapter（title 与 line 分离），审核映射 NarrativeReview，音频清单映射 audioResourceName。当前未实现导入器，不能宣称模板已进入 App。
