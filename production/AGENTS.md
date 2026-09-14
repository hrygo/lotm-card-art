# AGENTS.md — 分层生产系统（production/）

> 目录级增量规则，全局契约见根 `AGENTS.md`。本目录把 `pathways/<id>/` 的语义正本编译为任务、登记真实生图、合成候选并执行门禁；**任务只引用语义，不复制语义**。
> 当前 SOP `docs/production-sop-v3.md`（3.5.0）；被取代的 v1/v2 已移除（见 `docs/DECISIONS.md` D10），不得据此重加已取消的序列名文字。

## 结构 STRUCTURE
- `tasks/`：foundation|hierarchy|subject 三类概念任务示例（可复制成独立 task_id/revision）；`symbols/`：精雕符号库（圣徽/艺术数字/融合印记/序列铭刻/五档 kit，自带 catalog/tasks/calls/recipes）。
- `calls/`：真实工具调用、观察与附件回执（未知 model/seed 留 null）；`compositions/`：素材+矢量+文字合成清单（`fool-09-pilot-named*.json` 是含必需姓名区的**历史契约示例**，其引用的 `foundation-paper`/`hierarchy-low` 回执已随失败物料退役、不可解析，不作为当前模板；其余 pilot 亦仅历史记录）。
- `approvals/`：人工视觉批准 sidecar；`retirements/`：可恢复退役账（Trash）；`fixtures/`：文字面板测试样例；`templates/`：几何/接口合同（fool-mother-frame、emblem-dock、card-text-panels v3–v5）。
- `schemas/`：编辑器契约，`tools/production.py` 执行同一契约的 JSON Schema 子集与跨文件业务门禁；合成由 `tools/render/compose.swift` 执行。
- `symbols/`：当前愚者五档分层基线、十序列 Agentic 完整框和融合圣徽历史参考；`assets/tiers` 与 `assets/fool`：旧四档/矢量研究稿，只读审计，不是当前入口。
- `artifacts/production/`（仓库根）：不可覆盖的 raw/final/preview/provenance；输出只允许新目录。

## 查哪里 WHERE TO LOOK
| 任务 | 位置 | 说明 |
|---|---|---|
| 分层生产 SOP | `docs/production-sop-v3.md` | 当前入口：原生画布，中间不转 2K，整卡验收后一次采样 |
| 开工/返修/交付检查表 | `docs/production-preflight.md` | 逐项判定，不是自动门禁，不自动批准 |
| 当前愚者分层资产 | `production/symbols/{README.md,catalog.json,fool-layered-asset-baseline-v1.json}` | 五档完整原生框、十序列 Agentic 框与历史融合徽参考；以 `check-fool-materials` 为门禁 |
| 符号资产接入 | `production/symbols/{README.md,catalog.json,fool-five-tier-kit.json}` | 按 catalog/receipt.raw 解析，不扫描目录 |
| 任务契约 | `production/schemas/task.schema.json` | kind/mode/spec；subject 必填 slot/card/protagonist/semantic_source |
| 合成契约 | `production/schemas/composition.schema.json` | layers/vector_assets/nameplate/profile |
| 调用回执 | `production/schemas/call.schema.json` | tool/model/seed/attempt/attachments/observation |
| 叙事/台词 | `docs/card-narrative-contract.md` + `production/narratives/` | 与图像共用身份、独立批准，不写进主插画 |
| 五档配色 | `config/quality-color-tokens.json` | 唯一配色源，不在提示词/Skill 维护第二份色表 |
| 事实层级 | `config/sequence-hierarchy.json` | 事实称谓唯一来源；圣者/天使仍属高序列 |
| Skills 路由 | `.agents/skills/lotm-{foundation,hierarchy,subject,symbols,quality-frames}/SKILL.md` | 三类任务 + 符号 + 品质边框 |

