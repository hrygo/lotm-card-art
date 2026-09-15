# 《诡秘世界》产品需求文档 PRD（项目内基线副本）

> **效力**：产品基线 · 立项级。本文件描述的是**未来产品《诡秘世界》**的目标定义，不是本仓库（诡秘之主 · 成神途径卡牌知识库）当前的规范、事实源或批准记录。
> **来源**：用户提供，`~/Downloads/诡秘世界_PRD_v1.0.md`；2026-09-15 入仓为项目内副本。
> **正文完整性**：下一分隔行之后为原文，**逐字未改**（未删节、未改写、未补写）。
> **sha256**：`bc2c04057e4686904c8665750b7be45693197d9857c0ffed2de9054df555c62c`（等于源文件哈希，用于证明正文未被改动）。
> **适用边界**
> - 对《诡秘世界》的产品定义 → 约束性基线；后续拆分 PRD（见附录 B）与实现以其为准。
> - 对本仓库现有交付面 → **不是规范**：不覆盖 `pathways/*/card.json`、`canon.json`、`sources/registry.json`、`config/`，不构成任何 `approved` / `release_approved`，也不改变卡牌数量与卡槽口径。
> - 按本文 §25：World / Story / Character / Audio 引擎**不进入**卡牌美术仓库；本仓库继续只承担卡牌内容生产与 M1 客户端，引擎实现属另一交付面。
> **实现状态对照（2026-09-15）**：已有部分对应实现的只有 `apps/LotmCardStudio`（M1 垂直切片）与 `docs/card-narrative-contract.md`（单卡叙事与声音合同）；World State、Character Engine、Knowledge/Spoiler、Story Genesis、Story Director、Outcome Resolver、State Delta、Memory Distillation、Audio Engine、Story Book **均未实现**。
> **路由**：文档效力地图见 `docs/AGENTS.md`；立项与分层边界见 `docs/DECISIONS.md` D17。

---

# 《诡秘世界》产品需求文档 PRD

> **版本**：v1.0  
> **状态**：产品基线 / 立项级  
> **首发平台**：macOS  
> **产品形态**：单人持续世界 × 卡牌收藏 × 角色演绎 × 互动叙事 × 沉浸式声音故事  
> **产品边界**：单真实用户；个人世界；首发本地持久化；未来可扩展其他平台与可选同步

---

## 0. 执行摘要

《诡秘世界》不是“AI 续写《诡秘之主》”，也不是“卡牌附带一个故事生成器”。它是一套以《诡秘之主》的世界观、历史、人物、途径与神秘学规则为 **Canon 底座** 的单人持续世界演绎应用。

用户通过已有卡牌进入这个世界：

- **原著人物卡**：进入一个已经具有完整历史、人格、关系与知识边界的人物视角；
- **序列卡**：以序列原型为约束，诞生一个新的原创人物，从原著未曾照到的角落探索世界；
- **特殊存在卡**：以符合位格的高层叙事语法影响世界，而不是沿用普通冒险模板。

一次互动故事不是孤立内容。人物经历、关系变化、知识增长、地点变化与重要世界事件都会沉淀为该用户个人世界的历史，影响未来从其他人物视角展开的故事。

产品最终希望建立的体验不是：

> “AI 给我生成了一篇好故事。”

而是：

> **“这是我的那个诡秘世界；它记得发生过什么，而其中的人也记得。”**

核心原则：

1. **世界先于故事。**
2. **角色先于剧情。**
3. **Canon 定义已经发生的历史，但不锁死尚未发生的未来。**
4. **玩家影响命运，但不把人物变成木偶。**
5. **每一个重要故事都必须留下记忆或世界痕迹。**
6. **故事结束，世界不结束。**

---

# 1. 产品背景与机会

## 1.1 当前产品基础

现有《诡秘之主》应用已经围绕卡牌建立内容资产，并持续扩展：

- 22 条成神途径、序列 9 至 0 的序列卡体系；
- 原著人物卡系列，并将持续丰富；
- 特殊存在、高位存在及其他世界要素卡牌；
- 卡牌强调设定准确、系列美学、身份与能力的可辨识度。

其中序列卡并不默认等同于某个具体原著人物，而是“序列原型”；现有设计语义包含身份、扮演、能力、魔药、晋升、限制等维度。这使卡牌天然可以从“收藏物”升级为“世界入口”。

## 1.2 产品机会

原著描绘的是一个庞大世界中少数人物、少数地点、少数时间段被照亮的部分。大量空间天然存在：

- 原著人物没有被书写的日常与事件；
- 原著事件之间的时间空隙；
- 已离开主叙事人物之后的人生；
- 贝克兰德、海上、教会、秘密组织等未被主线触及的人与事；
- 完全原创人物在同一世界规则下的生命轨迹；
- 从 Canon 某一点开始产生的另一条命运。

本产品的机会是：**把“未被讲述的空间”变成可持续演绎的世界。**

