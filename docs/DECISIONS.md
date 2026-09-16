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

## D18｜项目更名为《诡秘世界》：英文名、仓库名与标识方案
原因：用户裁决本项目后续演进为《诡秘世界》（以本卡牌体系为 Canon 底座的单人持续世界应用），App 同步更名。需要为「本地项目名 + GitHub 仓库名」定下唯一命名方案，并明确哪些标识**不得**随名迁移。
结果：
- **命名（已采纳）**：显示名 **诡秘世界**；英文名 **World of Mysteries**；GitHub 仓库 `hrygo/world-of-mysteries`（原 `lotm-card-art`，2026-09-15 改名，旧 URL 由 GitHub 重定向）；bundle id 规划 `com.hrygo.world-of-mysteries`；bundle 目录规划 `WorldOfMysteries.app`；App 模块规划 `WorldOfMysteries`；**未来引擎模块保持 IP 中性**（`WorldEngine`/`CharacterEngine`/`StoryEngine`/`AudioEngine`），不挂产品名（依 PRD §25 引擎与内容解耦）。
- **取舍依据**：`Secret World` 因与 Funcom「The Secret World」/「Secret World Legends」**同行业同题材商标重叠**而排除（该商标声明见 secretworldlegends.com 页脚）；`World of Mysteries` 与原著官方英文名 *Lord of the Mysteries* 同构，回译「诡秘世界」稳定。
- **本批已完成**：根 `README.md`、根 `AGENTS.md`、`SECURITY.md`、`.github/ISSUE_TEMPLATE/config.yml`、`config/project.json` 的 `project_id`，以及 GitHub 仓库名与本地 remote URL。
- **不得随名迁移（稳定标识）**：（1）内容 ID 命名空间 `lotm.*`（403 文件 / 1089 次）——批准 sidecar 与 provenance 按 `card_id` + sha256 绑定，改名会作废全部批准与哈希链；（2）`production/schemas/*.json` 的 `$id`（内容层 schema 命名空间）；（3）项目技能名 `lotm-*`；（4）小说与 IP 引用：`小说《诡秘之主》`、canon 序列名「序列之上·诡秘之主」、法律归属段落。
- **分批计划**（含 Keychain 与 `Application Support` 配置路径的**阶梯迁移**、安装包迁移、历史文档不回写、引擎目录分层）见 `docs/superpowers/plans/2026-09-15-rename-to-world-of-mysteries.md`（Agent 生成提案）。本轮只执行「项目名与仓库名」部分，未改任何代码。
- **补充（2026-09-15，用户裁决）**：App **展示名称使用中文「诡秘世界」**。落地：bundle 目录改为 `.build/诡秘世界.app`（原规划 `WorldOfMysteries.app` 作废）；`CFBundleDisplayName` 与 `CFBundleName` 均为「诡秘世界」；新增 `Resources/zh-Hans.lproj/InfoPlist.strings`、`CFBundleDevelopmentRegion=zh_CN`、`CFBundleLocalizations=[zh-Hans,en]`，并由 `scripts/build-app.sh` 显式拷入 `.app`（无 `.lproj` 时菜单栏名称会回落到进程名，故本地化文件是必需品而非装饰）。**`CFBundleExecutable` 与 SwiftPM 模块名保持 ASCII `WorldOfMysteries`**：进程名、日志、构建产物与脚本路径不受中文影响。安装路径为 `/Applications/诡秘世界.app`。

