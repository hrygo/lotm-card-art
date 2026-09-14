# 愚者途径 9—0 序列：魔药配方、扮演法与晋升研究

研究日期：2026-09-14  
作品范围：`lotm-volume-1-zh`，《诡秘之主》第一部中文原著  
研究状态：`research / mixed verification`  
适用对象：`pathways/fool/canon.json`、愚者途径各序列卡的研究上下文

## 1. 研究边界

本表的“魔药配方”和“晋升条件”均按“进入当前序列”记录；“扮演法”和“能力”属于成为当前序列后的性质，不能把下一序列的仪式或能力提前挪到当前序列。

来源分层：

- `verified`：当前可访问的官方中文设定集或已登记的一手中文章节片段直接支持。
- `lead`：二手百科/章节索引完整整理出的研究线索，内容可用于补齐研究草稿，但还必须由第一部中文底本逐项复核。
- `interpretation`：把已知事实转成卡面可读行为的解释，不是原著固定术语。
- `knowledge_gap`：当前范围内未取得足够证据；不表示原著没有该内容。

当前最重要的证据限制：官方中文设定集已经直接核验愚者途径 9—0 的名称、序列 0 配方、仪式和三项能力；序列 9 的主材料与克莱恩服药片段也有中文章节支持。序列 8—1 的完整辅材、部分扮演细节和高序列仪式目前主要来自二手页面，因此本文件将其记录为 `lead`，而不是静默升级为 `verified`。