---

# 2. 产品定位

## 2.1 一句话定位

**《诡秘世界》是一款以《诡秘之主》世界观、原著人物、途径序列和历史设定为基础的单人持续世界演绎应用。用户通过卡牌进入不同人物的视角，与原著人物或原创人物共同经历原著未曾讲述的故事，每一次重要经历都会成为这个个人世界新的历史。**

## 2.2 产品不是

本产品不是：

- 原著剧情重演器；
- 单篇 AI 同人小说生成器；
- AI Chat 角色陪聊产品；
- 传统视觉小说；
- MMO / 多人在线世界；
- PvP / 卡牌对战游戏；
- 数值型开放世界 RPG；
- 数百 NPC 永久在线自主模拟器。

## 2.3 核心价值

### 对原著人物爱好者

体验“熟悉人物未曾被写下的人生”，并让这些经历长期成为该人物在个人世界中的历史。

### 对世界观爱好者

从原著主视角之外探索世界，看到普通人、基层非凡者、组织成员与城市角落中的另一面。

### 对卡牌收藏用户

卡牌从静态收藏品升级为世界访问入口和人物经历载体。

### 对声音故事用户

获得以人物稳定音色、环境声、旁白与关键音效构成的沉浸式互动有声故事。

---

# 3. 用户模型与平台策略

## 3.1 单真实用户

产品只有一个真实用户。

```text
Real User = 1
World Characters = N
```

世界内部可以拥有大量角色、NPC、组织和关系，但不存在多个真实用户共享同一 World State 的产品需求。

明确不做：

- 玩家联机；
- 用户之间交易；
- 公会；
- 排行榜；
- 世界频道；
- PvP；
- 多真实用户共同推动一条世界线。

## 3.2 首发平台

首发为 **macOS 应用**。

产品定义不绑定具体设备。未来允许扩展：

- Windows；
- iPad / 其他终端；
- 多设备访问；
- 可选的数据备份与同步。

即使未来支持同步，它仍然是一名真实用户的个人世界，而不是多人共享世界。

## 3.3 持久世界 ≠ 后台实时模拟

“持续存在”指世界状态在会话之间保持，而不是应用关闭后仍持续消耗资源模拟整个世界。

默认：

```text
应用运行 → 世界发生演绎
应用关闭 → 世界状态持久化并暂停
```

后续可考虑有限的时间推进或离线事件，但不作为 MVP 前提。

---

# 4. 产品核心模型

整个产品围绕三个一级对象构建：

## 4.1 World

这个世界已经发生什么、目前是什么状态。

## 4.2 Character

是谁在这个世界中经历事情，以及这个人如何理解世界。

## 4.3 Story

用户这一次通过某个角色视角，看见并参与了什么。

关系：

```text
World
  ├── Character
  │     └── Story / Episode
  ├── Character
  │     └── Story / Episode
  └── Character
        └── Story / Episode
```

**故事属于世界，而不是每次故事重新创造一个世界。**

---

# 5. 卡牌在产品中的角色

## 5.1 卡牌是“世界入口”

卡牌不仅用于收藏、设定阅读与美术欣赏，也承担进入不同叙事视角的功能。

```text
卡牌
  ├── 原著人物卡 → 进入已存在人物
  ├── 序列卡     → 创造受该序列约束的原创人物
  └── 特殊存在卡 → 进入高位叙事模式
```

## 5.2 原著人物卡

人物卡代表一个 Canon 中已经存在的具体人物。

进入故事时必须继承：

- 身份与社会位置；
- 外貌与阶段性形象；
- Canon 经历；
- 当前时间点的序列与能力；
- 当前时间点已经获得的知识；
- 人际关系；
- 价值观；
- 行为习惯；
- 语言风格；
- 重要记忆。

目标不是“一个像奥黛丽的人”，而是：**这个世界里的奥黛丽。**

## 5.3 序列卡

序列卡代表序列原型，而非固定人物。

选择序列卡后，Character Genesis 可以生成一名原创角色：

```text
序列卡
  ↓
时代 / 地域 / 社会身份
  ↓
原创 Character
  ↓
进入 World
```

其能力、限制、扮演原则和知识上限必须受序列 Canon 约束。

## 5.4 原创人物卡

原创人物可以来自：

- 序列卡生成；
- 产品预设角色；
- 故事中成长为重要人物的 NPC；
- 后续开放的用户角色创建。

原创人物的价值不是替代原著人物，而是 **深入原著没有照亮的世界**。

## 5.5 特殊存在卡

天使、真神、旧日、外神、源质等不能沿用普通人物的“走左边还是右边”式交互。

随着位格提升，叙事选择由“行动”逐渐升级为：

- 是否回应；
- 是否干涉；
- 通过何种象征或权柄施加影响；
- 是否让某件事情进入历史；
- 影响哪个锚、因果或群体。

---

# 6. Canon 与 Fate