## D19｜以文档确立分层、放弃物理迁移（单仓库组织的落地方式）
原因：用户要求「依据最新 PRD 重新组织项目文档；制作卡片的能力已经仅仅是本项目的一部分」，并裁决《诡秘世界》采用单仓库架构。原规格 `docs/superpowers/specs/2026-09-15-monorepo-layout-and-layering-design.md` 提出把 `pathways/`/`catalog/`/`sources/` 搬入 `content/`、清空 git 历史、并把封存 pin 从路径主键演进为内容寻址；经**对抗式审查**（oracle 技术风险 + Metis 歧义/AI 失败点 + 独立实证复核）判定**在现行治理下不可执行**，且该迁移服务于工程意愿而非用户提出的文档准确性痛点。
结果：
- **决策**：不搬动任何目录、不清空或重置 git 历史、不改动 `tools/production.py`、`tools/pin_seal.py`、`production/schemas/*.json`、`.agents/skills/**`；改以**文档**确立分层。落点为 `docs/decisions/ADR-006-docs-first-layering-no-physical-migration.md`（ADR 编号：ADR-005 已被 `carrier-geometry` 占用，故记为 006）。
- **新增**：`docs/architecture/layering.md`（全部顶层目录的层归属与依赖规则的**单一说明**，并显式声明「**未机器强制**」）；`packages/README.md`（IP 中性引擎层契约**占位**，无实现代码；「引擎层无违规引用」当前是空真）。
- **文档改为产品优先**：根 `README.md`、根 `AGENTS.md`、`docs/AGENTS.md` 不再把本仓库描述为「卡牌制作脚手架」，改为《诡秘世界》前置工程，三个面（内容生产面、客户端面、**未实现**的引擎面），制卡是**内容层的一个子域**。
- **不可执行的理由（均代码/文件级实证）**：① `narrative_digest`（`production.py:1784-1789`）把 `evidenceRefs[].path` 计入哈希，`validate_narrative`（L1792-1817）要求已批准条目 `contentDigest` 与 `approvedDigest` 双等于该摘要 ⇒ 改路径即令批准失效，唯一过门禁方式是**覆写人类批准摘要（伪造批准）**；② `production/schemas/task.schema.json` 对 `contracts.items`/`narrative`/`references.items`/`protagonist.evidence_refs.items` 四处为 `additionalProperties:false` + `required` 含 `path`+`sha256` ⇒ 新增 `content_hash` 或令 `path` 可选**直接校验失败**；③ `pin_seal._reseal_text` 的 `updated.count(digest)!=1` 会因双写同值中止，且 `MASK_RE` 只遮蔽 `"sha256"` ⇒ 字节保全断言对 `content_hash` 是盲区；④ `artifacts/**` 的 **52** 份 `snapshot.json` 共 **367** 条依赖记录 `tools/production.py` 等哈希，而路径同步**必须**编辑该文件，`artifacts/**` 不可覆盖 ⇒ **无合规修复路径**；⑤ 上述依赖中**已有 76 条指向不存在路径**（既有债，含已按 D10 移除的 SOP v1/v2 与已移入 Trash 的旧链 `raw.png`），且 `selfcheck.py` 与 CI 都**不调用** `gate`，长期无人发现；⑥ 原规格同步范围**漏 `tests/**`**（14 处硬编码旧路径，5 个文件）与 `.github/**`。
- **未来若仍要迁移**：前置条件清单见 ADR-006 Decision 6（a–f：摘要与路径解耦、开放闭合 schema 并配反例、处置 snapshot 依赖并先修已断 76 条、门禁接入 selfcheck 与 CI、定义唯一 git 基线并演练 bundle 还原与导出 GitHub 独有数据、同步范围含 `tests/**` 与 `.github/**`）。
- **本次验证**：改动仅限文档与新占位目录。`python3 tools/pin_seal.py --check` 退出 0（113 条通过）；`python3 tools/cardctl.py check --level scaffold` 退出 0；`python3 -m unittest discover -s tests` 退出 0（184 tests OK，skipped=6）。
- **补充（2026-09-15，用户裁决）**：确认「以『单仓库架构 ⇒ 引擎层落在本仓库 `packages/`』为准」。即：就**引擎代码归属**而言，本决策、`ADR-006` 与 `docs/architecture/layering.md` **优先于** D17 / 母 PRD §25 的「引擎不进入本仓库、需另行立项」措辞；§25 的实质要求（引擎与内容解耦、IP 中性）由 `packages/README.md` 的硬契约承接。引擎**仍未实现**，相关里程碑仍阻塞于引擎立项。变更须由用户新的明确裁决，详见 ADR-006「与 D17 / 母 PRD §25 的关系」。

