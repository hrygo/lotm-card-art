---
name: lotm-hierarchy
description: 为诡秘之主卡牌生产低序列、中序列、圣者、天使、真神五档边框材质、层级物料及框徽承接件，读取结构化任务，经实际生图、观察和登记交付。
---

# 五档品质与层级物料

读取 `docs/production-sop-v3.md`、`config/quality-color-tokens.json`、`config/sequence-hierarchy.json`、现有task schema与当前kind=hierarchy任务。v2仅作历史迁移参考，旧CLI合同见 `docs/production-sop.md`。

分辨率合同固定为“原生工作画布优先、最终整卡一次采样”：母版、五档边框、宝石、承接件和诊断层都保持 Agentic 实际 `native_canvas`，不得中间转 2K、裁切回填、分别把各层转 2K 后拼接或从 2K 反向修复。只有完整卡通过视觉与结构验收后，才从同一份完整原生卡整幅无裁切生成 `2048×3072`；需要收藏版时直接从该原生卡生成 `4096×6144`。处理链和 `intermediate_2k_count=0` 写入 manifest。

## 色彩与结构分工

视觉品质为低序列、中序列、圣者、天使、真神；序列映射和HEX仅从配色配置解析，不复制手写色表。圣者/天使在事实分类中仍属高序列；不改正典分类来迁就视觉分档。

层级主色重点作用于边框纹理、珐琅嵌饰和宝石设计。遵循配置中的受控色相流动：凹槽、起伏、反射与体色有层次，允许局部偏色但保持档位识别。宝石有明亮切面、近白亮点、内部折射和小范围火彩，不变成泛白光团。人物背景、姓名、整枚徽章不自动染色。

五档共用母框轮廓、内部折槽、框肩、姓名牌、宝石槽与锚点。品质不靠加构件、加宝石、扩大徽章或堆辉光。材质可在已定区域变化，结构正本可为精美栅格，不要求用简陋矢量替代。整框重生成只提供候选，不能靠外轮廓裁切认证内部零漂移。

## 输入与执行

按 `docs/production-preflight.md` 先检查当前工具是否支持目标品质与区域处理，将该文件作为 contracts 依赖。未接入五档的工具不承担五档交付；可以准备候选与输入，不反复调用旧 all 验证一个已知不支持的目标。

输入包含 quality.sequence/visual_tier、相同的 spec.tier、母框及摘要、geometry_id、纹理/宝石区域、身份保护域、光向、clear_regions、真实参考用途和预算。primary 从色表解析，不另存可漂移的手写色值。几何/材质扩展写侧车 brief，经 contracts 路径/摘要绑定；实际图像附件仍放 references。编译器自动追踪当前 SOP/色表和声明的侧车，不自动转译 prompt 或递归收集任意 JSON 路径。

框纹理、EmblemDock 承托、连接帷幕与相应宝石归同一 material_group，共用锚色、光向和反射环境，但不同材质保留自己的明暗深度。纹理、宝石、保护区分别设 mask；不出现框已换档而嵌座/连接件仍旧紫的断裂。新结构接口见 `production/templates/emblem-dock-interface-v1.json`，机器约束见 `production/schemas/emblem-dock.schema.json`：母版拥有固定嵌座，圣徽只作为独立可替换本体；逐枚数字仍需实测可见 bbox、实心接点和孔洞保护。旧 `frame-emblem-interface.json` 仅作历史模板，不是新结构合同，也不是现成渲染配方。

当 Agentic 生成了五档完整边框研究稿时，研究稿不能只展示而不进入成品：优先把完整原生画面作为视觉资产，必要的透明净化、孔洞清除、可见 bbox 和固定锚点测量都在原生画布完成；不得把宝石裁成中间 2K 层再嵌回边框，也不得用局部重绘替换 Agentic 已确认的宝石。钻石的五档变化来自体色、切面、内部折射和局部火彩；输出仍是五档一对一，不与十枚序列圣徽做 5×10 交叉组合。源图摘要、alpha、可见 bbox、固定锚点和最终一次采样字段必须写入 manifest 并由 gate 重算。

母框与 EmblemDock 先由 Agentic 创作与样件审定，再冻结结构、派生品质；圣徽本体另行创作、净底和定位。默认采用视觉嵌孔而非让主体背景透出的真实透明孔，承托不得随圣徽重复生成。愚者双侧帷幕是已接受实例，不是所有途径模板。需要结构/净底/装配时使用lotm-quality-frames。

交付按锁点推进：先冻结 `FrameCore + EmblemDock` 的 L1 几何，再派生五档材质和宝石；L1 通过后不得因材质或单枚圣徽问题重生母版。嵌座断裂只返修 EmblemDock，颜色/反射问题只返修 `QualityMaterial`，两者均保留冻结锚点。每次输出标明 `study/candidate/measured/approved/release` 状态，不能用生成目录名或自评替代证据。

compile→读 prompt→真实附件→内置 image_gen→看图→call→ingest→原生视觉验收→最终整卡一次采样→gate；检查 alpha 实际像素，不以棋盘格替代透明。所有中间输出保持原生候选，批准绑定具体原生版本与最终交付版本。

旧foolkit是四档硬编码，仅作历史审计；新活动资产必须使用独立的五档版本化套件，不能将旧all输出改名视作五档完成。本轮愚者任务固定验证低/神跨度、圣者/天使区分、十枚已批准融合圣徽和零漂移，再进入可视材料研究与合成；不以旧四档结果回填任何五档交付。

当前任务 schema 接受 saint/angel，并强制它们携带匹配的 quality 输入；新五档任务不得用 high 代替。旧 high 只用于历史四档任务兼容。活动五档装配统一走 catalog/manifest 指定的版本化渲染器，其 manifest/gate 负责摘要、alpha、几何、EmblemDock 接口和逐枚定位；不得由 Skill 猜测工具版本，也不得把旧 `compose/foolkit` 作为新五档入口。