## 6.1 Canon：已发生的历史

Canon 包括：

- 世界规则；
- 已确定历史；
- 某时间点的人物身份；
- 人物已经经历的重要事件；
- 当前阶段已经掌握的能力；
- 已建立的关系；
- 组织存在时间；
- 重要地点和事件状态。

Canon 的原则是：**不能为了让故事更刺激而随意修改。**

## 6.2 Fate：尚未发生的未来

```text
过去
━━━━━━━━━━━━━━━━━━●━━━━━━━━━━━━━━━━━━→
               Story Start

     Canon History          Open Fate
       已发生                 尚未发生
```

用户真正参与的是 Open Fate。

## 6.3 三种时间模式

### Canon Gap

发生于原著已知事件之间。

要求：

- 不破坏之后必须成立的重要 Canon；
- 人物知识、能力、关系对应准确时间点；
- 允许补充原著没有描写的小型事件与经历。

目标感受：**“这件事真的可能发生过。”**

### Open Future

从人物某个 Canon 时间点之后开始，未来完全开放。

适合：

- 原著已结束的人物未来；
- 离开主叙事人物的后续人生；
- 原创人物。

### Divergent Fate

如果故事中发生足以改变既有未来的重要事件，则明确创建新 Worldline。

```text
Canon Timeline ──────────────●────────────→
                              \
                               └──────────→ Divergent Worldline
```

从分叉后开始，不强制人物重新回到原著未来。

## 6.4 Canon Guard 的真正职责

Canon Guard 保护：

- 世界规则；
- 已经发生的历史；
- 能力边界；
- 知识边界；
- 时间一致性；
- 人物阶段一致性。

它不负责强制所有未来继续复制小说。

---

# 7. Persistent World：个人持续世界

## 7.1 World State

每个用户拥有一个持续存在的世界状态：

```text
World
├── Canon Baseline
├── Active Worldline
├── Worldlines
├── Characters
├── Relationships
├── Locations
├── Organizations
├── World Events
├── Active Mysteries
├── Episodes
├── Memories
└── User / Spoiler Progress
```

## 7.2 世界持续性

Story 完成后，其中具有长期意义的结果写回 World State。

示例：

- 一个据点被摧毁 → 后续故事中仍然是废墟；
- 一个原创 NPC 死亡 → 不能无理由正常出现；
- 一个角色知道了秘密 → 未来继续知道；
- 两个人建立信任 → 后续相遇时关系延续；
- 一桩案件没有解决 → 可以成为其他角色之后遇到的未解事件。

## 7.3 World Event 分级

### Personal Event
只影响当前人物，例如受伤、获得物件。

### Relationship Event
改变人物之间的信任、敌意、债务、共享秘密等。

### Local Event
改变某地点、组织或区域，例如据点被摧毁。

### Major World Event
可能影响多个未来故事或世界线的重要变化。

## 7.4 不做全量世界模拟

采用：

> **Persistent Important State + Generative Detail**

长期保存重要状态，大量普通居民、环境细节、一次性背景在进入具体场景时按规则生成。

---

# 8. Character Engine

## 8.1 Character 数据模型

```text
Character
├── Identity
├── Appearance
├── Personality
├── Values
├── Decision Pattern
├── Speech Pattern
│
├── Canon History
├── Generated History
│
├── Pathway
├── Sequence
├── Abilities
├── Limitations
│
├── Knowledge
├── Secrets
│
├── Relationships
├── Memories
│
├── Current State
├── Current Goals
└── Voice Persona
```

## 8.2 原著人物 Character Bible

原著人物不能只由“聪明、善良、谨慎”这类标签定义。

至少需要描述：

- 面对危险的判断方式；
- 对陌生人的态度；
- 对力量、秘密、组织的态度；
- 价值排序；
- 道德底线；
- 幽默与自嘲方式；
- 冲突处理方式；
- 长期愿望；
- 恐惧与内在矛盾；
- 压力下的人格变化；
- 典型措辞与语气；
- 明确的“不会这样做 / 不会这样说”的反例。

目标：**隐藏姓名后，仍能凭行为和声音认出这个人物。**

## 8.3 Character Agency

用户不是角色遥控器，而是“命运顾问”。

```text
角色遇到问题
  ↓
角色描述处境
  ↓
出现不同策略
  ↓
用户提供建议
  ↓
角色结合人格、知识与现实执行
  ↓
产生结果
```

原则：

```text
Choice ≠ Command
Choice = Advice
```

## 8.4 角色可以部分偏离建议

仅当：

1. 选择事实上无法执行；
2. 严重违反角色核心人格；
3. 人物没有必要知识；
4. 违反 Canon 能力或世界规则；
5. 执行前发现新的关键信息。

角色偏离必须有自然、可理解的原因，且不能高频发生。

## 8.5 Character Development

人物不是静态 Prompt。

