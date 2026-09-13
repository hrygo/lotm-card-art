# 精雕符号资产库 · v1

## 当前愚者五档带圣徽框套件

当前入口是[五档资产目录](fool-five-tier-kit.json)与[五档制作报告](../../reports/fool-five-tier-materials-v1.md)。已生成[五档边框总览](../../artifacts/production/fool-five-tier-kit-v1/five-tiers.png)、[十序列装配总览](../../artifacts/production/fool-five-tier-kit-v1/contact-sheet.png)及[深底圣徽诊断](../../artifacts/production/fool-five-tier-kit-v1/emblems-dark.png)。当前映射为低序列9/8、中序列7/6/5、圣者4/3、天使2/1、真神0；五档采用同一锁定几何与固定坐标材质处理，视觉审核仍待用户确认，未进入formal release。

旧四档目录 fool-frame-kit.json 已标记为 retired-historical，不再是交付入口、active asset 或 fallback；历史记录和工具仅用于审计/回归。

## 新版品质边框样板

最新：已固化[品质边框Skill](../../.agents/skills/lotm-quality-frames/SKILL.md)，并执行“严禁位置漂移”。[母框比例与姓名居中校准](../../artifacts/production/quality-layout-v2/master-aligned-r2/final.png)、[统一几何锁](quality-geometry-lock.json)。圣徽可见高度约增14%，姓名字形双轴实测误差0像素；不再逐档挪姓名补偿漂移。下述三档参考编辑稿均暂不准入正式合成，高阶有已观察位置漂移，另两档因不透明无法通过结构核验。

[四档品质对照](../../artifacts/production/quality-frames-v1/frames/final.png) · [圣徽与姓名试装](../../artifacts/production/quality-frames-v1/emblem-fit-r2/final.png) · [结构化清单](quality-frame-family.json)。
采用低阶母框真实参考派生，固定帷幕骨架与构件数量，用材质及底部单一品质片区分四档。顶部开放，不再用小圆孔。仅母框当前有真实alpha，另三档待净底；高档底部略有几何漂移。属于方向样板而非可发布四档套件，旧图保留。

## 最新补充：完整愚者融合族

用户已认可“母标识→专属数字→Agentic融合”的方法及旧0/4/7/9造型，并明确要求保留。现已补齐1/2/3/5/6/8：[十枚总览](../../artifacts/production/symbol-art-v2/fool-fusion-family/final.png)、[完整清单](fool-fusion-family.json)、[旧稿保留凭据](fool-fusion-preservation.json)。
方法已固化到[lotm-symbols Skill](../../.agents/skills/lotm-symbols/SKILL.md)。艺术认可与透明工程状态分开：旧稿未覆盖，新增稿待确认；十枚当前均需净底。以下v1数据保留为首轮记录，不代表融合族仍只有四枚。

## 首轮记录

本轮通过Agent Skills实际生成，不是矢量占位符。全部为原创美术候选，尚未获得用户批准。

- [22途径圣徽浅底总览](../../artifacts/production/symbol-art-v1/emblems-light/final.png)
- [22途径圣徽深底总览](../../artifacts/production/symbol-art-v1/emblems-dark/final.png)
- [愚者0–9艺术数字](../../artifacts/production/symbol-art-v1/fool-numerals/final.png)
- [四级框与姓名试装](../../artifacts/production/symbol-art-v1/four-tiers-named/final.png)
- [融合造型候选：透明交付失败](../../artifacts/production/symbol-art-v1/fusion-concepts/final.png)

机器接入读取[catalog.json](catalog.json)，原图地址从receipt的raw字段解析；不要扫描目录后把所有PNG都当可用资产。`fusions`为`blocked-alpha`，不可作为透明叠层；`diagnostic_jobs`只是失败展示。
22圣徽、10数字、4框共36个透明候选。四框仅愚者体系，不是22×4已齐。融合只有愚者0/4/7/9造型，原稿与返修均失败，没有220枚可用融合印记。

所有框均有独立姓名铭牌，中文由合成程序排版，不能交给生图猜字。插画关键区域按[窗口实测](frame-window-check.json)避让：原先统一大矩形窗口未满足，高/神需专属遮挡与裁切规则。

复核：`python3 -m unittest discover -s tests -p test_symbols_library.py -v`。
重渲染示例：`python3 tools/materialctl.py render production/symbols/recipes/emblems-light.json --out artifacts/production/symbol-art-v1/emblems-light-new`。输出目录必须是新目录；不覆盖历史。

详细质量边界见[交付报告](../../reports/symbol-art-v1.md)。
