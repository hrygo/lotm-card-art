# 愚者途径五档物料 v1

日期：2026-09-13
状态：active five-tier candidate；机器门禁通过；视觉复核已完成初检，等待用户对新材质方案确认；formal release 未批准。

## 交付入口

- [五档边框总览](../artifacts/production/fool-five-tier-kit-v1/five-tiers.png)
- [十序列装配总览](../artifacts/production/fool-five-tier-kit-v1/contact-sheet.png)
- [深底圣徽诊断](../artifacts/production/fool-five-tier-kit-v1/emblems-dark.png)
- [白底圣徽诊断](../artifacts/production/fool-five-tier-kit-v1/emblems-white.png)
- [完整 manifest 与输入输出哈希](../artifacts/production/fool-five-tier-kit-v1/manifest.json)
- [五档资产目录](../production/symbols/fool-five-tier-kit.json)
- [旧四档可恢复清理凭据](../production/retirements/fool-four-tier-v1.json)

本次只处理愚者途径五档公共物料及 9–0 序列装配框，不包含人物插画、姓名艺术字、卡牌背板、音频、客户端接入或其他 21 条途径。

## 五档映射

| 品质档 | 序列 | 主色 | 材质表现 |
| --- | --- | --- | --- |
| 低序列 | 9、8 | 银白 #E8EDF2 | 哑光雾银、克制边缘反射、烟紫凹槽、冷白宝石 |
| 中序列 | 7、6、5 | 翡翠绿 #55B978 | 绿色珐琅与金属边缘反射、烟紫凹槽、绿色宝石 |
| 圣者 | 4、3 | 秘蓝 #4D97D4 | 蓝色晶质反射、银色高光、蓝色宝石 |
| 天使 | 2、1 | 典藏紫 #A66BD6 | 紫色典藏珐琅、折射高光、紫色宝石 |
| 真神 | 0 | 橙金 #F0B23F | 橙金金属、深紫暗部、琥珀宝石与受控高光 |

五档共用一份冻结几何母框、五份固定区域结构蒙版和同一顶部圣徽安全区。层级差异只作用于边框纹理、既有途径凹槽、固定底部品质菱形及其宝石光学；没有新增构件、额外宝石、王冠、翅膀、托座或全图染色。

## 十张序列物料

| 序列 | 品质 | 输出 |
| ---: | --- | --- |
| 9 | 低序列 | [fool-9-frame.png](../artifacts/production/fool-five-tier-kit-v1/fool-9-frame.png) |
| 8 | 低序列 | [fool-8-frame.png](../artifacts/production/fool-five-tier-kit-v1/fool-8-frame.png) |
| 7 | 中序列 | [fool-7-frame.png](../artifacts/production/fool-five-tier-kit-v1/fool-7-frame.png) |
| 6 | 中序列 | [fool-6-frame.png](../artifacts/production/fool-five-tier-kit-v1/fool-6-frame.png) |
| 5 | 中序列 | [fool-5-frame.png](../artifacts/production/fool-five-tier-kit-v1/fool-5-frame.png) |
| 4 | 圣者 | [fool-4-frame.png](../artifacts/production/fool-five-tier-kit-v1/fool-4-frame.png) |
| 3 | 圣者 | [fool-3-frame.png](../artifacts/production/fool-five-tier-kit-v1/fool-3-frame.png) |
| 2 | 天使 | [fool-2-frame.png](../artifacts/production/fool-five-tier-kit-v1/fool-2-frame.png) |
| 1 | 天使 | [fool-1-frame.png](../artifacts/production/fool-five-tier-kit-v1/fool-1-frame.png) |
| 0 | 真神 | [fool-0-frame.png](../artifacts/production/fool-five-tier-kit-v1/fool-0-frame.png) |

十枚圣徽均来自已获用户确认的 0–9 愚者融合视觉基线。每枚圣徽按照自身可见墨迹 bbox 独立计算位置，不复制序列 9 的放置测量；可见高度目标为卡高 15%，中心锁定于顶部安全区。

## Agentic 材质研究