```text
Core Personality  → 极慢变化
Worldview         → 可长期成长
Relationships     → 持续变化
Knowledge         → 持续增长
Emotional State   → 快速变化
```

人物可以成长，但不能因为模型随机性突然变成另一个人。

---

# 9. Knowledge Engine 与剧透系统

## 9.1 World Truth ≠ Character Knowledge

同一个世界事件，不同人物只能看到自己能够接触到的部分。

```text
                    WORLD TRUTH
                         │
           ┌─────────────┼─────────────┐
           ▼             ▼             ▼
       Character A   Character B    普通 NPC
        Knowledge     Knowledge      Knowledge
```

## 9.2 Knowledge Fact

重要事实至少具有：

```text
fact_id
content
timeline
canon_status
knowledge_level
spoiler_level
known_by
source
```

知识级别示例：

```text
public
social
organization
church
pathway
high_sequence
secret
forbidden
cosmic
```

## 9.3 Knowledge Gate

Character Actor 不直接获得完整 Lore Kernel。

输入给角色的世界事实必须经过 Knowledge Gate，避免：

- 低序列人物知道高位秘密；
- 人物提前知道后来才发生的事件；
- 一个组织成员自动知道组织最高层真相；
- 角色拥有用户/模型的上帝视角。

## 9.4 Spoiler Profile

用户设置原著阅读进度，例如：

- 无剧透；
- 第一部 · 卷 X；
- 第一部完成；
- 续作进度 X；
- 完整设定。

图鉴、人物卡、卡牌详情、Story Genesis、NPC 和 World Event 均遵循统一 Spoiler Policy。

---

# 10. Story Engine 总体架构

逻辑架构：

```text
World Engine
     │
     ▼
Character Engine
     │
     ▼
Story Genesis
     │
     ▼
Story Director
     │
     ▼
Outcome Resolver ◄──── Player Choice
     │
     ▼
Story State / State Delta
     │
     ▼
Character Actor
     │
     ▼
Canon + Knowledge + Continuity Guard
     │
     ▼
Audio Engine
```

这些是职责，不要求一项职责对应一个独立模型。

---

# 11. Story Genesis：先创建真相

## 11.1 Story Seed

故事正式开始前必须生成隐藏 Story Seed：

```text
主角 / 当前人物阶段
时间与地点
表层事件
真正发生的事情
核心冲突
关键 NPC
各自目标
隐藏真相
秘密
线索分布
时间压力
故事主题
潜在转折
可接受结局集合
Narrative Scale
```

## 11.2 Truth First

故事采用：

> **先存在真相，再让人物逐步发现。**

顺序：

```text
真正发生了什么？
  ↓
是谁造成的？为什么？
  ↓
留下了什么证据？
  ↓
谁知道？谁不知道？
  ↓
角色通过哪些路径可能发现？
```

禁止每一轮临时修改幕后真相来制造“反转”。

## 11.3 Narrative Commitment Ledger

### Hard Commitments

不能随意改变：

- 已确定死亡；
- 人物身份；
- 核心真相；
- 重要物件位置；
- 时间；
- 当前序列与能力；
- 已经获得的知识；
- Canon 事实。

### Soft Commitments

导演层计划：

- 待回收伏笔；
- 可能再次出现的 NPC；
- 冲突发展方向；
- 计划中的揭示窗口。

### Mutable State

允许选择改变：

- danger；
- exposure；
- spirituality；
- injury；
- corruption；
- trust；
- suspicion；
- clues；
- relationships；
- location；
- time。

---

# 12. Story State 与因果链

## 12.1 Story State

核心状态示例：

```text
story_id
turn
phase
scene
time
location
character_state
world_context
known_clues
secrets
npc_states
relationships
commitments
current_goal
danger
exposure
spirituality
injury
corruption
```

## 12.2 Outcome First

用户做出选择后：

```text
Player Choice
     ↓
Outcome Resolver
     ↓
State Delta
     ↓
Story State Update
     ↓
Validation
     ↓
Narrative Generation
```

不采用：

```text
Choice → LLM 自由续写 → 再猜发生了什么
```

数据库和结构化状态是事实，文学叙述是事实的演绎。

---

# 13. 互动叙事体验

## 13.1 Character-Led Narrative

优先由角色本人讲述正在经历的事情，而不是由“系统旁白”主导。

示例：

> “我原本以为那只是一次普通的占卜。”  
> “直到结果告诉我——”  
> “这个已经死去的人，明天才会死。”

人物继续描述当前困境，在真正的重大节点向用户征询意见。

## 13.2 Choice System

每次默认提供三个选择，但必须代表不同策略。

示例：

| 选择 | 隐藏策略 | 主要代价 |
|---|---|---|
| 重新进行占卜 | 信息优先 | 灵性消耗 |
| 调查死者过去 | 稳健调查 | 时间成本 |
| 隐藏并等待来人 | 高风险观察 | 暴露风险 |

禁止三个选项只是同一行为的不同措辞。

## 13.3 Choice Intent

