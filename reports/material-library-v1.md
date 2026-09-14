# 公共物料库 v1 / 精细合成 v2 — 历史归档

验证日期：2026-09-13；归档更新：2026-09-14。该报告记录首轮 material-study 试装，已不再是当前生产基线。

## 当前结论

首轮生成目录 `material-library-v1/`、`material-studies/` 与 `sacred-slate-master/` 已按用户授权移入 macOS 废纸篓，可从[退役账](../production/retirements/fool-failed-materials-2026-09-14.json)恢复。当前视觉基线请查看[愚者五档原生包](../production/symbols/fool-five-tier-kit.json)及其直接输出目录；本报告中的旧图不再作为生产输入。

## 物料清单与输入

历史清单：[catalog.json](../production/library/catalog.json)；当前入口：[fool-five-tier-kit.json](../production/symbols/fool-five-tier-kit.json)。

| 类别 | 实际交付 | 状态 |
| --- | --- | --- |
| 可选用栅格 | 5项首轮公共材质研究 | 历史、退役 |
| 新组件 | 12个首轮组件研究 | 历史、退役 |
| 途径复合标识 | 引用既有愚者0–9共10个原型 | 未重新制作、未批准 |
| 新配方输出 | 11份 material-study 试装 | 已移入废纸篓 |
| 对照板 | 2份，另有来源与输出摘要记录 | 已移入废纸篓 |

本轮实际调用内置imagegen五次：4次新图、1次冷银定向编辑。冷银第一稿被发现椭圆渐晕，原稿独立保留在excluded_trials，不算合格可用素材；没有覆盖旧图。姓名插画沿用旧素材，未生成新人像。所有新原图均1024×1536；收藏4096×6144含栅格重采样，declared_native=false。

按lotm-foundation / lotm-hierarchy Skill执行结构化任务、编译、真实附件、生成、观察、ingest；编辑任务真实附带旧冷银原图。精确输入位于production/tasks/material-*.json和production/calls/material-*.json，未知model/seed留null。

## 历史程序结果

新增tools/materialctl.py和tools/render/materials.swift；这些工具与配方仍保留作为历史研究接口，不是当前愚者视觉生产路线。
v2支持有序栅格/矢量分组、命名矩形锚点、路径/椭圆/矩形alpha遮罩、偶奇孔洞、羽化、4种混合、亮度/饱和度、接触阴影；文字在目标像素尺寸重新排版，姓名从subject读取且最后叠加。
现阶段是二维分层合成，不是PBR材质或智能主体抠图。锚点不是自动构图算法；不具备自动脸部保护裁切。原始插画的头部靠近窗口上缘，后续应增加焦点/安全区约束。

两个真实问题已修复：
1. 标题字号42、框高50导致中文溢出，门禁正确报错；扩大到高70，不缩字、不截断，增加真实排版测试。
2. 临时目录迁移揭示绝对路径与macOS /var→/private/var别名问题；统一root.resolve与仓库相对请求路径，并通过无generated缓存的隔离副本测试。

## 验证证据

- 2026-09-13 的 `python3 -m unittest discover -s tests -v` 记录为107项通过；该结果随当前物料基线和清理变更失效，不作为本次完成证据。
- `python3 tools/cardctl.py check --level scaffold`：22途径、220卡位，0错误。
- 历史清单的11个 material-study 输出已退役；当前基线由 `python3 tools/production.py check-fool-materials` 逐项验证。
- `--release`实测退出2：material-study不能正式发布。
- 原v1姓名样卡composition gate仍通过；没有修改正典或自动批准记录。
- 输入alpha全解码统计：银丝原图1,388,111全透明像素、184,753半透明像素。是真透明，不是仅有alpha通道；白底实际观察未见矩形黑底。
- 原生像素测试覆盖孔洞、羽化边界、multiply/screen、有序遮挡、亮度和阴影；篡改源任务、组件或最终图会阻断；漏绑输出也会阻断。
- `git diff --check`通过；未提交、未推送。客户端两个并行修改文件没有由本任务编辑。

## 视觉观察与剩余工作

历史观察包括原图、白底诊断、四档与旧新对照板、新版姓名缩略图；它们只说明首轮研究过程，不代表当前五档 Agentic 视觉批准。
银丝在缩略图上较细，高序列与真神的力量层级仍主要依赖窗口结构；真神顶部小菱形靠近说明文字，样板排版仍可精修。暖金原始颗粒偏粗，配方低饱和/细带使用；不声明无缝平铺。
十个数字与帷幕根形仍是旧原型，艺术融合没有在本轮重做；不能宣称22途径高辨识度已达成。
所有资产均待用户视觉批准。第二途径扩展测试、其余21途径、浅底物料体系、正式v2卡牌release接入和用户混淆测试仍未完成，已登记gaps。

当前有效输出不再由本报告或历史 catalog 声明；以当前 Agentic 视觉基线、原生尺寸策略和退役账为准。
对照板使用同一原生合成器直接合成已经gate的单图，其provenance.json绑定全部来源、程序、请求与输出；不把多卡比较板冒称独立卡牌。

## 执行计划调整

历史首轮没有增加单独调度脚本；后续正式生产使用当前 Agentic 母版→五档→十序列路线，最终整卡验收后才进行一次 2K/4K 采样。
