<p align="center">
  <img src="docs/assets/logo_160.png" width="128" height="128" alt="诡秘之主卡牌制作脚手架 Logo" />
</p>

<h1 align="center">诡秘之主 · 220 张成神途径卡牌制作脚手架</h1>

<p align="center">
  <strong>22 条成神途径 × 序列 9–0 · 220 张独立高清序列卡牌正面 · 六维语义严谨契约 · 原生画册客户端</strong>
</p>

<p align="center">
  <a href="https://github.com/hrygo/lotm-card-art/actions/workflows/ci.yml"><img src="https://github.com/hrygo/lotm-card-art/actions/workflows/ci.yml/badge.svg" alt="CI 状态" /></a>
  <img src="https://img.shields.io/badge/version-0.3.0-blue.svg" alt="版本 0.3.0" />
  <img src="https://img.shields.io/badge/Python-3.10%2B-3776AB.svg?logo=python&logoColor=white" alt="Python 3.10+" />
  <img src="https://img.shields.io/badge/macOS-26.0%2B-000000.svg?logo=apple&logoColor=white" alt="macOS 26.0+" />
  <img src="https://img.shields.io/badge/dependencies-zero-brightgreen.svg" alt="零第三方依赖" />
  <a href="LICENSE-CODE.md"><img src="https://img.shields.io/badge/License-MIT-green.svg" alt="MIT License" /></a>
</p>

<p align="center">
  <a href="#-项目核心目标">核心目标</a> ·
  <a href="#-核心亮点">核心亮点</a> ·
  <a href="#-快速开始">快速开始</a> ·
  <a href="#-六维语义契约">六维契约</a> ·
  <a href="#-愚者途径研究资料">研究资料</a> ·
  <a href="#-原生画册客户端-lotmcardstudio">画册客户端</a> ·
  <a href="#-工程目录结构">工程目录</a> ·
  <a href="#-三级质量保证门槛">质量门槛</a> ·
  <a href="#-参与贡献">参与贡献</a> ·
  <a href="#-版权与法律边界">权利边界</a>
</p>

---

## 📖 项目核心目标

本项目以小说《诡秘之主》（Lord of the Mysteries）全 **22 条成神途径、每条途径序列 9 至 0，共计 220 张独立高清序列卡牌正面** 为内容生产主线，并提供一个隔离的 macOS 原生画册客户端垂直切片。

220 是美术生产脚手架的序列卡槽基线（22 途径 × 10 序列），不是卡牌上限，也不是客户端收藏分母——同一序列可有多个不同人物的身份卡，同一人物可有跨多个序列的形象卡，实际卡数可超过 220。客户端模型允许一个序列拥有 0…N 张身份卡，
同一角色也可以拥有多张独立身份卡；当前客户端以隔离 fixture 仅展示最新的 S00 愚者先生与 S09 克莱恩两张卡，均已接入卡图、六维、故事与本地配音，不代表正式卡牌已经完成或获最终视觉批准。

> **核心哲学**：
> **六维语义完整，载体自由组合；艺术可以抽象，事实不能含混。**

每张牌必须涵盖六大核心维度：**身份 — 扮演 — 能力 — 魔药 — 晋升 — 限制**。
我们不做刻板生硬的六格卡牌模版，也不做毫无依据的纯空想插画；默认采用序列原型，杜绝将角色偶然外物或高序列力量提前嫁接。

跨途径层级称谓统一从 `config/sequence-hierarchy.json` 读取：当前第五纪序列9–8为低序列、序列7–5为中序列、序列4–1为高序列/半神；序列4–3通常称圣者，序列2–1通常称天使，序列0为真神。天使之王是超越普通序列1但尚未成为真神的状态，不是新的序列；序列0卡也仍是正式序列卡，不是特殊事件。

---

## ✨ 核心亮点

- 🎴 **220 独立卡位与差异化视觉语言**
  在形状、材质、构图和异常发生方式上严格区分 22 条途径，拒绝千篇一律的站姿与触手堆砌。
- ⚡ **零依赖工程化工具链 (`tools/cardctl.py`)**
  仅依赖 Python 3.10+ 标准库，不联网、不请求外部 API、不偷跑收费模型，提供完整的脚手架结构验证、任务编译与状态追踪。
- 🛡️ **严格的事实与创作分离**
  正典断言（原著事实）、资料缺口（诚实记录未知）、解释性概括与美术提案严格解耦，拒绝为凑完成率捏造配方与仪式。