先生成策略 Intent，再转换成当前人物可执行的具体行动：

```text
investigate
observe
confront
deceive
retreat
protect
cooperate
sacrifice
manipulate
conceal
risk
```

## 13.4 选择的真实意义

一个重要选择至少应改变以下一种或多种内容：

- 后续可获得信息；
- 时间；
- 关系；
- 风险；
- 身份暴露；
- 灵性 / 状态；
- NPC 行为；
- 是否进入某个场景；
- 最终结局条件；
- World Event。

---

# 14. 故事长度与戏剧结构

## 14.1 长度

默认最多 **10 次重大抉择**，但不是必须十次。

Story Director 可以在 4 / 6 / 8 / 10 次等适合长度自然结束。

## 14.2 标准节奏

```text
Opening
  ↓
Discovery
  ↓
Investigation
  ↓
Escalation
  ↓
Midpoint Revelation
  ↓
Crisis
  ↓
Truth / Partial Truth
  ↓
Final Choice
  ↓
Resolution
```

选择节点由剧情需要触发，不按固定字数机械弹出。

## 14.3 收束命运

用户可在任何合适节点选择 **“收束命运”**。

Closure Mode 要求：

- 不再引入新的主要冲突；
- 不再引入新的核心人物；
- 处理当前主线；
- 回收必须回收的伏笔；
- 允许部分秘密保持未知；
- 在 1–2 个主要 Story Beat 内形成自然结局。

## 14.4 结局类型

允许：

- 真相结局；
- 胜利结局；
- 幸存结局；
- 代价结局；
- 失败结局；
- 逃离结局；
- 错误真相结局；
- 开放结局；
- 失控结局；
- 死亡结局。

所有选项最终都成功属于设计缺陷。

---

# 15. Secrets System

Story Seed 在开场前建立秘密集合：

```text
secret_01
secret_02
secret_03
...
```

秘密状态：

```text
hidden
partial
revealed
```

Episode 结束可以展示：

> **已揭开 4 / 7 个秘密**

未发现秘密不直接公开答案，为重玩、其他人物视角和未来 World Event 保留空间。

---

# 16. Narrative DNA：途径与位格决定叙事语法

## 16.1 途径 Narrative DNA

22 条途径不能只是换能力名称，需要各自拥有叙事倾向。

示例：

### 愚者相关途径
信息差、预兆、命运、身份、欺骗、仪式、线索。

### 观众相关途径
心理、观察、关系、人格、谎言、影响与操纵。

### 猎人相关途径
冲突、挑衅、陷阱、战争、群体与阴谋。

### 门相关途径
探索、旅行、空间、陌生区域、边界与未知。

Narrative DNA 至少描述：

```text
genre_weights
preferred_conflicts
pacing
motifs
choice_axes
typical_costs
forbidden_cliches
```

## 16.2 Sequence Narrative Scale

### 序列 9–7：人的尺度
案件、生存、城市异常、小型神秘事件、身份与初步非凡风险。

### 序列 6–5：成熟非凡者尺度
教会、秘密组织、团队、复杂仪式、区域阴谋与主动博弈。

### 序列 4–3：半神尺度
城市级异常、大型仪式、规则与权能冲突、污染与大规模后果。

### 序列 2–1：天使尺度
历史、锚、命运、象征、高位存在、大范围现实影响。

### 序列 0：神灵叙事
用户不再主要决定“下一步走哪里”，而决定“是否回应、如何施加影响、允许哪种因果进入现实”。

高位叙事必须维护位格感，不能只是把低序列冒险换成更大的特效。

---

# 17. Memory System

人物长期连续性至少分四类记忆。

## 17.1 Canon Memory

原著确定发生过的经历，具有最高事实优先级，不被生成内容覆盖。

## 17.2 Episode Memory

该人物在用户个人世界中经历过的生成故事。

## 17.3 Relationship Memory

```text
trust
fear
respect
affection
hostility
debt
shared_secret
last_encounter
```

## 17.4 World Memory

人物本人知道的世界变化。World Truth 发生变化，不代表所有人物自动知道。

## 17.5 Memory Distillation

每个 Episode 结束后，从完整故事提炼：

- 重大经历；
- 关键选择；
- 新知识；
- 重要秘密；
- 心理影响；
- 关系变化；
- 世界变化。

长期交互使用结构化记忆和摘要，而不是无限把所有历史全文塞入模型上下文。

---

# 18. Audio Engine：声音是第一公民

## 18.1 Audio First

本模块不是“文字小说 + TTS”，而是互动有声故事。

基本体验：

```text
环境声
  ↓
人物讲述
  ↓
必要旁白 / NPC
  ↓
声音事件与情绪变化
  ↓
人物提出抉择
  ↓
音频停顿
  ↓
用户选择
```

## 18.2 Voice Persona

重要人物拥有稳定声音身份：

