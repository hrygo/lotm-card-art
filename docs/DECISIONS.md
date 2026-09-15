# 设计决策记录

## D01｜六维是语义，不是栏目
原因：用户要求身份、扮演、能力、魔药、晋升、限制完整，但允许文字、图像与序列风格等不同方式体现。
结果：每维设claim、intent、cue、fidelity、readback；删去旧版“配方和仪式可完全省略”以及“六项必须全部文字化”的方向。

## D02｜必须在牌面上，但不一定精确穷尽
资料库保存可核验事实，牌面表达与当前主题相符的代表摘要。未标完整就不承诺完整配方/全能力。
侧边说明、alt或App详情仅作辅助，不掩盖卡面的语义缺失。

## D03｜根文件精简，规则和数据分开
根AGENTS给边界；路径AGENTS防特有误用；设计文档讲方法；card.json单一事实源。
不复制220份AGENTS，不搭建与当前出图无关的大百科或数据库。

## D04｜统一骨架、路径语法、单卡事件
四种构图共享身份锚点，22条途径在材质/形状/关系上分别设计；不锁死六格布局和固定正文百分比。
本包给22份原创路径视觉提案，但没有宣称其所有意象已在全部序列合法。

## D05｜结构可完成，设定不冒充完成
220卡位完整，不等于220份已审核设计。中文标签为检索种子，缺少证据时字段保留明确未知。
公开网页可以作为检索入口，不被包装成已读中文全书。

## D06｜可运行但不绑定出图服务
标准库Python提供检查和任务编译；不捆绑模型、密钥或收费调用。
真正发图、排版、超分与视觉审查由当时可用工具完成，并如实记录。

## D07｜三级验收与反例测试
scaffold应通过，空卡design/release应失败。检验“拒绝坏数据”的能力比只打印成功更重要。
像素头检查、记录审核与实际看图不是同一件事；人工回读结果不能用机器推断冒充。

## D08｜不假借历史批准
文本偏好作为候选基线，原图未取得时不登记为已批准资产。所有初始视觉方向均为proposed。

## D09｜跨途径层级称谓与序列0卡型
层级数字与途径序列名分离维护。当前第五纪采用序列9–8低序列、7–5中序列、4–1高序列/半神；4–3通常为圣者，2–1通常为天使，序列1可在有证据时标记大天使。天使之王记录为序列1之上的人物状态，不当作独立序列或序列1的无条件同义词；序列0是对应途径的真神，也是正式序列卡位，不归入特殊事件。规则与证据状态见`config/sequence-hierarchy.json`。

## D10｜被取代的流程文档不留在仓库
原因：`production-sop.md`（v1 工具合同）与 `production-sop-v2.md`（历史五档）已被 `production-sop-v3.md` 取代，`docs/AGENTS.md` 本已禁止按其实施；留在仓库只会被误读为可选入口或“仍然有效”。
结果：两份历史 SOP 从仓库移除，追溯以 git 历史为准。`docs/AGENTS.md` 的“历史文档保留原文”改为只约束仍列在效力表中的历史文档；被后续版 SOP 明确取代的流程文档随取代决定一并移除，效力表与路由须同步更新。`tools/production.py` 的 `task_dependencies` 不再把被取代文档计入当前任务依赖。

## D11｜序列之上存在的非序列卡位与叙事 slotID 放宽
原因：福生玄黄天尊被定位为「序列之上 · 诡秘之主」，既有的卡位语义全部绑定「途径 × 序列 9–0」；把它塞进任一序列会降格事实，也需要一个不占序列卡槽的载体。
结果：引入非序列 `slotID` 形态 `lotm.celestial-worthy`。`production/schemas/card-narrative.schema.json` 的 `identity.slotID` 模式由 `^lotm\.[a-z-]+\.s0[0-9]$` 放宽为 `^(lotm\.[a-z-]+\.s0[0-9]|lotm\.[a-z][a-z0-9-]*)$`，只额外接纳单个「途径级」非序列段；App `CardIdentity.slotID` 为自由字符串，无需改动。`validate_fool_audio_package` 的 App 卡图/音频白名单从写死两卡改为登记式三卡，`tests/test_fool_card_validation.py` 同步。序列候选清单 `production/cards/fool-card-candidates-v1.json` 与 `validate_fool_cards` 仍只覆盖序列卡，不含天尊；`check-fool-cards` 不受影响。