## D20｜创建《macOS UX / Interaction PRD》拆分 PRD，并实现 M2 世界外壳（示例世界）
原因：用户要求「结合母 PRD 与本机 macOS 现状，先创建《macOS UX / Interaction PRD》，然后实现」。母 PRD 附录 B 列出的第 6 份拆分 PRD 此前**不存在**（D17 明确记录「附录 A 的 15 份工程契约与附录 B 的拆分 PRD 均未创建」），而客户端只有 M1 的「卡牌」一条链路；若直接实现，界面目标只能靠母 PRD 的长文条款临时解释。
结果：
- **新增拆分 PRD**：`docs/product/macos-ux-interaction-prd-v1.0.md`（`draft-for-review`，Agent 依据母 PRD §13/§14/§15/§18/§19/§20/§21/§24/§27–§31 与 `apps/WorldOfMysteries` 现状起草，待用户确认后升为 v1.0 基线）。效力：只约束客户端**界面与交互**；不构成引擎立项、不构成任何内容批准或视觉批准，不覆盖 `pathways/**`、`config/`、`production/**`、`artifacts/**`。
- **里程碑映射写入 PRD**：M1 已实现（画廊 / 详情 / 故事抽屉 / SpeechRail）；**M2「世界外壳」= 本轮实现对象**（不需要引擎）；M3 命运闭环、M4 声音优先、M5 故事书完整化**阻塞于引擎立项**——D17 的内容/引擎分层边界**未改动**，本仓库仍不实现 World / Character / Story / Audio 引擎。
- **客户端实现 M2 世界外壳**（`apps/WorldOfMysteries`）：新增四个并列一级区域（世界 / 卡牌 / 人物 / 故事书）与区域内独立选中项；世界首页七个分区（世界状态头、最近事件、进行中的命运、最近活跃人物、未解决事件、地点变化、最近完成的故事）与空态；人物按 `character_id` 聚合身份卡，分开展示身份切片 / 本机经历 / 关系（区分原著事实与本机经历）/ 该人物自己知道的事；故事书命运详情含阅读模式、聆听模式（转入既有故事播放）、命运记录、秘密计数、关系变化与世界影响；卡牌详情新增命运入口（措辞随身份类型变化，真神与「序列之上」用「以祂的尺度介入世界」）与命运生成界面（只呈现时间/地点/异常/压力四项可见种子）。
- **示例世界边界**：世界数据来自 `SampleWorld`（合成示例世界），只存在于 App 进程内，**不写入** `pathways/**`、`canon.json`、`sources/registry.json`、`artifacts/**` 或任何批准记录；世界 / 人物 / 故事书三处持续显示「示例」标记与说明，该标记不得因界面完成而移除。
- **约束落入测试而非口头约定**：命运生成界面只暴露四个可见种子字段（且不含「秘密」「结局」等幕后词）；未揭开秘密的 `revealedText` 恒为 nil；叙事状态提示为句子且不含 ASCII 数字、不出现 `spirituality`/`exposure` 等变量名；新增用户文案通过内部术语黑名单；九位「序列之上」存在使用「祂」且无本机经历。
- **本次验证**：`swift build` 退出 0；`swift test` 142 tests / 0 failures（`WorldDomainTests` 17 条、`WorldShellTests` 28 条）；`./scripts/build-app.sh debug` 退出 0，产物 `.build/诡秘世界.app` 为 `LSMinimumSystemVersion=26.0`、`arm64`；`python3 -m unittest discover -s tests` 184 tests OK（skipped=6）；`python3 tools/selfcheck.py` 5/5 通过（当次 selfcheck 只有 5 步；D21 接入设计 token 步骤后为 6 步，见 D21「门禁接入」）。
- **实机观察（补充）**：2026-09-15 17:00–17:15 以窗口截图＋可访问性树逐区观察了四个区域、命运生成界面与高位存在卡面（记录见 `apps/WorldOfMysteries/docs/qa/m2-world-shell.md`）。这是 Agent 的实机观察，**不是**用户视觉批准；D16 的批准口径不变。
- **观察中发现并修复**：命运详情的阅读模式原先直接渲染卡片叙事的固定章节，导致进行中的命运显示尚未发生的段落、同卡两段命运段落重复。已改为「命运自己的段落优先，缺失时才回退到卡片叙事并明示来源」：`EpisodeRecord` 增加 `recordedPassages`，新增 `EpisodeReadingResolver`，示例世界为三段命运各写独立段落；PRD §3.7 与 §9.1 同步写明该口径，并新增防回归断言。
- **用户报告后的追加修复（2026-09-15 19:35）**：用户报告「左侧菜单点击时灵时不灵」。代码层定位到四处命中缺陷：装饰层（悬停描边 + 越界的焦点环）未退出命中测试、`contentShape` 声明在装饰之前、侧边栏行只在标签层之外声明命中区域（圆角与留白点不动）、`SidebarTactileButtonStyle` 按下缩放 0.96 会把命中几何一起缩小（贴边按下即作废）；此外选中行的 `.interactive()` 材质在按钮内部自带指针响应。已分别改为装饰层 `.allowsHitTesting(false)`、`contentShape` 后置、三个侧边栏行在标签层声明整行矩形、按下反馈改亮度/不透明度（同类行级样式 `ShellRowButtonStyle` 一并改）、侧边栏行材质去掉 `.interactive()`；PRD 新增 §4.6「命中与反馈」把四条写成规范。**未做真实鼠标验证**（应用窗口被其它应用遮挡，合成点击到不了侧栏），实测由用户完成；记录见 `apps/WorldOfMysteries/docs/qa/m2-world-shell.md`。
- **安装**：2026-09-15 17:36 将 release 产物安装到 `/Applications/诡秘世界.app`（旧的 13:18 构建先移入废纸篓，可恢复；`build-app.sh` 本身不写系统目录）。安装后启动实测通过，视觉测试由用户进行。
- **未完成（如实记录）**：**用户视觉批准与 VoiceOver 朗读走查未做**。Agent 的屏幕观察不能代替用户判断，也不得以构建、测试或截图冒充视觉验收。因此本轮的界面改动**不得**被表述为已通过视觉验收。
- **未改动**：内容生产面（`pathways/**`、`production/**`、`artifacts/**`、`schemas/`、`tools/`）与任何批准状态；引擎相关目录仍为空占位。