```text
Timbre
Age Impression
Breath
Tempo
Rhythm
Emotional Range
Distance
Narration Style
Forbidden Traits
```

同一人物跨越不同故事仍应明显是同一个声音。

## 18.3 声音层次

### Character Voice
主要人物第一人称讲述与对白。

### Narrator
仅用于必要的时间、空间和镜头转换，不抢人物主体。

### Ambient
雨、海、街道、房间、教堂、工厂、地下空间等持续环境层。

### SFX
钟声、枪声、敲门、脚步、仪式、呼吸、低语等关键事件。

## 18.4 声音资产原则

V1 优先使用高质量可复用 Soundscape Library，而不是为每一个背景声音实时生成 AI 音频。

Story Director 输出环境与音效标签，Audio Engine 负责拼接、混音和衔接。

---

# 19. 信息架构与核心界面

建议首版形成四个一级区域：

```text
世界
卡牌
人物
故事书
```

## 19.1 世界首页

目标：用户一打开就感觉自己“回到了同一个世界”。

展示：

- 当前世界时间 / 世界线；
- 最近发生的重要事件；
- 正在进行的命运；
- 最近活跃人物；
- 未解决事件；
- 重要地点变化；
- 最近完成的故事。

不是内容平台首页，不出现“热门玩家故事 / 排行榜 / 社区动态”等社交元素。

## 19.2 卡牌详情

保留收藏、设定和视觉价值，并增加：

> **开启命运**

人物卡：进入该人物。  
序列卡：创建对应序列原创人物。  
特殊卡：进入对应 Narrative Scale。

## 19.3 命运生成界面

卡牌作为视觉主体，逐渐显现本次故事的少量可见种子，例如：

```text
时间：深夜
地点：贝克兰德
异常：一个已经死去却仍拥有未来的人
压力：天亮以前
```

用户点击：

> **编织命运**

后台 Story Seed 的真相、NPC 目标、秘密与承诺不展示。

## 19.4 Story Player

主要元素：

- 卡牌 / 人物视觉主体；
- 当前章节；
- 字幕；
- 音频进度与播放控制；
- 文学化状态提示；
- 2–3 个命运选择；
- 收束命运。

避免复杂 RPG HUD。

## 19.5 状态文学化

后台：

```text
spirituality = 21
exposure = 78
```

用户看到：

> “你的灵性已经接近枯竭。”  
> “有人开始怀疑你的真实身份。”

数值属于引擎，不属于主要叙事界面。

---

# 20. Story Book：把经历变成历史

一次 Episode 完成后生成一本真正的命运故事书。

包含：

- 封面；
- 标题；
- 主角；
- 时间与地点；
- 章节；
- 终章与结局；
- 命运选择路径；
- 已发现秘密；
- 关键人物；
- 重要关系变化；
- 对世界造成的影响。

## 20.1 阅读模式

完整故事以实际发生过的 Narrative Blocks 为主，允许加入必要过渡，但不能在结束后让模型重新改写一篇“差不多”的小说并改变事实。

## 20.2 聆听模式

重用 Story Session 已生成音频，补齐转场和终章，形成完整有声故事。

## 20.3 命运记录

例如：

```text
调查尸体
  ↓
隐藏身份
  ↓
相信陌生人
  ↓
拒绝仪式
  ↓
保护受害者
  ↓
开放结局
```

## 20.4 世界影响

只展示真正写入 World State 的重要结果，例如：

- 某 NPC 死亡；
- 某地点被摧毁；
- 某角色获得新秘密；
- 一个未解决事件被留在城市中。

---

# 21. 跨故事连续性

产品区别于普通故事生成器的核心是：**Episode 之间互相有历史。**

例如：

1. 奥黛丽在 Episode A 调查一次失踪事件；
2. 事件没有完全解决，成为 World Event；
3. 佛尔思在 Episode B 从报纸或关系网络中听到它；
4. 一个原创记者在 Episode C 到达事件地点；
5. 三篇故事共同丰富同一个世界，而非三次独立生成。

长期效果：

```text
Canonical Character
       +
User World Experiences
       =
My World Character
```

---

# 22. Worldline 与平行命运

发生重大分叉时创建新 Worldline，而不是静默覆盖历史。

```text
Worldline A ───────────●────────────→
                        \
                         └──────────→ Worldline B
```

未来能力：

- 查看分叉点；
- 从重要节点创建平行命运；
- 切换主要世界线；
- 比较不同选择造成的长期世界差异。

默认体验仍强调：**已经发生的事情应该具有重量。**

---

# 23. 核心数据对象

V1 需要正式定义：

```text
World
Worldline
Character
Card
CanonFact
KnowledgeFact
Relationship
Memory
WorldEvent
StorySeed
StorySession
StoryState
Choice
StateDelta
NarrativeBlock
Secret
Episode
AudioSegment
```

## 23.1 核心数据链