- 🔒 **三级渐进式发布阻断流水线**
  `scaffold`（结构骨架）➔ `design`（六维转译与证据）➔ `release`（真实高清图档与审核快照），层层设卡杜绝劣质打卡。
- 🖥️ **原生 macOS 卡牌画册客户端 (`apps/LotmCardStudio`)**
  基于 SwiftUI 的 macOS 原生 M1 里程碑垂直切片，提供书架画廊、正式/候选/愿望清单、故事抽屉、人工台词审核门槛及本机 SpeechRail 语音接入。

---

## 🚀 快速开始

### 1. 环境准备

- **卡牌制作脚手架**：Python 3.10 或更高版本（纯标准库，无需 `pip install`）。
- **macOS 画册客户端**（可选）：macOS 26.0+，Swift 6.2+ 工具链；当前在 Apple silicon arm64、Swift 6.3.3 环境验证。

### 2. 基础检查与工作流体验

所有命令均在仓库根目录执行：

```bash
# 1. 验证脚手架 220 个卡位与基础结构完整性
python3 tools/cardctl.py check --level scaffold

# 2. 查看全局 22 途径制作状态总览
python3 tools/cardctl.py status

# 3. 智能推荐下一张待制作卡牌
python3 tools/cardctl.py next

# 4. 编译单卡研究草稿任务单（以愚者途径序列 9 占卜家为例）
python3 tools/cardctl.py brief --card fool:09 --draft

# 5. 执行工程自动化测试套件
python3 -m unittest discover -s tests -v
```

> [!NOTE]
> 刚检出的脚手架在执行 `check --level design` 或 `check --level release` 时**应当失败**：当前卡位仍处于研究待填补阶段，这属于发布阻断机制的正常表现，而非代码故障。

---

## 📐 六维语义契约

卡面上的每一个视觉元素都承担着严谨的信息回读职责：

| 维度 | 表达事实或核验边界 | 载体示例（自由组合） | 误读阻断底线 |
| :--- | :--- | :--- | :--- |
| **身份** (Identity) | 准确序列名与序列阶数 (9–0) | 符文、数字刻印、途径特异边框 | 禁止与其他途径或邻近序列混淆 |
| **扮演** (Acting) | 当前序列的行动准则与守则 | 动作、神态、场域交互、仪式姿势 | 必须反映守则内核，不只是静止站姿 |
| **能力** (Abilities) | 该序列获得的可辨认超凡效果 | 视觉现象、光影异变、物质形变 | 禁止提前表现更高序列的专属神能 |
| **魔药** (Potion) | 已核验的关键主辅材料要素 | 物件、背景标本、灵界生物投射 | 未知时使用明确缺口标记，不凭空造物 |
| **晋升** (Advancement) | 进入本序列所需的仪式或环境 | 场景环境、特殊天象、宿命因果关系 | 属于进入当前序列的前提，非下一序列 |
| **限制** (Limitation) | 失控风险、精神异变或负面代价 | 构图负空间、失衡形变、侵蚀暗影 | 必须具有具体边界，不能用笼统暗色敷衍 |

## 📚 愚者途径研究资料

愚者途径的角色故事、序列研究和结构化事实采用“研究稿—正典断言—来源登记”三层索引。研究稿用于持续补全与审核，不代表卡牌已经通过 `design` / `release` 门槛，也不代表其中所有 `lead` 内容已经获得用户批准。