## D21｜建立全局设计 token：单一事实源 + Figma 生成器 + 客户端遵守
原因：用户要求「建立全局设计 token 并遵守」，并在发现初版做法跑偏后指定参考其他项目（SpeechRail）**真实的 Figma 使用方式**——先在 Figma 里建立变量与文字样式，而不是把数值直接塞进代码。
结果：
- **事实源**：新增 `config/design-tokens.json`（v1.0.0；当前 color 71 / space 27 / radius 17 / stroke 4 / type.size 18 / size 8 / motion / material）。色值取自客户端原有 `ArchiveTheme.swift` 的真实数值，并补齐 `DivineFoolArtworkView` 里两个未 token 化的字面量，不凭空发明配色。后续两轮各补一个「既有像素值的 1:1 登记」：`space.60`（装订棱高度）、`radius.ridge` 1.5（凸棱圆角），都不是新设计。
- **两个投影**：`python3 tools/design_tokens.py generate` 写出 `apps/WorldOfMysteries/Sources/WorldOfMysteriesFeatures/DesignTokens.generated.swift`（客户端）与 `design/figma-kit/tokens.js`（Figma 生成器数据）；两侧均为生成物，命名规则 `a.b-c → aBc`。
- **客户端遵守**：11 个 Features 文件中的色值/字号/间距/圆角/描边/动效时长/弹簧改为引用 `DesignTokens.*`；颜色仍经 `ArchiveTheme` 语义层，避免 500+ 调用点直接依赖调色板。合同见新增的 `design/design-tokens.md`。
- **Figma 侧**：新增 `design/figma-kit/`（`manifest.json` + `main.js` + `build.js`）。`node design/figma-kit/build.js` 在跑完冒烟测试后把 `tokens.js + main.js` 合成 `code.js`，连同清单落到 `~/Downloads/mysteries-figma-kit/`（用 ASCII 目录名：中文路径会卡住 Figma 的清单选择器，实测）。Figma 桌面产出经实测为：变量集合「诡秘世界」（单 mode `Dark`）COLOR 71 + FLOAT 75、`type/*` 文字样式 10 条、`00 Foundations` 页面（色板 71 张且全部绑定变量）、自检问题 0；设计文件命名为「诡秘世界 · Design Tokens」。
- **检查**：`python3 tools/design_tokens.py check` 校验①两份投影与事实源逐字一致 ②客户端字面量分两档：**有刻度**的类别（字号、内边距/轴内边距、堆叠与弹性间距、圆角〔`cornerRadius:` 与 `.cornerRadius(_)` 两种写法〕、描边、等于某个 `size` token 的 `width/height/min*/max*`）出现字面量即失败；**尚无刻度**的类别（不透明度、阴影半径、模糊半径、位移、其它结构尺寸）按新增的 `config/design-token-baseline.json` 冻结——基线外的新取值失败、删减放行，改基线必须显式跑 `python3 tools/design_tokens.py baseline` 且 diff 在评审里可见 ③Figma 生成器里 10 条 `type/*` 用到的字号/字重/行高都在 config 里（负例实测会报错，不是空跑）。`node design/figma-kit/build.js` 用 figma stub 在 Node 里跑完整流程，并复刻两条**实测踩到过**的 Figma 契约：插件沙箱是严格模式（未声明标识符直接 `ReferenceError`）、任何 `fontName` 赋值前必须 `loadFontAsync`——这两条此前都真实导致过插件失败。
- **门禁接入（本轮补）**：设计 token 此前只靠人记得跑，等于自觉行为。现接入两处：`tools/selfcheck.py` 新增 `design-tokens` 步骤（`scaffold → pin 漂移 → 设计 token → 愚者门禁 → 全套单测`，共 6 步），CI 的 Python job 新增 `python tools/design_tokens.py check`（macOS job 未加，客户端侧仍有 `swift test`）。反例测试从 13 条扩到 17 条，新增覆盖 `.cornerRadius(1.5)` 修饰符写法、基线外新取值被拒、已登记取值放行与超出计数被拒。
- **与内容生产面解耦**：`config/quality-color-tokens.json`（五档边框生产配色）不受影响；本文件的 `tier.*` 只是客户端图鉴档位标签/发光色，二者在合同里显式区分。
- **安装**：2026-09-15 18:16 将 release 产物安装到 `/Applications/诡秘世界.app`（旧的 17:36 构建先移入废纸篓，可恢复；`build-app.sh` 本身不写系统目录）。构建前 `swift test` 142 tests / 0 failures。
- **未完成（如实记录）**：视觉判断仍由用户进行，Agent 的截图与插件自检面板**不构成**视觉批准（D16 口径不变）；Figma 生成器未接入 CI，真实产出需要 Figma 桌面手动运行。
- **未改动**：`pathways/**`、`production/**`、`artifacts/**`、`schemas/`、卡牌契约与任何批准状态；`design/figma-kit/` 的生成物不写回仓库。