```text
Card / Character
      ↓
World Context
      ↓
StorySeed
      ↓
StoryState
      ↓
NarrativeBlock
      ↓
Choice
      ↓
StateDelta
      ↓
StoryState
      ↓
NarrativeBlock
```

结束后：

```text
Closure
  ↓
Episode
  ↓
Memory Distillation
  ↓
Character Update
  ↓
Relationship Update
  ↓
World Event
  ↓
World State
```

---

# 24. Runtime 状态机

```text
IDLE
  ↓
CARD_SELECTED
  ↓
WORLD_CONTEXT_LOAD
  ↓
STORY_GENESIS
  ↓
SEED_VALIDATION
  ↓
OPENING
  ↓
NARRATING
  ↓
CHOICE_READY
  ↓
RESOLVE_CHOICE
  ↓
STATE_UPDATE
  ↓
VALIDATION
  ↓
NEXT_BEAT
  └──────────────→ NARRATING
```

结束流程：

```text
CLOSURE
  ↓
EPISODE_FINALIZATION
  ↓
MEMORY_DISTILLATION
  ↓
WORLD_UPDATE
  ↓
AUDIO_FINALIZATION
  ↓
STORY_BOOK
```

---

# 25. 内容与系统分层

底层引擎与《诡秘之主》内容尽量解耦：

```text
World / Story / Character Engine
            ↑
      Canon Content Pack
```

《诡秘之主》的：

- Canon；
- 人物；
- 卡牌；
- 途径；
- Narrative DNA；
- 世界 Lore；

属于内容层。

这样既有利于内容治理，也避免未来产品平台与具体 IP 内容在代码层不可分离。

现有卡牌美术/设定生产体系继续保持独立职责，通过经过审核的 Content Pack 输出给应用使用，而不是把 Story Engine 直接塞进卡牌美术仓库。

---

# 26. 质量体系

质量优先级必须固定为：

```text
世界设定正确
  ↓
人物正确
  ↓
知识边界正确
  ↓
历史连续
  ↓
选择具有因果意义
  ↓
故事精彩
  ↓
语言优美
```

不能为了“更炸裂”牺牲 Canon、人物真实性、位格、时间线与知识边界。

## 26.1 Canon Accuracy

检查：

- 序列能力；
- 能力获得时间；
- 当前身份；
- 组织与时间；
- 世界规则；
- 重大历史；
- 高位知识。

目标：**重大 Canon Violation = 0**。

## 26.2 Character Fidelity

检查：

- 决策是否符合人物；
- 用词是否符合人物；
- 情绪变化是否有原因；
- 是否拥有不应知道的信息；
- 长期经历是否真正产生影响。

## 26.3 Continuity

检查：

- 谁已死亡；
- 谁知道什么；
- 物品位置；
- 时间与地点；
- 伤势与灵性；
- 关系；
- 伏笔；
- World Event。

目标：**Hard Commitment Conflict = 0**。

## 26.4 Choice Meaningfulness

三个选项必须具备策略差异，并至少产生一项可验证的状态变化。

## 26.5 Narrative Quality

评估：

- 悬念；
- 节奏；
- 伏笔；
- 选择压力；
- 因果；
- 结局完整度；
- 世界感；
- 文学表现。

## 26.6 Audio Identity

评估：

- 同一人物跨文本音色一致；
- 情绪演绎不破坏角色身份；
- 旁白 / 角色 / 环境层次清晰；
- 长篇播放无明显断裂和声音漂移。

---

# 27. MVP

MVP 不追求一次实现完整世界，而验证最核心闭环：

> **卡牌 → 人物 → 世界上下文 → 故事 → 抉择 → 后果 → 记忆 → 世界更新。**

## 27.1 建议内容范围

- 3–5 名原著人物；
- 1 条途径的若干序列；
- 一批原创 NPC；
- 1 个重点城市；
- 若干必要组织；
- 最小 Lore Kernel；
- 少量高质量 Soundscape。

## 27.2 MVP P0

必须有：

- World State；
- Character；
- Character Bible；
- Canon Fact；
- Knowledge Boundary；
- Spoiler Profile；
- Story Seed；
- Commitment Ledger；
- Story State；
- Choice；
- Outcome Resolver；
- State Delta；
- Canon Guard；
- Knowledge Guard；
- Continuity Guard；
- Story Closure；
- Episode；
- Memory Distillation；
- Voice Persona；
- 基础 Audio Engine；
- Story Book。

## 27.3 MVP 暂不做

- 多真实用户；
- 社交；
- 联机；
- 玩家交易；
- PvP；
- 完整 RPG 战斗；
- 装备与经济系统；
- 开放地图自由移动；
- 数百 AI NPC 实时自主运行；
- 完整世界沙盒；
- 大规模多角色同时演绎。

---

# 28. 路线图

## Phase 0 - Story Bible / Protocol

先冻结底层协议：

