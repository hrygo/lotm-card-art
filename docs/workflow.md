# 制作流程与阶段门槛

## 制作批次
先用愚者途径做样板，不提前自动调用220次图像生成。
建议选择序列9、5、3、1、0观察职业、关系、历史性表达、天使层次与终点主题；这只是项目采样，不是所有途径的统一能力划分。
样板完成后补齐该途径，再挑一条视觉差异显著的途径做交叉检验；随后逐途径扩展。
用户指定某张时先处理该张，不以样板顺序阻止明确请求。未经批准的风格可用来探索，但状态仍为proposed。

## 全序列视觉梯度门槛

设计阶段默认沿 `9→0` 逐步减少人类叙事权重，逐步增加神性、权柄和抽象关系的权重：

- `9–8`：以人类尺度、具体动作和处境为主，能力表现为局部且有因果的效果。
- `7–5`：人物性格/扮演法与非凡效果并存，空间和现实表面开始被改写。
- `4–3`：人物更多作为神性载体、见证者或仪式节点，象征和环境压力上升。
- `2–1`：权柄、规则、化身和概念关系主导，肉身与人格退居次位。
- `0`：非人格权柄、法则和象征结构主导，人形仅为可选的最小身份锚点。

进入 `directed` 前，当前卡的设计记录要明确三件事：人类锚点、神性压力、抽象载体。相邻序列审核要确认变化来自主事件、观察角度、空间关系、人体/环境占比或媒介权重，而不是只换服装或堆叠亮度、王冠、翅膀、触手、黑雾。该梯度是视觉叙事权重，不是道德等级、能力数值，也不允许以抽象氛围掩盖六维事实缺口。

## 阶段
scaffold：卡位已建立，内容未研究。
research：整理与核对证据，可有候选表达。
directed：通过design门槛，六维、构图、文字和误读边界明确。
rendered：已有真实图像，尚不能冒充已经通过审核。
reviewed：已经执行并记录审图，尚需最终批准。
approved：当前方案与图片通过检查，并有真实批准依据。
状态不是凭感觉切换；通过机器结构检查不会自动升级艺术完成度。

## 每次任务的最小上下文
研究：根/路径AGENTS、source-policy、当前canon与来源。
转译：加semantic-contract、当前direction、card、symbol-policy。
构图：加art-bible、layout-system、rank-grammar、typography。
出图：使用编译任务、实际附件和精确文字，不继续让模型发明缺失事实。
审图：加qa-rubric、当前原图/成图/审核记录，先独立回读再对照计划。

## 正常命令
```bash
python3 tools/cardctl.py check --level scaffold
python3 tools/cardctl.py brief --card fool:09 --draft
python3 tools/cardctl.py check --level design --card fool:09
python3 tools/cardctl.py brief --card fool:09
python3 tools/cardctl.py fingerprint --card fool:09
python3 tools/cardctl.py check --level release --card fool:09
```
所有命令从仓库根执行；也可用绝对路径运行，工具用自身位置定位仓库。
brief在`generated/<card_id>/`写入task.md、art-brief.md、overlay-copy.json、semantic-checklist.md和dependencies.json。
它可以覆盖这些派生文件，绝不覆盖card.json、canon.json、人工批准图片或review.json。

## 失败与缺口
缺证据先列待核验项；图像模型不可用时只交付任务单，不能声称已出图。
语义回读失败先修cue和构图，再重出图；不用新增一大段解释绕过牌面缺陷。
精确文字错误优先修排版；局部修图需要实际提供原图，不假装工具已经取得旧卡。
低分辨率输出不通过selected profile；可使用明确记录的后处理，但必须重审细节。

## 一致性与修订
每张card.json的语义/构图及其规则、证据、路径基线组成design fingerprint；production字段的流程更新不参与该摘要。
审核还绑定最终图像SHA256；改图即使不改方案也会使旧审核不匹配。
reference manifest的变动会保守地使相关快照失效；不声明这是最小依赖影响分析系统。
普通用户批准可记录会话或工单位置，不能由Agent自己假造用户名、时间和发言。

## 快照与 tag
tag 是**快照**，不是发布或交付：打 tag 时说明必须附「在途内容清单」（未提交或在途的卡、研究稿、config 改动），并写明 `python3 tools/selfcheck.py` 的自证结果。
tag 名与说明不得暗示批准、release 或内容已核验；`release_approved` 与人工批准状态以各自独立记录为准，不因打 tag 而改变。
