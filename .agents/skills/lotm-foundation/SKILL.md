---
name: lotm-foundation
description: 为诡秘之主卡牌生产基础材质、纸张、金属表面和可复用纹理，读取 kind=foundation 的结构化任务，经实际生图、观察、登记交给合成器。
---

# 基础材质与复用范围

读取 `docs/production-sop-v3.md`、现有 `production/schemas/task.schema.json` 与当前kind=foundation任务；五档/旧五档迁移细节见 `docs/production-sop-v2.md`，旧工具字段/CLI以 `docs/production-sop.md` 为准。

material、lighting、tiling、use_scope明确接收面、纹理尺度及复用边界。既有框作真实上下文参考，输出材质不重复框、徽、姓名或主角。人物卡默认主体与背景一体生成，不为凑分层数量额外生成可见背板；统一石板不是22途径的默认基础材质。

基础材质是母版几何锁点 L1 之后的下游资产：材质或反射失败只返修材质层及其授权 mask，不移动 FrameCore、EmblemDock、圣徽、姓名或主体锚点。研究稿、候选和工程可用状态分开记录，不能用一张好看的材质图证明嵌座或整框通过。

涉及品质纹理或宝石时读取 `config/quality-color-tokens.json`；解析五档主色和hue_drift/gem_luminance要求。色值是识别锚点，纹理有深浅冷暖和受控色相流动，不做平涂或整卡滤色。反射随材质与光向变化；无定位功能的纹理可以创作，接框折槽等定位结构归层级/框架任务。

实际执行compile→读prompt→传递真实附件→内置image_gen→观察→call→ingest。未知model/seed为null，尝试预算不借改任务ID重置。素材没有自动批准；背景、可平铺、细节与适用范围经实际观察记录。

姓名艺术字借用kind=foundation登记时，明确name-art专用use_scope，并读取 `../lotm-quality-frames/references/name-art-input.md`；不把文字资产当普通纹理。交付记录实际原生/最终像素、净底与合成状态，不以编译成功冒充生图完成。
