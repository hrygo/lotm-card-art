# 愚者套件运行与交付

本页是旧四档工具的运行合同，不是当前五档品质设计。新任务先读 `config/quality-color-tokens.json` 与 `docs/production-sop-v2.md`。当前任务 schema 已支持 quality 与 saint/angel，但 foolkit 仍将4–1并为high；未完成渲染映射和纹理/宝石区域接入前，不用下列all命令声称生成新五档。已接受的单卡帷幕分支见 `docs/pathway-carrier-sop.md`，它也未自动读取五档配色。

## 工具范围

`tools/render/foolkit.swift`是本地Swift/AppKit专用工具，读取既有母框、融合原图及净底配置，执行程序净底、固定几何材质调色、15%圣徽占高装配。输出为material-study，不联网、不调用付费生图，不生成角色插画或姓名。

根圣徽、专属数字及融合造型来自既有Agentic资产；工具不替代其创作。其他途径、不同母框尺寸、其他层级映射或任意目标占幅不是当前CLI通用参数，不凭参数名称臆造能力。

## 执行

从仓库根目录运行。输出必须是`artifacts/production/`下的新目录；示例名称已存在时选择新的具体版本名。

```bash
mkdir -p generated/production/bin
swiftc -O tools/render/foolkit.swift -o generated/production/bin/foolkit
generated/production/bin/foolkit prepare . artifacts/production/fool-frame-kit-sample-next sample
generated/production/bin/foolkit gate . artifacts/production/fool-frame-kit-sample-next
```

`sample`输出四档材质框及序列9装配，不覆盖全部背景类型；白底的4和双眼孔的8仍需单独检查。全量命令：

```bash
generated/production/bin/foolkit prepare . artifacts/production/fool-frame-kit-next all
generated/production/bin/foolkit gate . artifacts/production/fool-frame-kit-next
```

全量固定输出0–9十张，映射与`config/sequence-hierarchy.json`核对：低9/8、中7/6/5、高4/3/2/1、真神0。当前工具内部固定映射，不会自动消费配置变更；配置变化先停止沿用，调整实现并补测。

## 工程检查与产物

`manifest.json`绑定输入、净底配置、输出PNG与工具源码摘要；gate重建确定性结果进行检查。非零退出即未通过，不忽略失败后继续交付。源码或净底配置改变后产生新输出，不追改旧manifest来消除失配。

目录包含四档透明框、十枚净底徽章、五份固定区域蒙版、十张独立透明卡框、深底预览、四档对照及深/白底圣徽诊断。拼版只供审阅，不替代独立卡框。

原生框1024×1536，徽章1254×1254，合成输出2048×3072，包含重采样；不表述为原生高清细节或超分重建。人物插画和姓名区为空。

工具逻辑修改运行原生反例和全库测试；仅文档修改检查格式、引用与指令一致性，不机械重跑全库。

```bash
python3 -m unittest discover -s tests -p test_foolkit.py -v
python3 -m unittest discover -s tests -v
python3 tools/cardctl.py check --level scaffold
```

当前套件及观察记录从`production/symbols/fool-frame-kit.json`及其报告读取。历史`quality-frame-family.json`、`quality-geometry-lock.json`描述旧候选/旧布局，不覆盖当前入口。

## 版本与可恢复清理

获准清理后，先确定具体旧目录，检查当前清单、配方、测试、回执和报告引用。名称含旧版本不等于无依赖，视觉弃用不等于能直接删除来源文件。

- 保留当前输出及其输入，保留用户明确保护的融合原稿和版本。
- 独立、已被替代、无当前依赖的试装目录优先移入系统废纸篓，不永久删除。
- 被历史配方引用的旧框先保留，或在授权范围内一起处理依赖；不留失效入口，不改写历史证据冒称从未生成。
- 更新记录，明确已移出项目、可恢复及当前位置状态；废纸篓文件不计为当前项目可访问资产。
- 清理后对当前套件运行gate，报告移除范围及恢复方式。清理授权不自动覆盖将来的全部生成物。

## 终态报告

先给实际产物与路径，再说明检查结果、视觉待审项和限制。使用“已生成”“检查通过”“当前不支持”“待用户确认”等对应事实的表述，不以计划或假设代替完成状态。不把总测试数量、历史版本名或一次性缺陷写成永久操作规则。