## D12｜第二个支柱「上帝」复用非序列卡位与登记式白名单
原因：上帝被定位为三大支柱之一、与福生玄黄天尊同级（源质＝混沌海，核心象征＝全知／全能／造物主／星界之主），同样不落在「途径 × 序列 9–0」语义内。D11 引入的非序列 `slotID` 形态需要验证是否可被第二个对象复用；不能为其临时改 schema。
结果：新增第二个非序列卡位 `lotm.god-almighty`（`cardID lotm.god-almighty.primordial-01`），直接沿用 D11 已放宽的 `identity.slotID` 模式，`production/schemas/card-narrative.schema.json` 无需再次改动。`validate_fool_audio_package` 的登记式白名单由三卡扩到四卡（24 个 WAV、4 张 App 卡图），`tests/test_fool_card_validation.py` 的 exact-count 断言同步。序列候选清单与 `validate_fool_cards` 仍只覆盖序列卡，不含两位支柱，`check-fool-cards` 不受影响。上帝的本体事实（支柱位格、源质＝混沌海、五途径归属、四核心象征）本轮全部维持 `lead / 待中文底本核验`；本轮外部交叉核证未取得结果，不作为升级依据。卡图以 no-compose 直出登记于 `artifacts/production/god-almighty-card-v1/v001/provenance.json`，保持 `candidate-pending-user-visual-approval`。

## D13｜机器不得自我批准视觉基线
原因：五档清单与分层基线里的 `status: user-approved-agentic-visual-baseline` 由渲染器 `foolpipeline5.swift` 自己写入，而门禁正是拿这个字符串当「已批准」依据；真正的人工批准记录 `production/approvals/fool-agentic-visual-baseline-v1.json`（`visual_approved`/`basis`/`approved_assets`）从未被读取。渲染器能写、门禁就读，等于机器自我批准。
结果：`validate_fool_materials` 必须读取独立的人工 sidecar，校验 `kind`、`visual_approved=true`、用户依据原文、`release_approved=false`，且其 `approved_assets` 的 manifest 与母版哈希须与当前文件一致；渲染器今后写入中性状态 `agentic-native-material-baseline`，状态字符串只作描述、不再构成批准。`compose` 把 `review.json` 纳入回执依赖，`gate` 因此覆盖评审文件。反例测试见 `tests/test_fool_material_validation.py`。

## D14｜第三个支柱「堕落母神」复用非序列卡位，白名单扩到五卡
原因：堕落母神被定位为三大支柱之一，与福生玄黄天尊、上帝同级。用户在回答「源质／途径口径」时裁定：**源质＝母巢**，对应地球侧 **月亮＋母亲** 两条途径，核心象征＝**生命 · 繁衍**，**不纳入**她自身那条外神途径（序列 9 恶棍 → 序列 0 混沌原胎）。该对象不落在「途径 × 序列 9–0」语义内，不能塞进任一序列。
结果：新增第三个非序列卡位 `lotm.mother-goddess-depravity`（`cardID lotm.mother-goddess-depravity.primordial-01`），直接沿用 D11 已放宽的 `identity.slotID` 模式，`production/schemas/card-narrative.schema.json` 无需再改。`validate_fool_audio_package` 的登记式白名单由四卡扩到五卡（30 个 WAV、5 张 App 卡图），`tests/test_fool_card_validation.py` 的 exact-count 断言同步。序列候选清单与 `validate_fool_cards` 仍只覆盖序列卡，不含三位支柱，`check-fool-cards` 不受影响。事实边界：支柱位格、源质＝母巢、被撕裂状态、两途径拆分本轮**全部**维持 `secondary-cross-check / authorial-supplement（转录）`，**没有任何一条可标为 `verified`**；本仓库无中文授权底本，作者公众号原文未取得。`sequenceName` 取「序列之上 · 现实支柱」（由二手「现实世界的主宰」推导），在资料包与汇报中标注为可由用户一词更正。卡图以 no-compose 直出登记于 `artifacts/production/mother-goddess-depravity-card-v1/v001/provenance.json`，保持 `candidate-pending-user-visual-approval`。

