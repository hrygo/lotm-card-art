# 愚者途径三文字区边框模板实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]` syntax for tracking.

**Goal:** 将愚者途径卡片边框升级为严格锁定几何的 v2 模板：左右仍为柱状骨架，仅在文字处增加略宽的局部铭刻带；中央姓名为唯一全宽面板；序列圣徽共 10 枚且每枚只绑定其数字所属的一个品质档位，圣徽、边框纹理与底部宝石使用五档分层配色。
**Architecture:** 以结构化 catalog、几何锁、颜色 token 和独立素材 manifest 作为单一事实源；Agentic 图像只负责材质/承接/宝石研究；程序负责固定几何、圣徽调色、文字排版、合成、哈希和门禁。v1 资产保持只读历史版本，v2 采用新输出目录和新 manifest。
**Tech Stack:** Swift 6.2/CoreGraphics/CoreText raster renderer, JSON schema/manifest, Python unittest, existing project gate scripts, imagegen agentic generation, PNG RGBA sRGB.

## Global Constraints

- 只修改愚者途径边框模板及其生产链，不扩展到其他途径或 220 张卡。
- 不生成或合成“序列 01–序列 09”字样；序列身份使用艺术数字和规范序列名，卡面文字由程序排版。
- 主体插画内不放任何文字；本计划只生成载体与试装示例。
- 圣徽总量为 10 枚，不是 5×10：9、8 属低序列银白；7、6、5 属中序列翡翠；4、3 属圣者秘蓝；2、1 属天使典藏紫；0 属真神橙金。
- 圣徽调色只改变材质 RGB 与受控高光/暗部色相；alpha、外轮廓、孔洞、数字骨架、承接定位和输出尺寸必须保持不变。
- 所有几何以 1024×1536 design space 定义，再按比例映射到 2048×3072 final space；不得使用视觉猜测定位。
- 卡框、圣徽和文字区保留可编辑分层；任意生成的带文字图片仅作研究参考，不作为正式文字来源。
- 任何 gate 非零都不能标记完成；视觉审核与结构门禁分开记录。

---

## Task 1: 建立 v2 结构契约与测试基线

- [x] 新建 production/schemas/card-text-panels.schema.json，限定字段 pathway_name、sequence_name、character_name，限定三种区域类型 left-column-inlay、right-column-inlay、central-nameplate，禁止占位符和未声明字段。
- [x] 新建 production/templates/card-text-panels.json，写入中央姓名面板、左右局部铭刻带、留空圣徽安全区、文字安全边距及无文字原型规则。
- [x] 新建 production/symbols/quality-frame-three-text-direction.json，锁定 design space 几何：左右柱体连续；左右铭刻带宽度为相邻柱体主体宽度的 1.15 倍，允许验证区间 1.12–1.18；铭刻带仅覆盖文字局部纵向范围；中央姓名面板为唯一全宽文字面板；底部宝石中心沿用 (512,1429)，视觉尺寸为 v1 的 1.28 倍。
- [x] 为 production/symbols/fool-five-tier-kit.json 增加 v2 layout/recipe/output 标识、10 枚 emblem 的 tier 绑定和五档颜色引用，保持数字到档位映射为单值映射。
- [x] 新建 tests/test_fool_three_text_zones.py，先写失败测试：契约字段、映射唯一性、10 枚总数、左右 1.12–1.18 宽度、中央唯一全宽面板、底部宝石放大、旧四档和 50 枚命名模式拒绝。
- [x] 运行 python3 -m unittest tests.test_fool_three_text_zones -v，确认基线测试按预期失败，并记录失败原因，随后只提交契约与测试基线。

## Task 2: 生成 v2 视觉研究资产

- [ ] 建立 production/calls/fool-three-text-template-v1.json，记录实际模型、时间、参考输入、无文字约束和几何意图；调用 imagegen 生成中央姓名面板与左右局部铭刻带的材质研究图。
- [ ] 建立 production/calls/fool-diamond-v2.json；以 v1 底部宝石和五档 token 为参考，调用 imagegen 生成更高精度、多切面、可控高光和五档材质变化的研究图。
- [ ] 将研究结果登记到 artifacts/production/fool-three-text-template-v1/raw.png 与 artifacts/production/fool-diamond-v2/raw.png，记录尺寸、哈希、工具、参考资产和视觉审核状态。
- [ ] 使用 view_image 检查研究图：确认没有可读文字、没有整体侧面板、没有扩大圣徽、没有改变卡框外轮廓；不通过的研究结果保留为 rejected 记录，不进入正式输出。

## Task 3: 先完成核心渲染器的 TDD 接口

- [ ] 在 tools/render/foolkit5.swift 中补充 emblemTier(for:mapping:)、colorizeEmblem(_:tier:profile:) 和 alphaDifference(_:_:)，为每个数字解析唯一档位并在调色后逐像素核对 alpha 不变。
- [ ] 将固定材质流程拆出 emblem、frame texture、gemstone 三类受控区域；主色只进入目标材质，愚者途径的烟紫身份色保留为次级凹槽/阴影，不覆盖五档主色。
- [ ] 为 v2 记录 geometry lock、catalog hash、recipe hash、token hash、input hash、output hash 和 predecessor v1；manifest 明确 10 枚圣徽对应 10 个数字，不产生按档位复制的第二维。
- [ ] 扩展 renderer 单元/集成测试，断言 5 个 frame、10 个 emblem、10 个 fool-digit-frame 组合；断言不存在 emblem-数字-tier、digit-frame-tier 或 50 份输出命名。
- [ ] 先运行相关 Swift selftest 与 Python 测试，确认渲染器改动前后失败点均来自已声明的新契约。