五档研究图由五次独立 Agentic 生图生成，每次实际附带冻结几何母框和对应已确认圣徽作为参考。研究图全部为 1024×1536 RGB 展示图，带不透明展示背景，因此只作为材质意向与调色参考，不作为透明框像素，也没有提升正式审批状态。

| 品质档 | 研究图 | sha256 | 调用记录 |
| --- | --- | --- | --- |
| 低序列 | [raw.png](../artifacts/production/fool-five-tier-material-low-v1/raw.png) | 8840e479e704fe7986c85e27c6d838afec2f6b32b7518c75e8687d2d83a774b3 | [call](../production/calls/fool-five-tier-material-low-v1.json) |
| 中序列 | [raw.png](../artifacts/production/fool-five-tier-material-mid-v1/raw.png) | a15f06033d808dfd863de58180542bd617126f02f59f1fb5b4605c3bba175982 | [call](../production/calls/fool-five-tier-material-mid-v1.json) |
| 圣者 | [raw.png](../artifacts/production/fool-five-tier-material-saint-v1/raw.png) | 0cc0eb7d71257b36b580284553e34566faf4afe4a37f9df15992aa2b02133f7a | [call](../production/calls/fool-five-tier-material-saint-v1.json) |
| 天使 | [raw.png](../artifacts/production/fool-five-tier-material-angel-v1/raw.png) | e39c71d24043234a85d5ee7a6e4faaa9ae7a5d474626234ce384b6bb785dfa8a | [call](../production/calls/fool-five-tier-material-angel-v1.json) |
| 真神 | [raw.png](../artifacts/production/fool-five-tier-material-true-god-v1/raw.png) | d01a4ade113515d92d6b676106e3ca6307436980d229afc62a73ff0879b18e64 | [call](../production/calls/fool-five-tier-material-true-god-v1.json) |

实际观察到的共同点是双侧帷幕、顶部留空、姓名牌、底部单菱形和整体轮廓保持；层级差异集中在受控材质与宝石光学。研究图仅影响确定性 recipe 的材质意向，不允许 Agentic 输出改变几何。

## 工程门禁

- 渲染器：tools/render/foolkit5.swift；renderer sha256 为 3661ad1e210f46ca5096f2095eb485ba21644d0e68120da96ad4b5db5d56b32f。
- recipe sha256：6fd1905b8d5541044f5bdab8be883d1821d2c837223f27981707b8b649a5c8c7。
- 冻结母框 native 尺寸：1024×1536；序列最终输出：2048×3072；PNG、RGBA、sRGB。
- 输出目录共 45 个文件，其中 44 个 PNG 与 1 个 manifest.json。
- 实测输出：5 档边框、10 枚净底圣徽、10 张序列装配框、5 份结构蒙版、深/白底诊断、总览图及预览图。
- gate 实测结果：5-tier；10 compositions；zero geometry/placement drift；real alpha；visual review separate；not release。
- manifest 中五档几何差异为 0，十枚序列装配的几何差异均为 0，圣徽透明度和边框透明度均为真。
- 旧四档映射被显式拒绝；production/symbols/fool-frame-kit.json 已转为 retired-historical，不再作为 active asset 或 fallback。

manifest 的 outputs 字段保存全部 44 个实际输出 sha256；本报告只重复列出序列和研究图哈希，避免形成第二份可漂移的哈希事实源。

全库回归实测：134 项测试中 70 项通过，2 项既有断言失败，62 项因历史素材回执引用的 tools/production.py 摘要过期而报错。该问题发生在旧素材链的通用校验，不影响本报告列出的五档聚焦测试与 foolkit5 gate；未借由重写历史回执来掩盖它。

## 视觉与发布边界

当前已完成的是五档候选物料的生产与机器/视觉初检，不是用户对新材质成品的最终批准。此前“9–0 圣徽全面认可”只确认十枚圣徽的视觉基线，不自动批准五档新配色、边框材质、透明净底细边或正式发布。

旧四档物料已退出 active 集合；旧目录及旧样本的审计记录保留在版本化文本和调用记录中，必要时可从系统废纸篓恢复已清理的输出目录。