## D22｜卡图解码离开主线程：详情不降质，网格瓦片降采样，玻璃合并渲染
原因：用户报告「卡牌和人物页面打开卡顿」「必须优化性能，现在才多少卡啊」，并给出硬约束「**不降低打开单卡品质**」。
结果：
- **根因（代码层定位，非猜测）**：`BundledArtworkView.body` 里直接 `NSImage(contentsOf:)`。`NSImage(contentsOf:)` 只建立文件引用、**不解码**；解码被推迟到绘制（帧提交路径）。且每次 `body` 重新求值都新建 `NSImage`，同一张卡的解码被反复支付。
- **实测（本机 Apple silicon，App 内 11 张真实卡图 1024×1536）**：`CGImageSourceCreateImageAtIndex` 带 `kCGImageSourceShouldCacheImmediately` 时创建 **20.5 ms/张**、之后首绘 1.9 ms/张；不带该选项时创建 0.07 ms/张、首绘 **21.3 ms/张**（对照组，证明解码确实被推到绘制）。旧路径画册一屏 11 张 **282–296 ms 主线程**，再渲染两次 **502–525 ms**；打开单卡一张 **23.4–23.8 ms**（绘制到 460×690）/ **57.5 ms**（绘制到 920×1380 的 2x 背板）。
- **决策①（品质）**：**详情大图档 `thumbnailMaxPixel = nil`，按源图分辨率解码，不设缩略图上限**——这是用户硬约束，写成 `ArtworkStoreTests` 的断言，任何把详情档降采样的改动会直接测试失败。允许降采样的只有网格瓦片档（长边上限 1024px，网格内显示约 273pt 宽）。实测详情档 1024×1536 与源图逐张一致（不一致 0 张）。
- **决策②（位置与次数）**：新增 `apps/WorldOfMysteries/Sources/WorldOfMysteriesFeatures/ArtworkStore.swift`：解码全部走 `Task.detached`，主线程只同步读 `NSCache`（实测 11 次命中 0.002 ms）；每张每档只解一次，并发请求共用同一份解码结果；启动预热（先瓦片档、后详情档），详情档预热张数设上限、超出后按需后台解码，避免常驻内存随卡数线性增长。
- **决策③（玻璃）**：画册网格与人物档案分别套 `GlassEffectContainer` 合并渲染；**容器 `spacing` 必须小于内部布局间距**（此处取 8pt，内部为 16pt / 20pt）。依据 Apple 文档「A spacing value on the container that's larger than the spacing of an interior HStack/VStack … causes Liquid Glass effects to blend together at rest」——取大于或等于间距的值会让相邻卡面/面板在静止时融合成一片，属视觉正确性问题。
- **决策④（瓦片发光）**：网格瓦片的离屏模糊（`.blur(radius: 24)` ×11）改为同层径向渐变。已核对这**不改变当前 11 张卡的可见像素**：CardArt PNG 逐张 `sips -g hasAlpha` 均为 `no`，且卡图以 `scaledToFill` 铺满卡面区域，发光层被不透明卡图完全遮住。详情页发光保持原样（`.blur(radius: 44)`，未替换）。
- **契约落点**：PRD 新增 §4.7「卡图解码与开页面性能」（含「body 不得读文件/解码」「每张每档只解一次」「详情不降采样」「容器 spacing < 内部间距」五条）与 §9.1 第 10 条机器可断言项（卡图档位与缓存），使这份用户约束不依赖口头约定。
- **本次验证**：`swift test` 150 tests / 0 failures（新增 `ArtworkStoreTests` 8 条）；`python3 tools/selfcheck.py` 6/6；`python3 tools/design_tokens.py check` 退出 0；`python3 -m unittest discover -s tests` 201 tests OK（skipped=6）；`./scripts/build-app.sh release` 退出 0，20:39 安装到 `/Applications/诡秘世界.app`（旧 20:14 构建移入废纸篓，可恢复；安装产物与 `.build` 产物逐字节一致）。记录见 `apps/WorldOfMysteries/docs/qa/m2-world-shell.md`。
- **未验证（如实记录）**：**没有端到端真机帧时间测量**——采样期间 App 窗口被最前面的全屏应用完全遮住，被遮挡窗口会被系统跳过合成，`sample` 数字只能当**下限**，故本轮改用同机同进程的确定性微基准说明成本挪动（数据见上）。**人物页卡顿没有独立实测**：人物页无卡图，成本在视图图重建与逐面板玻璃采样，本轮只做玻璃容器化；是否明显变快须由用户实测。**玻璃容器化的净收益未测**，取小 spacing 保证的是不产生视觉融合，不是性能结论。视觉判断仍由用户进行（D16 口径不变）。
- **未改动**：内容生产面（`pathways/**`、`production/**`、`artifacts/**`、`schemas/`、`tools/`）与任何批准状态；客户端仅新增上述卡图缓存与玻璃容器化。
- **补充（2026-09-15，D23 落地）**：决策①的**意图不变**（打开单卡不降品质），机制已换成「打包时就把显示尺寸做成成片」。因此客户端里 `ArtworkVariant.thumbnailMaxPixel` 与运行时的缩略图解码**已不存在**；详情档改为读打包生成的 hero 成片（母版长边不超过 1536 时与母版同像素），瓦片档读 tile 成片（长边 1200 → 800×1200，比原来的 683×1024 更大）。决策②③④未变。