## 约定 CONVENTIONS
- **任务只引用语义**：`semantic_source` 指向 `pathways/<id>/sequences/<09..00>/card.json`；compile 校验 slot/card_id/quality 与 design 指纹，不在本目录维护第二份语义。
- **途径命名空间**：新途径的合同/任务/模板/回执置于 `production/<area>/<pathway>/…`（`<pathway>` 取 `catalog/pathways.json` 的 id）；`fool` 保持现有扁平形态并**显式视为历史形态**，不迁移、不改名、不作为新途径起名模板。详见 `docs/pathway-namespace.md`。
- **五档映射**固定从 `config/quality-color-tokens.json` 解析：low 9–8、mid 7–5、saint 4–3、angel 2–1、true-god 0；quality.visual_tier 必须一致，旧 `high` 不得代替 saint/angel。
- **状态与记录诚实**：每文件标 study/candidate/measured/approved/release，记真实像素/通道/来源/处理链；未知 model/seed 留 null；不冒称原生 2K/4K。
- **原生画布**：Agentic 实际尺寸即 `native_canvas`；中间不转 2K、不裁切回填；只有整卡全部验收后一次全画布采样 2048×3072（收藏 4096×6144，不经 2K）。
- **不可覆盖**：compile 写 `generated/production/`；ingest/compose 等只允许新 run 目录；raw/final/preview/provenance 与历史 receipt 不覆盖。
- **姓名合同**：取 `subject.spec.protagonist.name_zh`；真人物须 character_id、name_status=verified、evidence_refs，原型 archetype 不得冒名；nameplate 只存 rect/font/size/fill/align，字号≥32，不截断不缩字。
- **批准与权益**：production 矢量/层须 approved + by/reference；release 另需 rights_status=cleared；缺真实证据保持 pending。
- **门禁分层**：结构检查≠事实正确≠图像表达清楚；`gate` 默认合成一致性，`--release` 追加 design/release、批准与权益检查。
- **资产接入**：读 catalog 与 receipt.raw；`diagnostic_jobs`、`gaps`、blocked-alpha 不是可用资产；人物插画不算公共物料。
- **历史隔离**：旧四档链（`fool-frame-kit.json`、四档 `quality-frame-*` 合同、`ornate-frame-*`/`four-tiers` 任务与配方、`assets/tiers` 四档矢量）已整体移入 Trash，不再有入口/active/fallback；退役走可恢复 Trash 并留退役账（`production/retirements/`）。

## 反模式 ANTI-PATTERNS
- 不把 task/composition 当语义正本，不用生成结果反推能力事实。
- 不以路径文字代替实际附件；文字 contracts 不计入图像附件；call 不记未实际传递的输入。
- 不用无铭文 2K 底框+局部回填、2K 补字/修框、裁片拼贴当默认交付；失败只回退到最近已过门禁的原生阶段，并按缺陷 owner 局部回退。
- 不扫描目录把 PNG 当可用资产；不把 blocked-alpha 融合稿当透明叠层；不拿愚者原型复制到其余 21 途径充数。
- 不伪造批准/权益/可复现性；不把 alpha 统计、机器 JSON 通过或缩略图当视觉批准。
- 不为位置漂移逐档挪姓名补偿；不静默截断或缩成微字。
- 不重复调用不适配工具试运气；不自动安装/购买/换服务扩大范围。

## 命令 COMMANDS
```bash
# 分层生产（仓库根执行；零第三方依赖，Python 3.10+）
python3 tools/production.py compile production/tasks/foundation-paper.json --out generated/production/paper-v1
python3 tools/production.py ingest generated/production/paper-v1 /absolute/path/to/raw.png production/calls/paper-v1.json --run v001
python3 tools/production.py compose production/compositions/<composition>.json --out artifacts/production/<new-run>
python3 tools/production.py gate artifacts/production/<new-run>
python3 tools/production.py gate artifacts/production/<new-run> --release
# 注意：现存 compositions/*.json 均为历史 pilot 示例，其引用的回执已退役，compose/gate 会按依赖校验失败；
# 当前愚者资产路线见下方的 check-fool-materials。
python3 tools/production.py check-content production/narratives/klein-s09-tingen.json  # --ready-for-audio 拒绝未批准文案
python3 tools/production.py check-fool-audio  # 两张当前 App 卡包的叙事摘要、WAV 与资源白名单
python3 tools/production.py check-fool-materials
python3 tools/production.py check-fool-cards
# 仅在 production/cards/fool-final-sampling-v1.json 写入真实用户视觉批准后执行
python3 tools/production.py finalize production/cards/fool-final-sampling-v1.json --card-id <card_id> --profile standard --out artifacts/production/<new-final-run>
python3 tools/production.py check-final-sample artifacts/production/<new-final-run>/receipt.json

# 回归
python3 -m unittest discover -s tests -p test_production.py -v
python3 -m unittest discover -s tests -p test_symbols_library.py -v
```
