# 单卡操作清单

本清单只在执行单卡时按需读取。命令从仓库根目录执行，持久化文档使用原生命令，不把本机 `rtk` wrapper 写入项目产物。

## 文件映射

| 目的 | 路径 |
| --- | --- |
| 途径工作 ID | `catalog/pathways.json` |
| 途径事实 | `pathways/<pathway_id>/canon.json` |
| 途径视觉提案 | `pathways/<pathway_id>/direction.json` |
| 单卡事实/方案 | `pathways/<pathway_id>/sequences/<seq>/card.json` |
| 来源登记 | `sources/registry.json` |
| 研究记录 | `docs/research/` |
| 编译任务 | `generated/<card_id>/` |
| 图像/音频原始与最终资产 | `artifacts/<card_id>/<stage>/` |
| macOS 试听 fixture | `artifacts/<card_id>/audio-vNNN/`（打包期由 `tools/production.py stage-app-resources` 落入 `.app` 的 `Audio/`） |

## 阶段命令

~~~bash
# 先确认整个脚手架与当前卡位
python3 tools/cardctl.py check --level scaffold

# 研究/概念阶段：允许显式带 --draft
python3 tools/cardctl.py brief --card fool:09 --draft

# design 通过后才生成普通任务快照
python3 tools/cardctl.py check --level design --card fool:09
python3 tools/cardctl.py brief --card fool:09
python3 tools/cardctl.py fingerprint --card fool:09

# 最终资产和审核齐全后再检查 release
python3 tools/cardctl.py check --level release --card fool:09
python3 -m unittest discover -s tests -v
git diff --check
~~~

`brief` 只写 `generated/<card_id>/` 的派生任务文件，不覆盖 `card.json`、`canon.json`、人工批准图片或审核记录。普通模式被阻塞时，修证据/方案，不用忽略退出码放行。

## 六维回读表

每项在单卡记录中至少有一行：

| 维度 | 必须回读的问题 | 常见错误 |
| --- | --- | --- |
| identity | 途径、序列数字和名称能否直接核对？ | 只靠颜色或不稳定徽记 |
| acting | 主体在遵循什么行为原则？ | 站姿、服装替代扮演法 |
| abilities | 哪个对象被什么机制改变？ | 发光手掌、烟雾、无因果法阵 |
| potion | 哪个已核验关键要素进入画面？ | 泛用药瓶冒充配方 |
| ascension | 进入当前序列的门槛/条件是什么？ | 每张都画无意义阶梯 |
| limitations | 具体边界、代价或风险在哪里？ | 暗色、裂纹自动冒充限制 |

## 序列层级渐变回读

“人性占比递减、神性与抽象度递增”适用于完整的 `9→0`，不是序列 0 专属规则。它描述画面叙事权重，不是角色道德评价，也不是能力数值。

| 区间 | 回读问题 |
| --- | --- |
| 9–8 | 远看能否识别人类尺度的主体、动作和具体处境？超凡效果是否局部、即时并有因果？ |
| 7–5 | 人物性格/扮演法与非凡效果是否同时可见？空间变化是否开始压过日常尺度但没有抹除主体？ |
| 4–3 | 人物是否更像神性的载体、见证者或仪式节点？象征和环境压力是否承担了部分叙事？ |
| 2–1 | 权柄、规则、化身或概念关系是否成为主视觉？人格退居次位后，身份和六维事实是否仍可核对？ |
| 0 | 是否以非人格权柄、法则和象征关系为主体，人形仅作残留锚点？是否避免用黑雾、触手或光芒直接冒充神性？ |

跨序列审核还要检查：递进是否体现为主事件、观察角度、空间关系、人体/环境占比或媒介权重的变化，而不是单纯堆叠装饰。

## 资产与批准记录

每个真实资产记录：

- 输入文本或图像的内容摘要；
- 工具/服务、模型和实际参数；
- 生成时间、原始像素、最终像素、后处理；
- 参考资产及其实际附件关系；
- 文件格式、时长（音频）或尺寸（图像）、SHA-256；
- `draft` / `approved` / `reviewed` 的真实依据和审核者/时间；
- 未运行的人工检查、资料缺口和下一步。

文案批准、音频生成、视觉审核和正式收藏是四个独立状态。一个状态通过不能替代另一个状态。

## 音频交付检查

- 只处理已批准的逐字文案；已有批准本地音频时优先复用并校验。
- 需要生成时确认服务健康状态和实际可用音色，不默认注册持久化的自定义 voice。
- API key 通过 macOS Keychain 或用户明确授权的安全配置提供，不写入仓库或 App bundle。
- 记录模型、音色、参数、响应格式，以及音频时长、采样格式和 SHA-256；不记录 token、Authorization header 或完整私密路径。
- 确认音频真实可解码，资源名与 `NarrativeLine.audioResourceName` 一一对应，应用在本地资源缺失时才回退网络合成。
- 服务失败就停止当前音频交付并记录缺口；一次性故障、临时绕行和历史 issue 不写入本 SOP。

## 交付摘要模板

~~~text
卡片：<pathway>:<seq> / <card_id>
阶段：<research|directed|rendered|reviewed|approved>
已完成：<事实/六维/图像/音频/App 接入>
真实文件：<路径 + 格式 + 尺寸/时长 + SHA-256>
检查：<命令与结果>
人工检查：<pass/fail/not_run + 依据>
未决：<事实缺口、视觉候选、硬件或服务限制>
~~~
