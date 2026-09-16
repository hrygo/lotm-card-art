<p align="center">
  <img src="docs/assets/logo_160.png" width="128" height="128" alt="诡秘之主序列卡牌制作工具 Logo" />
</p>

<h1 align="center">诡秘之主 · 序列卡牌制作工具</h1>

<p align="center">
  <strong>22 条成神途径 × 序列 9–0 · 220 个序列卡槽 · 六维语义严谨契约 · 分层卡面生产线（零第三方依赖 · Python 3.10+）</strong>
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
  <a href="#-制作文档与工具索引">文档索引</a> ·
  <a href="#-工程结构">工程结构</a> ·
  <a href="#-三级质量保证门槛">质量门槛</a> ·
  <a href="#-参与贡献">参与贡献</a> ·
  <a href="#-版权与法律边界">权利边界</a>
</p>

---

## 📖 项目核心目标

本项目以小说《诡秘之主》（Lord of the Mysteries）**22 条成神途径 × 序列 9→0、共 220 个序列卡槽**为内容生产主线。`220` 是序列卡槽的基线数量（22×10），是下限而不是卡牌上限：同一序列可容纳多个不同人物的身份卡，同一人物也可有跨多个序列的形象卡，实际卡数可超过 220，各用独立 `card_id` 分开管理。

跨途径层级称谓统一从 [`config/sequence-hierarchy.json`](config/sequence-hierarchy.json) 读取：序列 9–8 低序列、7–5 中序列、4–1 高序列/半神（4–3 圣者、2–1 天使）、序列 0 真神；天使之王是超越普通序列 1 但尚未成为真神的状态，不是新序列。序列 0 仍是正式序列卡位，不是特殊事件。

> **核心哲学**：
> **六维语义完整，载体自由组合；艺术可以抽象，事实不能含混。**

起点见 [`docs/START-HERE.md`](docs/START-HERE.md)（“先选一张，不先填满 220 张”），制作入口索引见 [`docs/card-production-index.md`](docs/card-production-index.md)。