## D23｜卡图交付改走打包成片：App 内不放母版，运行时零图像处理
原因：用户报告「卡牌和人物页面打开卡顿」后追加要求「调研最佳实践，怎么解决多图高清，速度问题」，并在调研稿交付后指示「按照调研最佳实践处理」。调研结论（`docs/research/2026-09-15-client-image-delivery-and-decode-research.md`）指出：**「多图 + 高清 + 快」不能靠运行时把大图缩下来解决**——本机实测同一张 2048×3072 用 ImageIO 现缩到 800×1200 要 **65.8ms**，而直接读一张 800×1200 的成片只要 **2.7ms**；PNG 的缩略图解码甚至比全尺寸还慢（65.8 vs 59.6ms）。D22 只是把这条成本挪到后台，没有消掉它。
结果：
- **决策**：**App 内不放母版**，只放「按显示尺寸已经做好的成片」；每一档在**打包时**从 `artifacts/**` 的母版生成，**运行时零图像处理**（不缩放、不重编、不读 PNG 母版）。母版仍是唯一真源，交付规格（ADR-003 的 2K/4K PNG）**不变**。
- **落点**：挂在现成的 `tools/production.py stage-app-resources`（`validate_fool_audio_package`）里，原先把母版 PNG 拷进 `.app` 的那一步换成 `stage_app_card_art`；`artifacts/**` 不写回、不新增第二份资源登记表。
- **档位（`APP_IMAGE_TIERS`）**：tile 长边 **1200**（源 1024×1536 → **800×1200**）JPEG q85；hero 长边 **1536**（→ **1024×1536**，与母版同像素）JPEG q88。**只缩不放**：`long_edge = min(档位, 母版长边)`。任何一档低于 `APP_IMAGE_DISPLAY_MINIMUM_LONG_EDGE = 960`（由显示需求推出：详情卡面 320×480pt → 2x = 640×960；网格瓦片按 320pt 计）直接判错。
- **为什么不取调研稿的 640×960 / 800×1200**：那两个数值低于改动前的实际解码尺寸（瓦片 683×1024、详情 1024×1536），与用户硬约束「不降低打开单卡品质」冲突。取「不低于改动前实际解码尺寸、只换编码不降像素」，品质只增不减，速度收益全部来自编码（JPEG 解码比 PNG 快约 6 倍）。
- **列宽上限**：新 `albumTileMaxDisplayWidth = 400`（= tile 成片 800px ÷ 2）并接到画册网格四列的 `GridItem(.flexible(minimum:maximum:))` 上——调研稿 §3.2「**先给瓦片设上限，再定档**」。实测窗口 1576×971pt（`CGWindowList`）：四列时列宽约 **293pt**、卡面约 **269pt**（2x 需 539px，成片 800px，余量 1.48×），上限**当前不生效**；按 `(窗口宽 − 侧栏 266 − 内边距 72 − 列间距 48) ÷ 4 ≤ 400` 反解，窗口宽超过约 **1986pt** 才开始收敛列宽（5K/6K 屏幕上会出现，届时瓦片仍不会被拉过 800px 成片）。`tests/test_app_image_staging.py::test_grid_column_cap_stays_within_the_tile_tier` 反查客户端常量与打包档位是否自洽。
- **打包成本**：11 张卡 × 2 档一次性 **1.1s**（`sips`，单张 2K → 800×1200 约 0.09s）；生成用系统 `sips`，本机实测其缩放结果与 CoreGraphics `interpolationQuality = .high` **逐像素一致（最大差 0）**，故不需要在 Python 侧引入第三方依赖（`tools/AGENTS.md` 的标准库约束不受影响）。
- **包体**：`CardArt` 由约 33MB PNG 降到 **15.22MB**（tile 5.75MB + hero 9.48MB，22 个文件）；`.app` 总量 60MB。按每张约 1.4MB 推算，220 张约 **300MB**（现状规格直接进包会是 1.5GB 量级），符合调研稿给出的量级判断。
- **缓存与内存**（调研稿 §3.5 / §3.7）：两档都改为按**字节成本**限流（tile 96MB、hero 128MB；同一张两档差约 10 倍，只按张数限流会失控），并新增内存压力响应——收到 `DispatchSourceMemoryPressure` 的 warning/critical 就整体丢弃解码结果（重解一张瓦片只要几毫秒）。**两档预热都设张数上限 24**（`tilePreloadLimit` / `heroPreloadLimit`）：卡数上来之后逐张预热全部瓦片，只会让刚解好的图被成本限流立刻淘汰，改为滚动到跟前时按需后台解码。今天 11 张卡时这条上限不生效。
- **契约落点**：UX/Interaction PRD §4.7 改写为「App 只读打包成片、运行时零缩放、档位由 `APP_IMAGE_TIERS` 定义、任何档位不得低于显示需求下限」；`apps/AGENTS.md` 的卡图条目同步。
- **本次验证**：`swift test` **152 tests / 0 failures**（`ArtworkStoreTests` 10 条，含「丢弃缓存后重新解码」与两条预热上限）；`python3 -m unittest discover -s tests` **209 tests OK（skipped=6）**；`python3 tools/selfcheck.py` **6/6**；`python3 tools/design_tokens.py check` 退出 0；`python3 tools/pin_seal.py --check` 113 条通过；`./scripts/build-app.sh release` 退出 0，**21:45 安装**到 `/Applications/诡秘世界.app`（旧的 20:39 / 21:33 两次构建依次移入废纸篓 `~/.Trash/诡秘世界-20260915-2133-pre-image-derivatives.app`、`~/.Trash/诡秘世界-20260915-2145-pre-preload-cap.app`，均可恢复；安装产物与 `.build` 产物逐字节一致，sha256 `bbb60a4a…107d`）。**端到端校验**：以与 `ArtworkDecoder` 逐字一致的 Bundle 查表方式对**已安装的 App** 解码 11 张 × 2 档全部命中（两次复测分别 111.1ms / 99.5ms，首次冷启动约 20ms，其余 3–7ms；负例「不存在的资源名」查不到）。**窗口实测**：1576×971pt，四列时列宽约 293pt、卡面约 269pt（`CGWindowList` + 窗口截图逐列扫描）。机器观察见下方 QA 记录。
- **未完成（如实记录）**：**没有用户视觉批准**。JPEG 是有损编码，属于可见变化的改动，按 D16 只能由用户在最暗渐变、最细金饰、最亮高光三处做 1:1 对比后确认；Agent 的抽查与截图（`gold crop` / `mid crop` 按显示尺寸比 MAE 分别 6.46 / 4.45）**不构成**视觉批准。**没有端到端真机帧时间**（D22 的采样限制不变）。**220 张规模未实测**：包体与内存都是按单张实测值外推。
- **未改动**：`config/production-resolution-policy.json` 与 ADR-003（母版交付规格不变）、`artifacts/**`、`pathways/**`、`production/**`、`schemas/` 与任何批准状态。本决策只改变**App 包内**的卡图形态。

