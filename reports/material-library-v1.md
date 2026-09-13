# 公共物料库 v1 / 精细合成 v2 — 首轮交付

验证日期：2026-09-13。范围是深色公共底座与愚者纵向试点，不是全部22途径物料已完成。

## 先看结果

- [四档结构对照](../artifacts/production/material-library-v1/tier-board/final.png)：左上低、右上中、左下高、右下真神。重复插画仅用来控制构图变量，不表示此人物具备四档能力。
- [旧新与接缝对照](../artifacts/production/material-library-v1/comparison-board/final.png)：上排左旧右新；下排同一饰条左矩形叠加、右遮罩/羽化/滤色。
- [新版姓名样卡](../artifacts/production/material-library-v1/r2/fool-low-named/final.png) / [收藏尺寸](../artifacts/production/material-library-v1/r2/fool-low-named-collector/final.png)。仍为匿名原型“无名占卜者”。
- [白底透明检查](../artifacts/production/material-library-v1/r2/alpha-white/final.png) / [黑底](../artifacts/production/material-library-v1/r2/alpha-black/final.png) / [彩底](../artifacts/production/material-library-v1/r2/alpha-color/final.png)。

## 物料清单与输入

单一清单：[catalog.json](../production/library/catalog.json)；接口和CLI：[library/README.md](../production/library/README.md)。

| 类别 | 实际交付 | 状态 |
| --- | --- | --- |
| 可选用栅格 | 5项：旧纸纹、修复冷银、暖金、愚者帷幕、银丝装饰 | pending |
| 新组件 | 12个：4公共组件、4档窗口遮罩、4档愚者结构 | proposed |
| 途径复合标识 | 引用既有愚者0–9共10个原型 | 未重新制作、未批准 |
| 新配方输出 | 11份：4档、姓名标准/收藏2份、alpha3份、接缝2份 | 实际PNG＋完整回执 |
| 对照板 | 2份，另有来源与输出摘要记录 | 评审辅助，不是卡牌交付 |

本轮实际调用内置imagegen五次：4次新图、1次冷银定向编辑。冷银第一稿被发现椭圆渐晕，原稿独立保留在excluded_trials，不算合格可用素材；没有覆盖旧图。姓名插画沿用旧素材，未生成新人像。所有新原图均1024×1536；收藏4096×6144含栅格重采样，declared_native=false。

按lotm-foundation / lotm-hierarchy Skill执行结构化任务、编译、真实附件、生成、观察、ingest；编辑任务真实附带旧冷银原图。精确输入位于production/tasks/material-*.json和production/calls/material-*.json，未知model/seed留null。

## 程序结果

新增tools/materialctl.py和tools/render/materials.swift；旧production.py/compose.swift保持原样，旧样卡门禁仍通过。
v2支持有序栅格/矢量分组、命名矩形锚点、路径/椭圆/矩形alpha遮罩、偶奇孔洞、羽化、4种混合、亮度/饱和度、接触阴影；文字在目标像素尺寸重新排版，姓名从subject读取且最后叠加。
现阶段是二维分层合成，不是PBR材质或智能主体抠图。锚点不是自动构图算法；不具备自动脸部保护裁切。原始插画的头部靠近窗口上缘，后续应增加焦点/安全区约束。

两个真实问题已修复：
1. 标题字号42、框高50导致中文溢出，门禁正确报错；扩大到高70，不缩字、不截断，增加真实排版测试。
2. 临时目录迁移揭示绝对路径与macOS /var→/private/var别名问题；统一root.resolve与仓库相对请求路径，并通过无generated缓存的隔离副本测试。

## 验证证据

- `python3 -m unittest discover -s tests -v`：107项全部通过，40.254秒，无跳过；其中本轮新增28项。
- `python3 tools/cardctl.py check --level scaffold`：22途径、220卡位，0错误。
- 清单11个当前输出的material gate全部通过（由test_every_recipe_and_output_is_current逐项验证）；收藏版另行CLI复核尺寸4096×6144、sRGB。
- `--release`实测退出2：material-study不能正式发布。
- 原v1姓名样卡composition gate仍通过；没有修改正典或自动批准记录。
- 输入alpha全解码统计：银丝原图1,388,111全透明像素、184,753半透明像素。是真透明，不是仅有alpha通道；白底实际观察未见矩形黑底。
- 原生像素测试覆盖孔洞、羽化边界、multiply/screen、有序遮挡、亮度和阴影；篡改源任务、组件或最终图会阻断；漏绑输出也会阻断。
- `git diff --check`通过；未提交、未推送。客户端两个并行修改文件没有由本任务编辑。

## 视觉观察与剩余工作

实际观察了原图、白底诊断、四档与旧新对照板、新版姓名缩略图。旧顶部矩形底的拼贴边界明显减弱；新样卡避免装饰条与核心数字重叠。四种窗口轮廓可区分，但这不是用户盲测结果。
银丝在缩略图上较细，高序列与真神的力量层级仍主要依赖窗口结构；真神顶部小菱形靠近说明文字，样板排版仍可精修。暖金原始颗粒偏粗，配方低饱和/细带使用；不声明无缝平铺。
十个数字与帷幕根形仍是旧原型，艺术融合没有在本轮重做；不能宣称22途径高辨识度已达成。
所有资产均待用户视觉批准。第二途径扩展测试、其余21途径、浅底物料体系、正式v2卡牌release接入和用户混淆测试仍未完成，已登记gaps。

当前有效输出仅catalog.json指向的material-library-v1/r2；更早material-studies和首轮根目录输出是调试证据，因代码/配方变更而失效，不再计为当前交付。
对照板使用同一原生合成器直接合成已经gate的单图，其provenance.json绑定全部来源、程序、请求与输出；不把多卡比较板冒称独立卡牌。

## 执行计划调整

没有增加仅为列举固定配方的material_studies.py：catalog.render_jobs已能表达任务清单，直接使用现有CLI，避免第二套调度逻辑。其余首轮任务均按测试、真实出图、观察、门禁推进。后续先做此轮视觉验收，再确定第二途径，而不是自动连续付费生成全系列。