## Task 4: 实现三文字区与精细宝石合成

- [ ] 新建 tools/render/fooltext3.swift，提供 fooltext3 selftest、fooltext3 render ROOT OUT FRAME TEXT_JSON、fooltext3 gate ROOT OUT；使用 CoreText 排版，不把文字交给图像模型。
- [ ] 文字输入只允许 pathway_name、sequence_name、character_name；pathway_name 放左局部铭刻带，sequence_name 放右局部铭刻带，character_name 放中央全宽姓名面板；空姓名不绘制占位符。
- [ ] 对每个文字层计算实际 ink bounding box，水平/垂直中心误差不超过 final space 1 px，检查上下左右安全边距和溢出；路径名、序列名和角色名分别输出独立层。
- [ ] 新建 production/symbols/recipes/fool-three-text-zones-v2.json，绑定 geometry lock、color tokens、emblem mapping、CoreText 规则、diamond v2 尺寸和输出目录。
- [ ] 使用研究资产中的材质意图更新 renderer 的铭刻承接纹理和底部宝石切面；所有位置由 geometry lock 计算，禁止手工逐图拖动。

## Task 5: 生成并试装 v2 物料

- [ ] 通过现有 production.py/Swift renderer 编译到 generated/production/bin，生成 artifacts/production/fool-five-tier-kit-v2/。
- [ ] 生成 5 个品质边框、3 个独立文字面板层、1 个文字安全区层、10 个单一颜色绑定的圣徽、10 个带圣徽边框组合和结构诊断图；保留 v1 输出不覆盖。
- [ ] 新建 production/fixtures/fool-three-text-sample.json，使用克莱恩·莫里亚蒂序列九试装数据以及一个无角色姓名原型，确保主体区无任何文字。
- [ ] 用 fooltext3 和合成器生成 artifacts/production/fool-three-text-sample-v1/，输出一张序列九克莱恩·莫里亚蒂试装卡和一张无姓名原型卡。
- [ ] 用 view_image 检查低序列、中序列、圣者、天使、真神各一张及序列九试装卡，重点看左右铭刻带是否略宽但不变成侧面板、姓名是否真正居中、圣徽是否压住文字、底部宝石是否抢主体。

## Task 6: 执行门禁与文档固化

- [ ] 运行 python3 -m unittest tests.test_fool_three_text_zones -v 和 python3 -m unittest discover -s tests -v。
- [ ] 运行 v2 renderer gate、fooltext3 gate、python3 tools/cardctl.py check --level scaffold；所有命令必须以真实退出码判断。
- [ ] 核对 v2 输出尺寸为 2048×3072、RGBA、真实 alpha、无裁断边框、无透视、无手持/桌面摆拍；核对 5 档 token 实际作用于边框纹理和宝石，圣徽各自只绑定一个档位。
- [ ] 更新 .agents/skills/lotm-quality-frames/SKILL.md、.agents/skills/lotm-symbols/SKILL.md、.agents/skills/lotm-hierarchy/SKILL.md，固化三文字区、1.15 局部铭刻带、10 枚单档圣徽、v2 宝石和位置零漂移门禁。
- [ ] 新建 docs/production-sop-v2.md 和 reports/fool-three-text-zones-v2.md，记录事实、创作提案、实际生成、门禁结果、视觉待审项及 v1/v2 边界；不把结构通过写成用户艺术批准。
- [ ] 仅 stage 本计划、v2 生产文件、相关 renderer、测试、技能和报告；运行 git diff --check 后创建独立提交，最后报告实际文件、命令和未解决风险。

## Verification Commands

~~~sh
python3 -m unittest tests.test_fool_three_text_zones -v
python3 -m unittest discover -s tests -v
python3 tools/cardctl.py check --level scaffold
swiftc -O -o generated/production/bin/foolkit5 tools/render/foolkit5.swift
generated/production/bin/foolkit5 selftest
generated/production/bin/foolkit5 prepare . artifacts/production/fool-five-tier-kit-v2
generated/production/bin/foolkit5 gate . artifacts/production/fool-five-tier-kit-v2
swiftc -O -o generated/production/bin/fooltext3 tools/render/fooltext3.swift
generated/production/bin/fooltext3 selftest
generated/production/bin/fooltext3 render . artifacts/production/fool-three-text-sample-v1 artifacts/production/fool-five-tier-kit-v2/fool-9-frame.png production/fixtures/fool-three-text-sample.json
generated/production/bin/fooltext3 gate . artifacts/production/fool-three-text-sample-v1
~~~

## Acceptance Criteria

- v2 结构契约、颜色映射和素材 manifest 可被机器读取并通过 schema/门禁。
- 左右文字区是局部、略宽于柱体的铭刻带；中央文字区是唯一全宽姓名面板；卡框外轮廓与圣徽安全区不漂移。
- 10 枚圣徽完整保留且每枚只有一个所属档位颜色；输出不出现 50 枚交叉变体。
- 五档边框品质通过色彩、纹理和底部宝石精度区分，不靠无止境增加装饰数量。
- 序列九克莱恩·莫里亚蒂试装卡可生成，主体内无额外文字，姓名层由程序精确居中。
- 结构门禁、渲染门禁和全量测试真实通过；视觉批准仍单独等待用户确认。