- 📖 [知名角色资料补全与多段关联故事](docs/research/2026-09-14-fool-known-characters-dossier.md)：按姓名、序列、六维信息、口头语和角色身份整理；克莱恩的多个身份分条记录，并串联相关剧情段落。
- 🧪 [序列 9—0 魔药配方、扮演法与晋升研究](docs/research/2026-09-14-fool-sequence-potion-acting-advancement.md)：逐序列整理主材、辅材、扮演原则、晋升条件/仪式、角色实例和资料缺口。
- 🎭 [格尔曼·斯帕罗序列 6 卡牌原材料包](docs/research/2026-09-14-germann-sparrow-s06-card-materials.md)：准备人物身份切片、六维输入、关联故事节点、视觉主事件和资产缺口；明确暂不启动生产流程。
- 🕯️ [扎拉图（Zaratul）卡牌原材料包](docs/research/2026-09-14-zaratul-card-materials.md)：拆分序列 2、序列 1 扎拉图与第四纪扎拉图先祖，准备六维输入、关联故事和视觉边界。
- 🐺 [安提哥努斯（Antigonus）卡牌资料包](docs/research/2026-09-14-antigonus-card-materials.md)：拆分天生奇迹师、半个愚者与霍纳奇斯封印状态，整理家族、夜之国和源堡关联。
- 🌫️ [愚者先生／Mr. Fool 卡牌原材料包](docs/research/2026-09-14-mr-fool-card-materials.md)：制作前研究稿，整理序列 0 神格身份切片、六维输入、关联故事、视觉主事件与既有资产/缺口；当前 App 接入状态以 QA 与生产门禁记录为准。
- 🃏 [序列 0「愚者」研究与卡面转译](docs/research/2026-09-13-fool-s00-research.md)：序列 0 的位阶、配方、仪式、能力与限制边界。
- 🧭 [克莱恩序列 9「占卜家」研究卡](docs/research/2026-09-13-klein-seer-card.md)：人物身份、序列 9 研究、六维转译和制作边界。
- 🗃️ [愚者途径结构化正典断言](pathways/fool/canon.json)：可复用的序列名称、能力、配方、扮演、晋升与资料缺口，按证据状态管理。
- 🔗 [来源登记与证据范围](sources/registry.json)：记录官方中文、官方英文交叉定位及二手研究来源的访问状态和使用边界。

其中，序列 0 的通行配方与仪式保持官方中文设定依据；序列 8—1 的部分完整配方、扮演法和高序列仪式仍以 `lead` 或 `knowledge_gap` 标记，须完成中文底本逐项复核后才能升级状态。

---

## 🖥️ 原生画册客户端 (LotmCardStudio)

位于 [`apps/LotmCardStudio`](apps/LotmCardStudio/)，是《诡秘之主》卡牌画册的原生桌面客户端：

<p align="center">
  <img src="apps/LotmCardStudio/Resources/logo.png" width="96" height="96" alt="LotmCardStudio App Icon" />
</p>

### 当前能力
- 📚 **书架画廊**：M1 fixture 仅展示最新 S00/S09 两张 `klein` 独立身份卡，模型为动态 0…N 预留。
- 🗂️ **三类清单**：正式收藏、候选收藏和愿望清单分开筛选；候选不会因内容确认自动升级。
- 🔍 **大卡面与详情抽屉**：展示身份面板、六维语义回读和第三人称故事；故事抽屉按正常布局流展开，不覆盖右侧面板。
- 🎙️ **SpeechRail 接入**：只连接本机 loopback `http://127.0.0.1:8201`；最新 S00/S09 各接入 6 条新版文案和对应系统音色本地 WAV，优先本地播放，缺失时才请求语音，服务失败时保留文字稿并显示失败状态。
- 🛡️ **人工审核门槛**：只有批准摘要仍与文本匹配的台词/章节进入播放列表，示意 fixture 不代表正典批准。

当前本机 Release 已发布并安装至 `/Applications/LotmCardStudio.app`；发布验证覆盖资源白名单、arm64 架构、macOS 26.0 最低版本、代码签名、自动化测试和真实窗口交互。这里的 App 发布不等同于两张卡的视觉正式 release。
当前未实现：仓库内容导入、SwiftData 用户库、Keychain 设置界面、完整音频缓存、正式卡面资源和卡牌游戏规则。

### 运行与构建
```bash
cd apps/LotmCardStudio

# 运行客户端单元测试（当前 22 项）
swift test

# 运行 SwiftPM executable
swift run LotmCardStudio

# 构建 macOS 原生应用程序包（参数只能是 debug 或 release）
./scripts/build-app.sh debug
./scripts/build-app.sh release
open .build/LotmCardStudio.app
```

若 `Resources/AppIcon.icns` 存在，打包脚本会将其复制到 `.app`；`Resources/CardArt/` 与 `Resources/Audio/` 也会随应用打包；图标不是测试运行的前置条件。
真实构建、视觉验收和 SpeechRail 试听状态见 [`apps/LotmCardStudio/docs/qa/m1-local-run.md`](apps/LotmCardStudio/docs/qa/m1-local-run.md)。

---

## 📂 工程目录结构