- StorySeed Schema；
- StoryState Schema；
- Choice Contract；
- StateDelta；
- Commitment Ledger；
- Character Bible；
- Knowledge Gate；
- 第一条途径 Narrative DNA；
- 最小 Lore Kernel。

## Phase 1 - Text World Prototype

实现：

```text
选择卡牌 / 人物
  ↓
载入 World Context
  ↓
Story Seed
  ↓
角色第一人称讲述
  ↓
最多 10 次重大选择
  ↓
Closure
  ↓
Episode
  ↓
Memory + World Update
```

优先验证故事质量、一致性与角色真实性。

## Phase 2 - Audio First

加入：

- Voice Persona；
- 多角色与旁白；
- Ambient；
- SFX；
- 分段生成与复用；
- 完整 Story Book 播放。

## Phase 3 - Persistent World UX

加入：

- 世界首页；
- Character Memory；
- Relationship Memory；
- World Events；
- 未解决事件；
- 跨 Episode 连续性；
- 人物长期成长。

## Phase 4 - Worldline / Multi-character

加入：

- 重大 Canon Divergence；
- Worldline；
- 平行命运；
- 双角色故事；
- 不同人物故事交错；
- NPC 晋升长期角色。

## Phase 5 - World Expansion

逐步扩展：

- 22 条途径；
- 更多原著人物；
- 更多城市与时代；
- 更多组织；
- 高序列与特殊存在独立叙事语法；
- 原创人物创建；
- 更完整的声音世界。

---

# 29. 产品成功标准

产品真正成功不是“单次生成质量很高”，而是长期使用以后用户产生以下明确感受：

> **“这个世界记得以前发生过什么。”**

> **“这个人物真的认识以前遇见过的人。”**

> **“这是奥黛丽，但这是我这个世界里的奥黛丽。”**

> **“上一段故事发生的事情，这一次仍然存在。”**

> **“即使没有故事正在播放，我仍然感觉这个世界存在。”**

---

# 30. 核心产品循环

```text
认识世界
  ↓
收藏卡牌
  ↓
进入人物 / 创造人物
  ↓
开启命运
  ↓
聆听故事
  ↓
参与抉择
  ↓
承担后果
  ↓
形成历史
  ↓
改变人物
  ↓
改变世界
  ↓
再次从另一个视角进入
```

---

# 31. 不可动摇的产品原则

1. **世界先于故事。**
2. **角色先于剧情。**
3. **Canon 定义过去，但不锁死未来。**
4. **原著人物必须保持人物真实性。**
5. **原创人物负责扩展原著没有描写的世界。**
6. **每个人物只能知道自己应该知道的事情。**
7. **用户影响人物，而不是操纵人物。**
8. **每一个重要选择都必须产生真实状态变化。**
9. **每一个重要故事都必须留下记忆或世界痕迹。**
10. **故事结束，世界不结束。**

---

# 32. 最终产品叙事

这里不是重新讲一遍《诡秘之主》。

原著告诉了我们一些人的故事，但那个世界远远没有因此停止存在。

在贝克兰德某一扇从未被小说推开的门后，在大海某一段没有被记录的航程中，在某个教会的地下档案室，在某个普通人的梦里，都可能发生着新的故事。

那些我们熟悉的人，也拥有原著没有记录的日子。

用户可以进入原著人物的视角，见证他们新的经历；也可以让一个此前从未存在的人第一次在这个世界醒来。

他们拥有自己的性格、记忆、知识、秘密和关系。

他们会听取用户的意见，但他们仍然是他们自己。

他们可能成功，可能犯错，可能失去某个人，也可能发现不该发现的秘密。

而当故事结束以后，这些事情不会被清空。

人物会记住。关系会改变。地点可能已经不同。某个秘密会继续存在。

下一次，从另一个人的视角再次进入这个世界时，用户会发现：

> **以前发生过的事情，真的已经成为历史。**

因此《诡秘世界》真正创造的不是无限数量的 AI 故事。

# 而是一个能够不断产生故事、记住故事，并因为这些故事而改变的诡秘世界。

---

## 附录 A：首批需要冻结的工程契约

1. `World.schema`
2. `Character.schema`
3. `CanonFact.schema`
4. `KnowledgeFact.schema`
5. `StorySeed.schema`
6. `StoryState.schema`
7. `Choice.schema`
8. `StateDelta.schema`
9. `NarrativeBlock.schema`
10. `Episode.schema`
11. `Memory.schema`
12. `WorldEvent.schema`
13. `Relationship.schema`
14. `VoicePersona.schema`
15. `AudioSegment.schema`

## 附录 B：PRD 后续拆分

本母 PRD 后续建议拆分为：

- 《World Engine PRD》
- 《Character Engine & Memory PRD》
- 《Story Engine PRD》
- 《Canon / Knowledge / Spoiler System PRD》
- 《Audio Engine PRD》
- 《macOS UX / Interaction PRD》
- 《Content Pack & Card Integration Spec》
- 《Evaluation & Quality Gate Spec》

