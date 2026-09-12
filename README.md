# 诡秘之主 · 220 张成神途径卡牌制作脚手架

**版本 0.3.0｜六维语义、混合媒介、单卡精制。**

交付目标：22 条途径 × 序列 9–0，每张一幅独立高清卡面。
六项都要在牌上出现，但不一定以文字出现：**身份—扮演—能力—魔药—晋升—限制**。
这不是六格说明书模板，也不是只有标题的插画库。

## 从这里开始
1. 阅读根 `AGENTS.md` 与 `docs/START-HERE.md`。
2. 阅读 `design/semantic-contract.md`；它定义“画面如何算真正包含一项信息”。
3. 选择当前卡，如 `pathways/fool/sequences/09/card.json`；先补证据，再填写转译方案。
4. 运行下面的命令生成任务单并检查。所有命令在本目录内执行。

```bash
python3 tools/cardctl.py check --level scaffold
python3 tools/cardctl.py status
python3 tools/cardctl.py next
python3 tools/cardctl.py brief --card fool:09 --draft
python3 -m unittest discover -s tests -v
```

需要 Python 3.10 或更新版本。核心工具仅使用标准库，不需要安装依赖、不联网、不请求 API 密钥、不自动调用图像模型。
生成任务位于 `generated/lotm.fool.s09/`。`--draft` 允许研究缺口，不能视作最终出图许可。
证据与单卡方案完成后，运行：

```bash
python3 tools/cardctl.py check --level design --card fool:09
python3 tools/cardctl.py brief --card fool:09
# 实际出图、排版并填写 review.json 后，再执行：
python3 tools/cardctl.py check --level release --card fool:09
```

脚手架刚解压时 design / release 检查**应当失败**：当前没有完成原著核验和正式图片。这是发布阻断机制，不是安装故障。

## 文件职责
```text
AGENTS.md                         全局目标与不可放宽的规则
config/project.json               单一项目配置与交付规格
catalog/pathways.json              22 条工作 ID 与待核验中文工作标签
sources/registry.json              来源登记、访问范围与核验状态
references/manifest.json           真实可用的参考图登记（初始为空）
design/                           六维转译、美术总纲、版式、层次与审核标准
pathways/AGENTS.md                 途径域工作规则
pathways/<id>/AGENTS.md            特定途径设计防错规则
pathways/<id>/direction.json       该途径的原创视觉语言提案
pathways/<id>/canon.json           仅存实际研究过的设定断言（初始为空）
pathways/<id>/sequences/09/card.json 该张卡的唯一结构化方案
.../08 … /00/card.json             其余九张卡位
schemas/                          编辑器可用的 JSON Schema
templates/                        新断言、单卡审核、制作记录模板
examples/                         解释表达机制，不伪装成已完成设定研究
prompts/                          模型无关的人工/Agent任务流程
artifacts/                        将来存放真实原图和成品，初始无图片
tools/cardctl.py                   检查、状态、下一卡、任务编译与完整性验证
tests/                            可重复运行的正常与反例测试
reports/                          本次实际测试与目标核对记录
```

## 现在已经有什么，尚未有什么
已经有：22 条差异化途径视觉提案、220 个唯一卡位、六维字段与转译规则、任务编译器、结构/设计/发布三级检查，以及验收报告。
尚未有：220 张成图、全序列中文名称及完整配方的原著核验、用户批准的美术基线、可复用历史原图。
22 个中文途径标签与愚者十序列等少量名称只是检索种子，`seed_unverified` 不等于“核验通过”。其余序列名留空，绝不填入臆测名称。
`direction.json` 内所有视觉设想是 **art_proposal**，不是正典能力清单；某个意象能否用于具体序列须另核验。

## 基线与版本
默认提案：维多利亚神秘学的精密工艺、塔罗式象征构图、克制的宇宙恐怖；不等于所有牌都深黑或相同边框堆饰。
采用小规模样板校准后再扩张，详见 `docs/workflow.md`。没有样张批准时可以探索，不假装已经批准，也不反复阻塞在索要确认。
所有输出保留版本，修改依赖后重新审核。不得用 `generated/` 中的任务单反向覆盖事实源。

## 文件完整性
```bash
python3 tools/cardctl.py verify-manifest
```
`SHA256SUMS` 记录本次交付文件摘要（不包含其自身与运行后新增的生成物/缓存）。修改文件后摘要不匹配是正常提示，不能因此回滚真实修订。

## 权利边界
本包没有原著全文、第三方卡牌原图或字体文件，也不代表官方授权。公开发行前独立核查素材及授权，数字高清不等于印刷就绪。
详细限制与设计决策见 `docs/LIMITATIONS.md` 和 `docs/DECISIONS.md`。