## D15｜九位「序列之上」旧日纳入与「真神及以上用祂」代词约定
原因：用户要求把 Downloads 新增的 6 张「序列之上」旧日卡（永恒之暗、恶魔之父、毁灭天灾、失序者、知识之妖、光之钥）作为**完整卡包**纳入，并裁定「**真神及以上**（序列 0 真神、天使之王、旧日/序列之上）的第三人称代词**一律用「祂」**」。
结果：
- 白名单由五卡扩到**十一卡**（66 个 WAV、11 张 App 卡图），`tools/production.py` 的 `packages` 与 `expected_card_art` 同步，`tests/test_fool_card_validation.py` 的 exact-count 断言同步为 11/66/11；`validate_fool_cards` 与序列候选清单仍只覆盖序列卡，不含九位「序列之上」存在。
- 六张新卡沿用 D11 的非序列 `slotID` 形态（`lotm.<slug>`），**不需要**再改 schema；`sequenceName` 取**存在名**（`序列之上 · 永恒之暗` 等），源质另以铭文/资料包记录。
- **已知异常（按用户裁决「按现状纳入」）**：`毁灭天灾` 卡左铭文槽为「毁灭天灾／THE DESTRUCTION CALAMITY」，而其余五张该槽放源质（此处应为**灾祸之城**）。已在 `artifacts/production/destruction-calamity-card-v1/v001/provenance.json` 的 `card_text_observed.readback_note` 与对应审核记录登记，**不自行改图**。
- **代词归一（用户两次裁定）**：指代「真神及以上」主体的人称代词统一为「祂」；指代**源质与概念**的代词（如永暗之河、暗影世界、灾祸之城、母巢、秩序、知识）**同样用「祂」**；只有**物体、事件与复数事物**（世界、「名字与源质同词」这件事、两条途径、可能性）仍用「它/它们」。归一同时作用于卡牌文案、`docs/research/` 资料包与 `docs/reviews/` 说明；`其他/他人` 等词不受影响。
- 正文变更使 `contentDigest`／`approvedDigest`／`artifacts/lotm.<slug>/audio-*/generation.json` 的 `text_digest`／Swift 叙事文件全部同步重算；`祂` 与 `它/他/她` 同音（`tā`），**本轮未重出音频、未逐条试听**，只保证摘要绑定一致。`production/tasks/fool-s00-card-agentic-v1.json` 的 narrative `sha256` 因 S00 文案变更同步更新；`artifacts/production/**` 的历史回执按不可覆盖原则**保持原样**。