## D24｜回归纯卡牌制作职责：仓库名改回 `lotm-card-art`
原因：用户裁决「这个仓库将来要修改，改回卡牌制作工作的纯粹职责」，并要求项目文档的身份描述一并改回（「项目文档 agent.md 等都改为，但 app 本身暂时保留」）。D18/D19 曾把本仓库身份改写成《诡秘世界》单仓库前置工程，其前提是「制卡只是本仓库内容层的一个子域」；该前提与新的职责界定相反。
结果：
- **仓库名**：`hrygo/world-of-mysteries` → **`hrygo/lotm-card-art`**（2026-09-16；GitHub 仓库 id `1367408361` 不变，commit/PR/issue 全部保留，旧 URL 由 GitHub 重定向）。本地 `origin` 与 README badge 同步。
- **本地路径**：`/Users/hrygo/Documents/world-of-mysteries` → `/Users/hrygo/Documents/卡牌制作工具`；旧路径留软链接（可随时删除，仅为兼容按旧路径寻址的会话与任务）。
- **身份回写（仅文档层）**：根 `README.md`、根 `AGENTS.md`、`NOTICE.md`、`CONTRIBUTING.md`、`SUPPORT.md`、`docs/AGENTS.md`、`docs/architecture/layering.md`、`apps/AGENTS.md`、`.github/ISSUE_TEMPLATE/config.yml`、`SECURITY.md`。措辞口径参照 D18 之前的版本（`4ba698f~1`）并适配当前目录结构。
- **保留面界定**：`apps/`、`packages/`、`docs/product/` 与客户端 Token 投影（`config/design-tokens.json`、`design/figma-kit/`）标为**保留面**——归属《诡秘世界》产品（仓库 `hrygo/WorldofMysteries`），在本仓库暂存、不再扩写，并从身份描述中移出交付主线。
- **app 保留**：用户明确「app 本身暂时保留」，故 `apps/WorldOfMysteries` 不摘出、不迁移、不删改；D22/D23 的卡图解码与打包成片决策对其继续有效。物理迁移若将来要做，仍以 ADR-006 Decision 6 的前置条件（a–f）为前提。
- **未改动（边界）**：`pathways/**`、`production/**`、`artifacts/**`、`schemas/**`、`tools/**`、`config/project.json` 与任何批准状态。D19「不搬动目录、以文档确立分层」的结论**继续有效**——本次只改文档措辞，不动顶层目录。
- **待决**：`config/project.json` 的 `project_id` 仍为 `world-of-mysteries`（D18 所改）。它被 `generated/**/dependencies.json` 与 `docs/assets/illustration-backups/**` 以「路径 + sha256」引用（例如 `generated/lotm.fool.s09/dependencies.json` 记录其摘要），所以它属内容层命名空间而非展示名，回改须走 pin 重封存路径，不在本次范围。
- **历史不回写**：`DECISIONS.md` D17–D23、`docs/decisions/ADR-006*`、`docs/superpowers/**`、`apps/**/docs/qa/**` 按仓库规矩保留原文；本决策以新条目覆盖其身份描述口径。与 D17/D18/D19 的关系：覆盖 D18 的仓库命名与 D19 的身份描述部分；D17 记录的母 PRD 分层、D19 的「不物理迁移」结论不变。
- **本次验证（2026-09-16）**：`python3 tools/selfcheck.py` **6/6 步通过**（scaffold / pins / design-tokens / fool-materials / fool-cards / suite）；`python3 tools/pin_seal.py --check` **113 条通过**；`python3 tools/cardctl.py check --level scaffold` 退出 0（22 途径 / 220 卡槽）；`git rev-parse --show-toplevel` 指向新路径且 `fetch` 通过，`main...origin/main [ahead 3]` 与改名前的未推送状态一致（3 个本地提交、2 个文件未提交改动、1 个未跟踪文件均未受影响）。
- **未完成（如实记录）**：**未提交、未推送**——工作区同时存在本次改动与在途的 `AGENTS.md`／`README.md` 重排（非本次会话产生），提交边界需由用户决定；**未跑 `swift test` 与 `build-app.sh`**（本次未触碰 `apps/WorldOfMysteries` 源码，客户端侧不受影响）；**未验证**旧路径软链接在并行会话中的实际使用情况。