```text
.
├── AGENTS.md                         # 全局质量契约与底线准则
├── apps/AGENTS.md                    # 客户端目录增量规则
├── catalog/pathways.json              # 22 条途径工作 ID 与待核验中文标签
├── config/project.json               # 交付规格与全局配置入口
├── config/sequence-hierarchy.json    # 9–0 层级标签单一配置（半神/圣者/天使/天使之王/真神）
├── design/                           # 六维转译、美术总纲、版式与审核规范
├── docs/                             # 架构决策、工作流、证据来源策略
│   ├── START-HERE.md                 # 制作快速上手指南
│   ├── workflow.md                   # 阶段推进流转说明
│   └── DECISIONS.md                  # 架构设计决策记录 (ADR)
├── pathways/                         # 22 途径核心资产
│   └── <pathway_id>/
│       ├── direction.json            # 该途径原创视觉提案
│       ├── canon.json                # 已核验设定断言库
│       └── sequences/<09..00>/
│           └── card.json             # 单卡唯一六维结构化设计方案
├── apps/LotmCardStudio/              # macOS 原生卡牌画册客户端 M1 里程碑垂直切片
│   ├── Package.swift                  # SwiftPM targets 与 macOS 平台声明
│   ├── Sources/                       # Core、Features 与 @main 入口
│   ├── Tests/                         # 客户端领域/交互测试
│   ├── Resources/Info.plist           # .app 元数据（图标资源可选）
│   ├── scripts/build-app.sh            # debug/release .app 打包
│   └── docs/qa/                       # 本机运行与视觉验收记录
├── tools/cardctl.py                   # 核心命令行工具（检查、状态、编译、校验）
├── schemas/                          # JSON Schema 结构约束
├── tests/                            # 自动化回归与反例测试集
└── reports/                          # 验收报告与覆盖率核对记录
```

---

## 🚦 三级质量保证门槛

```mermaid
graph LR
    A[Scaffold 骨架检查] --> B[Design 设计与证据审核]
    B --> C[Release 出图与发布验收]

    style A fill:#1a2332,stroke:#63d9c4,stroke-width:2px,color:#fff
    style B fill:#1a2332,stroke:#e3b063,stroke-width:2px,color:#fff
    style C fill:#1a2332,stroke:#8f78d6,stroke-width:2px,color:#fff
```

1. **`check --level scaffold`（结构级）**：
   核查 22 条途径、220 个序列槽位、Schema 完整性、引用合法性与路径越界防范。
2. **`check --level design --card <id>`（设计级）**：
   核验单卡原著证据链、六维载体完整性、误读阻断声明与艺术缺口记录。
3. **`check --level release --card <id>`（发布级）**：
   校验成品图像的物理分辨率、真实色彩通道、文件哈希一致性以及人工批准签署。

客户端另有独立门槛：`swift test`、debug/release `.app` 构建，以及一次真实窗口验收。
客户端验收不等于 220 张卡牌的 design/release 通过；当前 M1 只证明示意 fixture、布局和失败回退可运行。

---

## 🤝 参与贡献

欢迎共同完善《诡秘之主》220 张序列卡牌的结构化工程！在提交 Pull Request 前，请参阅：

- 📘 [贡献指南 (CONTRIBUTING.md)](CONTRIBUTING.md)：完整的单卡研究、证据填写与提交约定。
- 🛡️ [安全政策 (SECURITY.md)](SECURITY.md)：私密报告漏洞或凭据风险。
- 📜 [行为准则 (CODE_OF_CONDUCT.md)](CODE_OF_CONDUCT.md)：社区协作与沟通规范。
- 💬 [支持与问题分流 (SUPPORT.md)](SUPPORT.md)：提交需求、反馈与讨论渠道。

---

## ⚖️ 免责声明与版权边界

- **同人衍生作品**：本项目为《诡秘之主》读者发起的非盈利粉丝同人开源工程，非官方商业授权产品。
- **知识产权归属**：《诡秘之主》小说世界观、专有名词、设定及相关角色著作权归原著作者 **爱潜水的乌贼** 及 **阅文集团（起点中文网）** 所有。
- **无原著全文**：本仓库严禁录入小说正文全文，所有引用仅限于设定考据与单句事实考证。
- **开源许可证**：本项目软件代码、命令行工具与脚本采用 [MIT 许可证](LICENSE-CODE.md) 开源；内容协议与设计版权边界详见 [NOTICE.md](NOTICE.md)。