## D16｜十一卡「收藏转正式」与内容核验解耦（批准 ≠ 发布）
原因：用户裁决「已经验收通过，所有卡，变为正式」，并明确三点边界：① 转正范围为 App 现有十一张；② 深度只转状态与批准记录，不执行 ADR-003 最终采样、不产出 2K/4K；③ 素材基线一并转正。此前批准态只有「候选」一档，且 App 把「正式收藏」与「内容已核验」耦合成同一判据，导致「用户已批准」无法表达。
结果：
- **批准模型（Oracle 复核后定稿）**：批准 ≠ 发布。视觉批准写入独立人类 sidecar `production/approvals/fool-card-visual-approval-v1.json`（`kind: visual_approval_sidecar`，`visual_approved: true`、`release_approved: false`、`sampling_executed: false`，绑定十一张卡图与九份 provenance 的 sha256）；九张非序列卡另建聚合记录 `production/cards/fool-nonsequence-card-approvals-v1.json`（`kind: card_approval_aggregate`、`sequence_slots: false`），因为序列候选清单 `fool-card-candidates-v1.json` 的门禁要求 `sequence ∈ {0,9}` 且有 task/receipt，非序列卡不能塞进去。
- **状态词汇**：`CARD_MANIFEST_STATUSES = {candidate-pending-user-visual-review, user-visually-approved}`；`CARD_APPROVAL_STATUSES = {pending, approved}`；最终采样队列采用 `approved-for-final-sampling` 且必须 `sampling_executed: false`。所有 `formal_release_approved`／`release_approved` 保持 `false`（无交付像素）。
- **门禁**：新增 `validate_fool_nonsequence_card_approvals` 与 CLI `check-fool-nonsequence-cards`；`validate_fool_cards`／`validate_fool_finalization_manifest`／`validate_fool_materials` 由「拒绝一切非 pending」改为「校验批准来源」——必须读取独立人类 sidecar 并逐卡比对哈希，`approved` 不得由清单自证。反例测试见 `tests/test_fool_card_validation.py`（新增 8 条）。
- **不可覆盖**：`artifacts/production/**` 的 provenance 与历史回执不改写；材料基线的 `basis` 只记录本次批准依据，不构成发布批准。
- **App 解耦**：`AlbumViewModel.visibleCards(.formal)` 与 `formalCount` 只按 `collectionIntents == .formal` 过滤，不再要求 `contentStatus == .confirmed`；`ArchiveCopy.pathwaySummary(formal:candidate:)` 改为收藏口径。十一张卡的 `collectionIntent` 由 `.candidate` 改为 `.formal`，而 `contentStatus` 保持 `.proposed`——**用户批准视觉与收藏身份不等于内容已核验**，九位「序列之上」的资料仍是二手/未核验。「我的收藏」副标题改为「你正式收藏的身份卡；每张卡的内容核验状态以卡片自身的标注为准。」；测试加断言 `confirmedCount == 0` 与九卡 `.proposed`，防止后续误升。另移除 fixture 中 S00 的 `isWishlisted`：十一张卡均归入正式收藏后，愿望清单为空（分栏与指标保留给后续新增目标，断言改为显式空集而非删除）。

## D17｜纳入《诡秘世界》母 PRD 作为未来产品基线（内容/引擎分层）
原因：用户提供《诡秘世界》产品需求文档 PRD v1.0（本地 `~/Downloads/诡秘世界_PRD_v1.0.md`，2026-09-15），并要求纳入项目。该文件定义的是以本卡牌体系为 Canon 底座的**单人持续世界演绎产品**（World/Character/Story/Audio 引擎 + 持久世界 + Story Book），量级远超本仓库当前交付面（卡牌内容生产 + M1 客户端垂直切片）。若把 PRD 直接当作本仓库规范，会与既有事实源、卡牌契约与批准边界混淆。
结果：
- 入仓为 `docs/product/secret-world-prd-v1.0.md`：**正文逐字未改**（sha256 `bc2c04057e4686904c8665750b7be45693197d9857c0ffed2de9054df555c62c`，等于源文件哈希），仅前置来源/效力/实现状态说明块。
- 效力＝**产品基线·立项级**：约束**未来**实现；对本仓库现有交付面**不是规范**，不覆盖 `pathways/*/card.json`、`canon.json`、`sources/registry.json`、`config/`，不构成任何 `approved`/`release_approved`，不改变卡牌数量与卡槽口径（220 是卡槽基线，不是上限）。
- 分层边界（PRD §25）：World/Story/Character/Audio 引擎**不进入**卡牌美术仓库；本仓库继续只承担卡牌内容生产与 M1 客户端，引擎实现属另一交付面，需另行立项。
- 路由与效力已同步：根 `AGENTS.md`（概览/结构/查哪里）、`docs/AGENTS.md`（效力地图/约定/反模式/状态分类）、`docs/LIMITATIONS.md`（未实现清单）。
- PRD 附录 A 的 15 份工程契约与附录 B 的拆分 PRD **均未创建**，不在本决策范围内；尚未确定引擎代码归属的仓库或目录。