来源登记见 `sources/registry.json`。当前主来源是：[起点官方设定集](https://h5.if.qidian.com/h5/workSet/main?albumId=131&bookId=1010868264)、[官方 WebNovel 第一部作品页](https://www.webnovel.com/book/11022733006234505)、[愚者途径晋升资料（二手）](https://lordofthemysteries.fandom.com/wiki/Fool_Pathway/Advancement)、[愚者途径扮演原则（二手）](https://lordofthemysteries.fandom.com/wiki/Acting_Method/List_of_Acting_Principles)。

## 2. 总览表

| 序列 | 名称 | 魔药研究状态 | 扮演法研究状态 | 晋升/仪式研究状态 |
| --- | --- | --- | --- | --- |
| 9 | 占卜家 | 主材 `verified`；辅材 `lead` | `lead`，有较完整原则 | 服药进入；无独立仪式的结论暂为 `knowledge_gap` |
| 8 | 小丑 | `lead` | `lead` | 未检得独立仪式，暂不判定不存在 |
| 7 | 魔术师 | `lead` | `lead` | 未检得独立仪式，暂不判定不存在 |
| 6 | 无面人 | `lead` | `lead` | 未检得独立仪式，暂不判定不存在 |
| 5 | 秘偶大师 | `lead` | `lead` | 美人鱼歌声中服药，`lead` |
| 4 | 诡法师 | `lead` | `lead` | 公开大型表演、杀死半神、结尾服药，`lead` |
| 3 | 古代学者 | `lead` | `lead` | 脱离现实至少三百年、成为历史后服药，`lead` |
| 2 | 奇迹师 | `lead` | `lead` | 带回被遗弃的一段历史，`lead` |
| 1 | 诡秘侍者 | `lead` | `lead` | 建造秘偶城镇并设计命运轨迹，`lead` |
| 0 | 愚者 | 主材料与辅助条件 `verified` | 独立扮演守则 `knowledge_gap`；保留解释候选 | 愚弄一次时间、历史或命运，`verified` |

## 3. 序列 9「占卜家」

### 3.1 魔药配方

状态：主材 `verified`；辅材 `lead`。中文材料名称中的英文括注用于防止译名漂移。

**主材料**

- 拉瓦章鱼血液（`Lavos Squid's Blood`）10 毫升。
- 星水晶（`Star Crystal`）50 克。
- 可替代方案：一份占卜家非凡特性。

**辅助材料**

- 纯净水（`Purified Water`）100 毫升。
- 夜香草液体/夜香草汁（`Night Vanilla Liquids`）13 滴。
- 金薄荷叶（`Gold Mint Leaves`）7 片。
- 毒芹（`Poison Hemlock`）3 滴。
- 龙血草粉末（`Dragon Blood Grass Powder`）9 克。

这里的主材与数量已有中文章节片段和官方英文译本章节定位；完整辅助材料主要由二手配方页补齐，进入正式卡面前仍需中文底本逐字核对。[中文章节研究登记](https://www.xxsy.net/chapter/9069458404256003/27841458238329534)、[官方英文 Potion 章节](https://www.webnovel.com/book/lord-of-mysteries_11022733006234505/potion_31326301566593179)、[二手完整配方](https://lordofthemysteries.fandom.com/wiki/Fool_Pathway/Advancement)

### 3.2 扮演法

状态：`lead`，可作为研究方向，不标为个人口头禅。

- 对命运保持敬畏。
- 帮助他人解读启示、引导方向，但不能因为一次占卜就自认为掌握命运。
- 保持恐惧和尊重，不傲慢、不自大、不盲信自己的解读。
- 记住占卜不是全能；不同占卜方法的适用范围和准确度有边界。

卡面回读：正在进行真实占卜、认真辨认信息、保留复核余地。不能只画水晶、星空或神秘眼睛来代替扮演原则。[扮演原则二手整理](https://lordofthemysteries.fandom.com/wiki/Acting_Method/List_of_Acting_Principles)

### 3.3 晋升条件/仪式

- 进入序列 9：获得配方和材料后服用占卜家魔药。
- 克莱恩的实际过程：在老尼尔指导下服药，获得灵视并进入非凡世界。[正典片段]
- 当前资料没有形成“序列 9 另有独立晋升仪式”的可靠结论。
- 研究记录：`knowledge_gap`，不能把“普通服药”写成复杂仪式，也不能把“未检得仪式”写成“明确没有仪式”。

## 4. 序列 8「小丑」

### 4.1 魔药配方

状态：`lead`，完整辅材来自二手配方页。

**主材料**

- 成熟的霍纳奇斯灰山羊角晶体（`Crystal of a Matured Hornacis Gray Mountain Goat Horn`）。
- 完整的人面玫瑰茎（`Human-Faced Rose Complete Stalk`）。
- 可替代方案：一份小丑非凡特性。

**辅助材料**

- 纯净水（`Purified Water`）80 毫升。
- `Tornapple / Jimsonweed Juice` 5 滴；中文译名待底本核对。
- 黑边向日葵粉末（`Black-Rimmed Sunflower Powder`）7 克。
- 金色斗篷草粉末（`Golden Cloak Grass Powder`）10 克。
- 毒芹（`Poison Hemlock`）3 滴。

### 4.2 扮演法

状态：`lead`。

- 明白自己虽然能够从占卜中了解一点命运，却依然无法真正摆脱命运。
- 用笑容隐藏痛苦、悲伤、困惑和压抑。
- “笑”不是轻浮，也不是单纯搞怪，而是面对无力改变之事时的自我保护和舞台姿态。

卡面回读：身体动作轻盈、面部带有可控笑意，但环境或视线中存在不协调的压力。不能把小丑扮演简化为滑稽、恶作剧或纯粹表情包。[扮演原则二手整理](https://lordofthemysteries.fandom.com/wiki/Acting_Method/List_of_Acting_Principles)

### 4.3 晋升条件/仪式

- 进入序列 8：服用小丑魔药，前提是已经完成占卜家阶段的消化与准备。
- 当前资料未检得独立于服药之外的序列 8 晋升仪式。
- 记录状态：`knowledge_gap`，不是 `documented_absence`。

## 5. 序列 7「魔术师」

### 5.1 魔药配方

状态：`lead`。

**主材料**

- 迷雾树人真根（`True Root of a Mist Treant`）1 份。
- 邪纹黑豹全部脊髓（`All the Spinal Fluid of a Dark-Patterned Black Panther`）。
- 可替代方案：一份魔术师非凡特性。

**辅助材料**

- 纯净水（`Purified Water`）60 毫升。
- 迷雾树人汁液（`Mist Treant Juice`）30 毫升。
- 水滴宝石粉末（`Droplet Gem Powder`）3 克。
- 幻想草精油（`Fantasy Grass Essential Oil`）4 滴。

### 5.2 扮演法

状态：`lead`，扮演原则相对明确。

- 永远不要毫无准备地表演。
- 主动制造舞台、主动开始表演，不把行动权交给对手。
- 尽量获得观众的掌声或明确反馈。
- 控制目标的注意力，决定观众看见什么、忽略什么。
- 挑战“不可能”，即使最后呈现出来的只是一个幻象。

这里的“表演”不是只在剧院演魔术，而是把准备、误导、注意力和结果组织成一场有观众的事件。卡面不能只画纸牌或火焰而不表现“谁在看、谁被误导”。

### 5.3 晋升条件/仪式

- 进入序列 7：服用魔术师魔药。
- 当前资料未检得独立的序列 7 晋升仪式；魔术师阶段的核心是扮演和能力消化。
- 研究状态：`knowledge_gap`，不写成“仪式不存在”。

## 6. 序列 6「无面人」

### 6.1 魔药配方

状态：`lead`。

**主材料**

- 千面猎者变异垂体（`Mutated Pituitary Gland of a Thousand-faced Hunter`）1 份。
- 人皮幽影非凡特性（`Human-Skinned Shadow's Characteristic`）1 份。
- 可替代方案：一份无面人非凡特性。

**辅助材料**

- 千面猎者血液（`Thousand-faced Hunter's Blood`）80 毫升。
- 黑曼陀罗汁（`Black Jimsonweed Juice`）5 滴；中文译名待底本核对。
- 龙牙草粉末（`Dragon Tooth Grass Powder`）10 克。
- 深海娜迦头发（`Hair from a Deep-sea Naga`）3 根。

### 6.2 扮演法

状态：`lead`。

- 可以假装成为任何人，但始终必须是自己。
- 真正伪装成另一个人，并从周围人的反馈中校正身份，而不是只换一张脸。
- 身份改变应包括行为、语言、习惯、社会关系和他人眼中的反应。
- “无面”并不等于没有人格；恰恰要求在多重角色中保持主体连续。

卡面回读：同一人物身份与他人反馈同时存在，不能只用换脸特效表现无面人。身高、体重、性别和骨骼比例的限制必须保留在资料说明中。[扮演原则与能力资料](https://lordofthemysteries.fandom.com/wiki/Fool_Pathway/Abilities)

### 6.3 晋升条件/仪式

- 进入序列 6：服用无面人魔药，并在之后通过稳定的身份扮演消化力量。
- 当前资料未检得独立的序列 6 晋升仪式。
- 服药过程具有明显的身份和身体失控风险，但这是魔药反噬/晋升体验，不应误写成额外仪式条件。
- 研究状态：`knowledge_gap`。

## 7. 序列 5「秘偶大师」

### 7.1 魔药配方

状态：`lead`。

**主材料**

- 古老怨灵灰烬（`Dust of Ancient Wraiths`）。
- 六翼石像鬼核心晶体（`Core Crystal of a Six-Winged Gargoyle`）。
- 可替代方案：一份秘偶大师非凡特性。

**辅助材料**

- 索尼亚岛金泉泉水（`Spring Water from Sonia Island's Golden Spring`）80 毫升。
- `Drago Bark` 10 克；中文材料名待底本核对。
- 古老怨灵残余灵性（`Remnant Spirituality of Ancient Wraiths`）。
- 六翼石像鬼双眼（`One Pair of Eyes from a Six-Winged Gargoyle`）。

### 7.2 扮演法

状态：`lead`。

- 藏在幕后，让秘偶完成主要工作。
- 记住每个秘偶都有自己的设定、过去、语言、习惯和社会关系。
- 像导演一样安排“戏剧”，并从观众、敌人和秘偶的反应中获得反馈。
- 以秘偶为媒介，引导敌人扮演“被操纵的对象”。
- 不应把秘偶大师扮演缩成“控制别人”；关键是幕后组织、角色设定、舞台调度和间接影响。

### 7.3 晋升条件/仪式

**仪式条件**

- 在美人鱼歌声中服用秘偶大师魔药。
- 美人鱼歌声的核心作用是中和、平衡和放大情绪，使晋升者能够保留最后的情感与自我，抵抗灵体之线对身体和灵魂的侵蚀。
- 理论上，具有相近效果的声音或非凡能力可能替代美人鱼歌声，例如某些海洋歌者的歌声；这是二手资料中的机制解释，不应写成任意声音都能替代。
- 不死美人鱼不能简单视为等价替代品，具体条件需要底本复核。

**研究状态**：仪式本身为 `lead`；“中和/平衡灵体之线”的仪式本质为二手解释性资料，暂不标一手 `verified`。[秘偶大师配方与仪式](https://lordofthemysteries.fandom.com/wiki/Fool_Pathway/Advancement)、[美人鱼资料](https://lordofthemysteries.fandom.com/wiki/Creatures_and_Plants)

## 8. 序列 4「诡法师」

### 8.1 魔药配方

状态：`lead`。

**主材料**

- 诡术邪怪主眼（`Bizarro Bane's Main Eye`）。
- 灵界掠夺者真正灵体（`True Soul Body of a Spirit World Plunderer`）。
- 可替代方案：一份诡法师非凡特性。

**辅助材料**

- 诡术邪怪血液（`Bizarro Bane's Blood`）200 毫升。
- 灵界掠夺者尘埃（`Spirit World Plunderer's Dust`）30 克。
- 红发桦树皮（`Red-hair Birch Bark`）10 克。
- 一段金色葡萄藤（`A Segment of Golden Grapevine`）。
- 指甲大小的自制橡胶面具（`Fingernail-sized Self-made Rubber Mask`）1 个。

### 8.2 扮演法

状态：`lead`。

- 制造令人恐惧、诡异和不安的场景，并从观众反馈中完成扮演。
- 成为神秘、古怪、难以预测的人。
- “Sorcerer”不是要求表演某种固定职业；关键是用魔术师式的方法制造诡异和错位。
- “诡异”包含神秘、未知、复杂和命运不可预测的一面。
- 不能只靠血腥、黑雾或怪物外形表达诡异；需要让观众的判断、空间关系或现实规则发生错位。

### 8.3 晋升条件/仪式

- 依靠自身力量与筹划，在许多观众面前导演一场大型表演。
- 表演必须杀死一名半神层次或同等强度的非凡生物。
- 在表演结尾或高潮阶段服用诡法师魔药。
- 仪式的解释性核心是“制造标记/锚”：诡法师已经经历灵之虫分裂，比其他途径更早需要稳定的锚。
- “观众很多”是条件的一部分；不能把独自完成的战斗剪辑成合格仪式。

研究状态：条件和仪式为 `lead`；“锚”是二手解释，适合作为限制和视觉回读，不当作官方配方栏文字。[诡法师配方与仪式](https://lordofthemysteries.fandom.com/wiki/Fool_Pathway/Advancement)

## 9. 序列 3「古代学者」

### 9.1 魔药配方

状态：`lead`。

**主材料**

- 福根之犬双眼（`Pair of Eyes of Hound of Fulgrim`，又称 `Sefirah Castle Keeper`）。
- 一颗雾之魔狼转化之心（`Transformed Heart of a Fog Demon Wolf`）。
- 可替代方案：一份古代学者非凡特性。

**辅助材料**

- 福根之犬血液（`Hound of Fulgrim Blood`）100 毫升。
- 雾之魔狼白霜晶体（`White Frost Crystal of a Fog Demon Wolf`）30 克。
- 大量真实的古代历史记录（`A Large Amount of Real Ancient Historical Records`）。

### 9.2 扮演法

状态：`lead`。

- 成为来自古代的学者，而不是只穿古装或收藏旧书。
- 搜索真实古代历史，研究史料，并从中得出新的结论。
- 见证命运、影响现在，但不能把已经发生的过去随意逆转。
- 研究历史既是获取知识，也是为自己在历史孔隙中保留清晰锚点。

卡面回读：过去的记录、当前的观察和现实中的影响同时出现；不能只画旧书、遗迹或时间沙漏。[古代学者扮演原则](https://lordofthemysteries.fandom.com/wiki/Acting_Method/List_of_Acting_Principles)

### 9.3 晋升条件/仪式

- 与现实隔绝至少三百年。
- 在这段隔绝后，成为不属于当前时代的“历史”，再服用古代学者魔药。
- 这段时间不是普通闭关，而是让自身与当前现实的因果联系被历史化。
- 仪式解释：三百年的历史标记可成为进入历史孔隙后的锚，帮助主体找回自己的定义。
- 克莱恩的特殊情况：穿越者身份与源堡关系使其完成仪式的具体过程具有特殊性，不能直接当作普通古代学者的通用捷径。

研究状态：`lead`；“三百年隔绝”是条件，“进入历史后找回自我”的过程是仪式机制解释，两者分开记录。[古代学者配方与仪式](https://lordofthemysteries.fandom.com/wiki/Fool_Pathway/Advancement)

## 10. 序列 2「奇迹师」

### 10.1 魔药配方

状态：`lead`。

**主材料**

- 乌黯魔狼之心（`Heart of a Dark Demonic Wolf`）。
- 可替代方案：一份奇迹师非凡特性。

**辅助材料**

- 乌黯魔狼血液（`Blood of a Dark Demonic Wolf`）300 毫升。
- 一只时之虫（`Worm of Time`）。
- 一只星之虫（`Worm of Star`）。

### 10.2 扮演法

状态：`lead`。

- 满足他人的愿望。
- 制造奇迹。
- 不以“高高在上的神”姿态满足愿望，而是以一个人完成奇迹的方式行动。
- 奇迹往往是短暂的一刻，而命运可能是长期结果；不能只追求瞬间轰动而忽略愿望的后续。

卡面回读：愿望、实现方式和实现后的余波必须同时存在；不能把奇迹师画成单纯发光、许愿或无条件复活。[奇迹师扮演原则](https://lordofthemysteries.fandom.com/wiki/Acting_Method/List_of_Acting_Principles)

### 10.3 晋升条件/仪式

- 把一段已经被遗弃、被遗忘或脱离当前世界的历史带回现在。
- 被带回的历史不是普通资料，而应在现实与历史之间产生足够真实的对应关系。
- 克莱恩的具体晋升：让白银城被遗忘的历史重新回到当前历史，并以此完成奇迹师仪式。
- 仪式的主体不是“知道一段历史”，而是让历史真正重新影响当前时代。

研究状态：`lead`；原著剧情线提供较强章节定位，但完整通用仪式文字仍需中文底本逐字复核。[奇迹师晋升资料](https://lordofthemysteries.fandom.com/wiki/Fool_Pathway/Advancement)、[官方 WebNovel 第 1268 章定位](https://www.webnovel.com/book/11022733006234505/35957781160850515)

## 11. 序列 1「诡秘侍者」

### 11.1 魔药配方

状态：`lead`。

**主材料**

- 一份诡秘侍者非凡特性（`Attendant of Mysteries Beyonder Characteristic`）。

**辅助材料**

- 九种灵界特殊材料（`Nine Spirit World Specialties`）。

没有可靠证据显示必须把九种材料擅自扩写为固定名称和固定数量；本条保持“九种灵界特殊材料”的精度，不补造完整清单。

### 11.2 扮演法

状态：`lead`。

- 侍奉深层的神秘。
- 保护秘密、承载秘密，并让自己成为神秘结构的可靠接口。
- 这里的“侍奉”不能简化为服从某个组织；需要结合秘密、灵界、命运和自身身份的承载关系。

卡面回读：重点表现规则、秘密和多重身份的承接，不把“侍者”画成普通仆从或宗教侍从。[诡秘侍者扮演原则](https://lordofthemysteries.fandom.com/wiki/Acting_Method/List_of_Acting_Principles)

### 11.3 晋升条件/仪式

- 建造一座完全由秘偶组成的城镇。
- 为每一个秘偶设计命运轨迹。
- 让秘偶彼此互动，使其形成一幅足够真实的生活画，并在灵界生成对应区域。
- 城镇越大、秘偶越多、日常越详细、命运越丰富且越真实，仪式效果越好。
- 克莱恩的乌托邦是该仪式的角色实例；五千名秘偶、城市基础设施、社会关系和外部入口共同承担仪式结构。

研究状态：`lead`；“规模越大、生活越详细效果越好”属于二手资料对原著条件的扩展说明，正式卡面先只写必要条件，不写未经底本确认的最小人数。[诡秘侍者配方与仪式](https://lordofthemysteries.fandom.com/wiki/Fool_Pathway/Advancement)、[Utopia 资料](https://lordofthemysteries.fandom.com/wiki/Utopia)

## 12. 序列 0「愚者」

### 12.1 魔药配方

状态：`verified / primary_chinese`，但需要区分通行公式和克莱恩的具体资源状态。

**通行配方**

- 愚者唯一性（`The Fool Uniqueness`）。
- 三份诡秘侍者非凡特性（`Three Attendant of Mysteries Beyonder Characteristics`）。
- 辅助条件：掌控至少四分之一个历史迷雾/历史之雾（`at least a quarter of the Fog of History`）。

**克莱恩具体情况**

- 资料中也会以“愚者唯一性加自身之外剩余两份诡秘侍者特性”描述克莱恩手上的剩余资源。
- 这不是对通行三份公式的否定，而是角色已经拥有一份序列 1 特性后的具体资源表达。
- 正式数据应同时保存 `generic_formula` 与 `klein_resource_state`，不能用其中一个覆盖另一个。

### 12.2 扮演法

状态：`knowledge_gap + interpretation_candidate`。

当前可访问官方中文设定集没有单列序列 0 愚者的完整扮演守则。可保留的原创解释候选是：

> 在身份、历史和命运不断错位时，仍然辨认出真正的自己；让被看见的角色与真正承担后果的主体同时存在。

这句话只能标为 `interpretation`，不能写入 `canon` 的固定扮演法字段，也不能把“装傻”“欺骗别人”直接当作完整守则。

### 12.3 晋升条件/仪式

- 愚弄一次时间、历史或者命运。
- 该条件是愚者途径的专属序列 0 仪式，不应与“序列 0 等于真神”的层级说明混为一谈。
- 克莱恩的成神过程包含唯一性、诡秘侍者特性、安提哥努斯、阿蒙、诸神干涉和源堡等具体剧情因素；这些是人物实例，不应全部硬编码为每个愚者的通用仪式步骤。

状态：`verified / primary_chinese`。[起点官方设定集](https://h5.if.qidian.com/h5/workSet/main?albumId=131&bookId=1010868264)、[官方 WebNovel 第 1291 章定位](https://www.webnovel.com/book/11022733006234505/two-rituals_45148053144913263)

## 13. 研究结论与落盘映射

### 13.1 已落盘的路径级事实

- 所有序列 9—0 的名称已经存在于 `pathways/fool/canon.json`。
- 序列 9 的主材料、服药入序和灵摆限制已有中文研究断言。
- 序列 0 的通行配方、历史迷雾辅助条件、三项核心能力和成神仪式已有官方中文设定集断言。
- 本轮新增序列 8—1 的配方、扮演法和晋升/仪式研究断言，统一标为 `lead`，并绑定本研究文件与二手来源。
- 对序列 9、8、7、6 的“没有独立仪式”不做绝对断言，改记为限定检索范围内的 `knowledge_gap`。

### 13.2 不能由本研究稿直接推出的内容

- 不能把二手配方直接标为第一部中文原著 `verified`。
- 不能把某个角色的实际晋升过程当作所有该序列非凡者的通用仪式。
- 不能把配方材料的视觉颜色、形状或药液口感当作卡面必须表现的正典事实，除非另有逐项来源。
- 不能把扮演法写成口头禅，也不能把扮演原则直接当作能力。
- 不能把序列 0 的解释候选写成原著固定规则。

### 13.3 下一步核验顺序

1. 先以授权中文底本逐项核对序列 8—6 的完整配方与扮演段落。
2. 再核对序列 5—1 的仪式原文、仪式本质和克莱恩个人晋升实例。
3. 最后补序列 0 的扮演和限制；如果原著仍没有独立完整条目，就保留 `knowledge_gap`，不填空。
4. 事实核验后再把对应 `lead` claim 升级为 `verified`；升级必须同步更新 `verification.reviewed_at`、`source_refs` 和相关卡的设计指纹。

## 14. 相关仓库文件

- `pathways/fool/canon.json`：路径级可复用断言。
- `pathways/fool/sequences/09/card.json`：当前已有序列 9 研究卡，不能用本文件替代其六维设计和图像状态。
- `pathways/fool/sequences/08/card.json` 至 `pathways/fool/sequences/01/card.json`：当前仍为 scaffold，本轮不把研究稿误标为卡面设计完成。
- `pathways/fool/sequences/00/card.json`：当前已有候选图像状态，不等于序列 0 事实与视觉都已批准。
- `sources/registry.json`：来源版本、访问状态和证据范围。

本文件是研究产物，不是正式卡面、不含完整原著正文、不自动授权声音或图像生产，也不代表用户已经逐条批准所有 `lead` 断言。