## D25｜main 分支保护：唯一必需检查是聚合名 `All Quality Gates Passed`，检查名按公开接口守卫
原因：用户要求「设置 main 保护」，并按 GitHub 最佳实践配置。此前本仓库 `main` **零保护**（`rulesets` 为空）：可强推、可删分支、无合入门禁。直接开启保护有一个已知坑，也是用户在此前协作中明确关切过的失败模式——**PR 永久卡在等待一个永不出现的检查**：本仓库 CI 的 Python 任务名是矩阵展开的（`Toolchain (Python 3.10) · macOS` / `Toolchain (Python 3.14) · macOS`），一旦把这种名字设为必需检查，将来调整版本矩阵就会立刻装上这条死锁引信。
结果：
- **聚合检查名**（`.github/workflows/ci.yml` 新增 `gate` 任务）：`name: All Quality Gates Passed`，`needs: [test, native]` + `if: always()`，断言上游结果全部 `success` 才通过。这个名字不含矩阵版本号，改 Python 版本矩阵不影响它；同时它把「哪几个任务算通过」从分支保护里解耦出去，矩阵怎么调都不会改必需检查名。
- **检查名契约**（`.github/required-checks.json` + `tools/check_required_checks.py`）：改 job 的 `name` 会让保护永久 pending，所以检查名按**公开接口**管理。守卫零依赖、只读，解析 `.github/workflows/*.yml` 里每个 job 实际暴露的检查名（未声明 `name` 时按 job id 回落），断言契约声明的名字都存在，并**拒绝**把 `${{ }}` 插值名当必需检查（矩阵展开会改名）。接入三处：`tools/selfcheck.py` 第 4 步（自证序列变为 `scaffold → pins → design-tokens → required-checks → fool-materials → fool-cards → suite`，7 步）、CI 的 `test` 任务（改名先在不受保护、人人都看得见的任务里亮红）、聚合 `gate` 任务（阻断合入）。反例测试 `tests/test_required_checks.py` **13 条**：改名被拒、插值名被拒、契约指向别的 workflow 被拒、空 `checks`/非法 JSON/无 `jobs` 块均报错、step 级 `name` 不覆盖 job name、本仓库契约实测成立。
- **ruleset**（声明式记录见 [`.github/ruleset-main-protection.json`](../.github/ruleset-main-protection.json)，GitHub id `23544717`）：`deletion`（禁删分支）+ `non_fast_forward`（禁强推）+ `required_linear_history`（线性历史）+ `pull_request`（必需批准 **0**、推送后作废旧批准、必须解决审查线程、只允许 squash/rebase）+ `required_status_checks`（strict：合入前必须基于最新 `main` 重跑；**唯一**必需检查 `All Quality Gates Passed`）。`bypass_actors: []` ⇒ `current_user_can_bypass = never`：管理员同样不能绕过，没有「紧急情况下我直接推」的暗门；紧急修复走 revert 或 PR，真要先改规则就显式改 ruleset（留痕）。
- **为什么必需批准数是 0 而不是 1**：单人仓库里作者无法批准自己的 PR，设 1 会让所有 PR 永久卡住——那正是本次要排除的堵点。将来多人协作再提高到 1，并在同一次改动里同步本文件、`CONTRIBUTING.md` 与 ruleset。
- **`require_code_owner_review` 保持 false**：`.github/CODEOWNERS` 只有 `* @hrygo` 一个 owner，开启等于要求本人批准自己。
- **只用 ruleset，不用 legacy branch protection**：这是 GitHub 现行推荐；因此 `GET /repos/hrygo/lotm-card-art/branches/main/protection` 仍返回 404（该端点只反映旧机制），这不代表未生效，判断依据是 `GET .../rulesets/23544717`。
- **本次验证（2026-09-16）**：`f87019c` 推送后 CI run **`35098428822` 全绿**，四个检查名全部出现（`Toolchain (Python 3.10) · macOS`、`Toolchain (Python 3.14) · macOS`、`Native renderer + client (macOS 26)`、`All Quality Gates Passed`）——先让聚合检查名在 GitHub 上真实注册一次，再开启保护，避免「保护等一个从未出现过的检查」；`python3 -m unittest discover -s tests` **222 tests OK（skipped=6）**；`python3 tools/selfcheck.py` **7/7 步通过**；`gh api repos/hrygo/lotm-card-art/rulesets/23544717` 复核 `enforcement=active`、`bypass_actors=[]`、`current_user_can_bypass=never`、`required_status_checks=[All Quality Gates Passed]`、`strict_required_status_checks_policy=true`。**实测直推被拒**：在保护生效后对本提交执行 `git push origin main`，GitHub 以 `GH013 / protected branch`（rule violations）拒绝，验证「禁止直接推送」确实生效；随后改走分支 + PR 合入。
- **未改动**：卡牌内容面（`pathways/**`、`production/**`、`artifacts/**`、`schemas/**`、`config/**`）与任何批准状态；`apps/WorldOfMysteries` 源码未触碰。
- **未完成/待决（如实记录）**：**GitHub 侧 ruleset 与本仓库声明文件不会自动同步**——`.github/ruleset-main-protection.json` 是评审与复核用的记录，改它不会改 GitHub；目前靠 `gh api` 人工同步（本仓库工具链约束「不自动联网」，故不加自动同步脚本）。**未验证多人协作路径**（无第二账号/协作者，`required_approving_review_count` 的 1 人场景未实测）。**未验证** GitHub 上「PR 缺少必需检查」的等待态在本仓库的真实手感（本轮 PR 会顺带给出观察记录）。