**职责边界（2026-09-16 裁决，见 [`docs/DECISIONS.md`](docs/DECISIONS.md) D24）**：本仓库的职责是**卡牌制作**。macOS 画册客户端、世界外壳与 IP 中性引擎属于《诡秘世界》产品本身，归属 [`hrygo/WorldofMysteries`](https://github.com/hrygo/WorldofMysteries)；本仓库内的 `apps/`、`packages/`、`docs/product/` 与客户端设计 token 投影**暂时保留**、不再扩写，也不作为本仓库的主动交付目标。

---

## ✨ 核心亮点

- 🎴 **220 个序列卡槽与差异化视觉语言**
  在形状、材质、构图和异常发生方式上严格区分 22 条途径，拒绝千篇一律的站姿与触手堆砌。
- ⚡ **零依赖工程化工具链 ([`tools/cardctl.py`](tools/cardctl.py))**
  仅依赖 Python 3.10+ 标准库，不联网、不请求外部 API、不偷跑收费模型，提供完整的结构验证、任务编译与状态追踪。
- 🛡️ **严格的事实与创作分离**
  正典断言（原著事实）、资料缺口（诚实记录未知）、解释性概括与美术提案严格解耦，拒绝为凑完成率捏造配方与仪式。
- 🔒 **三级渐进式发布阻断流水线**
  `scaffold`（结构骨架）➔ `design`（六维转译与证据）➔ `release`（真实高清图档与人工批准快照），层层设卡杜绝劣质打卡。
- 🎨 **分层美术生产与原生画布 ([`production/`](production/) · ADR-003)**
  Foundation / Hierarchy / Subject / Symbols 四段工业流；中间不转 2K、不裁切回填，整卡验收后一次全画布采样。

---

## 🚀 快速开始

### 1. 环境准备

- **卡牌制作工具**：Python 3.10 或更高版本（纯标准库，无需 `pip install`）。
- **macOS 画册客户端**（可选，保留面）：macOS 26.0+ 与 Swift 6 工具链，arm64。

### 2. 基础检查与工作流体验

所有命令均在仓库根目录执行：

```bash
# 1. 验证 220 个卡槽与基础结构完整性
python3 tools/cardctl.py check --level scaffold

# 2. 查看全局 22 途径制作状态总览
python3 tools/cardctl.py status

# 3. 智能推荐下一张待制作卡牌
python3 tools/cardctl.py next

# 4. 编译单卡研究草稿任务单（以愚者途径序列 9 占卜家为例）
python3 tools/cardctl.py brief --card fool:09 --draft

# 5. 全工程自动化自证（骨架 / 活契约 pin / 设计 Token / 愚者物料与合成门禁 / 测试套件）
python3 tools/selfcheck.py

# 6. 执行工程自动化测试套件
python3 -m unittest discover -s tests -v
```

> [!NOTE]
> 刚检出的仓库在执行 `check --level design` 或 `check --level release` 时**应当失败**：卡位仍处于研究待填补阶段。这属于发布阻断机制的正常表现，不是代码故障；忽略退出码属于违规。

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

完整转译标准见 👉 [六维语义契约 (design/semantic-contract.md)](design/semantic-contract.md)。

---

## 📚 制作文档与工具索引

| 环节 | 入口 | 效力 |
| :--- | :--- | :--- |
| 制作上手顺序 | [`docs/START-HERE.md`](docs/START-HERE.md) | 指南（非规范） |
| 阶段流转与最小上下文 | [`docs/workflow.md`](docs/workflow.md) | 规范·当前 |
| 当前分层生产 SOP v3 | [`docs/production-sop-v3.md`](docs/production-sop-v3.md) | 规范·当前 |
| 开工/返修/交付预检 | [`docs/production-preflight.md`](docs/production-preflight.md) | 执行约定 |
| 载体·框徽·文字区细则 | [`docs/pathway-carrier-sop.md`](docs/pathway-carrier-sop.md) | 侧车细则 |
| 叙事/台词/声音合同 | [`docs/card-narrative-contract.md`](docs/card-narrative-contract.md) | 规范·当前 |
| 证据等级与来源边界 | [`docs/source-policy.md`](docs/source-policy.md) + [`sources/registry.json`](sources/registry.json) | 规范·当前 |
| 单卡制作规则 | [`pathways/AGENTS.md`](pathways/AGENTS.md) + [`pathways/README.md`](pathways/README.md) | 目录级规则 |
| 分层生产规则 | [`production/AGENTS.md`](production/AGENTS.md) | 目录级规则 |
| 架构决策 | [`docs/DECISIONS.md`](docs/DECISIONS.md) + [`docs/decisions/`](docs/decisions/) | 决策记录 |
| 当前边界与未执行事项 | [`docs/LIMITATIONS.md`](docs/LIMITATIONS.md) | 边界声明 |

单卡研究稿与资料包见 [`docs/research/`](docs/research/)（克莱恩序列 9、愚者序列 0、格尔曼·斯帕罗、扎拉图、安提哥努斯等）。研究稿与 [`docs/superpowers/`](docs/superpowers/) 计划是草稿，**不是** canon、批准或已核验事实。

---

## 🖥️ 暂时保留面：macOS 画册客户端

位于 [`apps/WorldOfMysteries`](apps/WorldOfMysteries/)，归属《诡秘世界》产品（仓库 [`hrygo/WorldofMysteries`](https://github.com/hrygo/WorldofMysteries)），按 D24 在本仓库**暂时保留、不再扩写**：M1 跑通书架画廊、三类清单、详情抽屉与 SpeechRail 本机语音；M2 建立「世界 / 卡牌 / 人物 / 故事书」四个一级区域。它显示的卡片是隔离的合成示例数据（fixture），不计入交付数量，也不代表内容核验或视觉批准。

```bash
cd apps/WorldOfMysteries
swift test                       # 客户端领域与交互测试
./scripts/build-app.sh debug     # 构建 .app（debug | release）
```

规则与测试契约见 👉 [`apps/AGENTS.md`](apps/AGENTS.md)，验收记录见 [`apps/WorldOfMysteries/docs/qa/`](apps/WorldOfMysteries/docs/qa/)。

---

## 📂 工程结构

```text
.
├── AGENTS.md                     # 本仓库全局契约与路由
├── catalog/pathways.json         # 22 条途径工作 ID
├── config/
│   ├── project.json              # 交付规格、六维、阶段与设计文档入口
│   ├── sequence-hierarchy.json   # 9–0 层级标签单一来源
│   ├── quality-color-tokens.json # 五档生产配色
│   └── production-resolution-policy.json  # 分辨率与工作画布策略（ADR-003）
├── design/                       # 六维转译、美术总纲、版式、层级语法、审核规范
├── docs/                         # 工作流 · SOP · ADR · 研究 · 评审 · 证据策略 · 决策
│   ├── START-HERE.md             # 制作快速上手
│   ├── production-sop-v3.md      # 当前分层生产入口
│   └── DECISIONS.md              # 决策记录（D01–D25）
├── pathways/<id>/                # direction.json + canon.json + sequences/<09..00>/card.json
├── production/                   # 分层生产 tasks/calls/compositions/schemas/symbols
├── artifacts/                    # 不可覆盖的 raw/final/preview/provenance
├── generated/ reports/ references/   # 派生 · 报告 · 参考（非事实源）
├── schemas/ templates/ examples/ prompts/  # 结构约束与模式参考
├── tools/                        # cardctl.py · production.py · check_required_checks.py · selfcheck.py · render/*.swift
├── .github/                      # required-checks.json（必需检查名契约）· workflows/ · CODEOWNERS
├── tests/                        # Python 回归与反例测试
├── .agents/skills/               # lotm-card-production-sop|foundation|hierarchy|subject|symbols|quality-frames
├── apps/WorldOfMysteries/        # [保留面] macOS 客户端（归属《诡秘世界》，本仓库暂存）
├── packages/                     # [保留面] IP 中性引擎层契约占位（未实现）
└── docs/product/                 # [保留面] 母 PRD 与 macOS 交互 PRD（归属《诡秘世界》）
```

分层与依赖方向的单一说明见 [`docs/architecture/layering.md`](docs/architecture/layering.md)（约定，未机器强制；ADR-006）。

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

1. **`check --level scaffold`（结构级）**：核查 22 条途径、220 个序列槽位、Schema 完整性、引用合法性与路径越界防范。
2. **`check --level design --card <id>`（设计级）**：核验单卡原著证据链、六维载体完整性、误读阻断声明与艺术缺口记录。
3. **`check --level release --card <id>`（发布级）**：校验成品图像的物理分辨率、真实色彩通道、文件哈希一致性以及人工批准签署。
4. **全工程自证**：`python3 tools/selfcheck.py` 串联骨架、活契约 pin、设计 Token、愚者物料与合成门禁、测试套件。

结构检查 ≠ 事实正确 ≠ 图像表达清楚；三者分别验证。机器门禁通过**不等于**人工批准——批准只能来自用户，且须落入独立人类 sidecar（见 `docs/DECISIONS.md` D16）。

---

## 🤝 参与贡献

欢迎共同完善《诡秘之主》220 个序列卡槽的结构化工程！在提交 Pull Request 前，请参阅：

- 📘 [贡献指南 (CONTRIBUTING.md)](CONTRIBUTING.md)：完整的单卡研究、证据填写与提交约定。
- 🛡️ [安全政策 (SECURITY.md)](SECURITY.md)：私密报告漏洞或凭据风险。
- 📜 [行为准则 (CODE_OF_CONDUCT.md)](CODE_OF_CONDUCT.md)：社区协作与沟通规范。
- 💬 [支持与问题分流 (SUPPORT.md)](SUPPORT.md)：提交需求、反馈与讨论渠道。

---

## ⚖️ 版权与法律边界

- **同人衍生作品**：本项目为《诡秘之主》读者发起的非盈利粉丝同人开源工程，非官方商业授权产品。
- **知识产权归属**：《诡秘之主》小说世界观、专有名词、设定及相关角色著作权归原著作者 **爱潜水的乌贼** 及 **阅文集团（起点中文网）** 所有。
- **无原著全文**：本仓库严禁录入小说正文全文，所有引用仅限于设定考据与单句事实考证。
- **开源许可证**：本项目软件代码、命令行工具与脚本采用 [MIT 许可证](LICENSE-CODE.md) 开源；内容协议与设计版权边界详见 [NOTICE.md](NOTICE.md)。
