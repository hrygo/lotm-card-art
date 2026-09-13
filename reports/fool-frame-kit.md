# 愚者十张带圣徽框 · 程序合成

2026-09-13。该文件仅保留旧四档实现的历史记录。旧输出 artifacts/production/fool-frame-kit-v3 已在新五档物料通过门禁后按用户授权移入系统废纸篓，可恢复；它不再是当前交付入口、active asset 或 fallback。当前入口转为 reports/fool-five-tier-materials-v1.md。

## 当前入口

- 五档资产目录：production/symbols/fool-five-tier-kit.json。
- 五档制作报告：reports/fool-five-tier-materials-v1.md。
- 五档总览：artifacts/production/fool-five-tier-kit-v1/five-tiers.png。

## 历史旧四档记录

- [十张总览](../artifacts/production/fool-frame-kit-v3/contact-sheet.png)：从左到右，上排0–4，下排5–9。
- [四档框](../artifacts/production/fool-frame-kit-v3/four-frames.png)：从左到右低、中、高、真神。
- 独立透明 `fool-0-frame.png` 至 `fool-9-frame.png`，2048×3072、sRGB；同名 `preview` 为深底预览。
- `frame-low/mid/high/true-god.png` 四份1024×1536透明框；`emblem-0.png` 至 `emblem-9.png` 十份1254×1254净底圣徽；五份固定区域结构蒙版。
- [深底圣徽诊断](../artifacts/production/fool-frame-kit-v3/emblems-dark.png)及[白底诊断](../artifacts/production/fool-frame-kit-v3/emblems-white.png)。
- [结构化入口](../production/symbols/fool-frame-kit.json)、[输入输出哈希清单](../artifacts/production/fool-frame-kit-v3/manifest.json)。

无人物、无姓名文字；姓名铭牌与插画区留空。可见圣徽高度为卡高15%，等比缩放，共享中心；这次是框架试装，不宣称已完成有主体插画的比例验证。

## 方法与保留

旧中、高、神漂移/不透明变体全部未使用。唯一来源是既有Agentic低阶母框，先净化其气氛alpha，建立新的研究版结构基线；四档由原像素位置不变的材质调色派生，保留折槽、姓名牌、宝石形状。品质片只在固定菱形内区变色。不是重新调用Agentic生成四份框，也不是PBR重光照；当前档次差异主要是材质色调、对比度和品质片。

融合徽章使用原Agentic融合造型，程序只净底与装配，没有重新机械拼接数字。大面积中性背景按连通域处理；人工观察定位的小镂空通过结构化种子清理。“4”使用更高的中性亮度下限保留银色浮雕，再定点移除眼孔白底。源图及早期原稿均未覆盖。

首轮样件有面具亮部误抠、铭牌alpha斑驳及品质片矩形调色接缝，已在后续版本修正。v1另发现0/1/2/5/8小镂空残底、4银色浮雕误抠；v2保留了4眼孔白底，v3定点修正。微小边缘残色仍需结合实际插画背景验收；不把具有alpha通道或机器检查通过当作任意背景上完美净底的保证。

## 验证与边界

- 新增 `tools/render/foolkit.swift`，未修改旧 `materials.swift`、`compose.swift` 或旧回执。
- 专用gate实测：10张、4框通过。校验输入/输出/程序哈希、实际框alpha、实心区域RGB与确定性母框派生结果、最终合成alpha及固定位置。输出2048×3072为重采样，非原生高清细节。
- 原生反例：灰底移除、白色高光保留、定点小孔清除、材质处理alpha不变、结构像素变化拒绝；另有实际文件篡改拒绝及输出目录禁止覆盖测试。先失败再实现。
- 全库115项测试通过，77.601秒；scaffold检查22途径、220卡位，0错误；`git diff --check`无报错。
- 此gate是针对当前确定性处理链的专用检查，不是能自动识别任意生成图片内部构件的通用视觉检测器。五份结构蒙版用于固定区域诊断；完整的自动语义分层、通用几何差异可视化和正式release接入尚未完成。
- 已观察四档板、十张总览、全套深/白底诊断，以及定点修复的全尺寸图。四档材质效果、净底细边与新基线仍待用户审阅；未自动批准，未交付正式人物卡。

## 再执行

从仓库根目录，输出必须用新目录：

```bash
mkdir -p generated/production/bin
swiftc -O tools/render/foolkit.swift -o generated/production/bin/foolkit
generated/production/bin/foolkit prepare . artifacts/production/fool-frame-kit-next all
generated/production/bin/foolkit gate . artifacts/production/fool-frame-kit-next
python3 -m unittest discover -s tests -p test_foolkit.py -v
```

工具仅本地读取已有素材；不联网、不付费生成、不覆盖原图。修改工具、净底配置或源图后须新建输出，旧manifest与当前处理链不匹配时gate拒绝。
