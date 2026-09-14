# 分层资产与运行合同

当前愚者视觉物料入口为 [symbols/fool-five-tier-kit.json](symbols/fool-five-tier-kit.json)，验证命令为 `python3 tools/production.py check-fool-materials`。

从 [SOP](../docs/production-sop-v3.md) 开始。任务类型 foundation / hierarchy / subject 分别由仓库 .agents/skills 中三个 Skill 执行。
schemas 是编辑器契约，tools/production.py 执行同一契约所用的 JSON Schema 子集和跨文件业务门禁。

- tasks：三类完整概念任务示例，可以复制成独立 task_id/revision。
- assets/tiers：旧四档真实可编辑矢量骨架，status=proposed，仅作历史审计。
- assets/fool：愚者 0–9 旧版矢量复合印记原型，仅作历史参考；当前数字圆洞与完整 Agentic 序列框以 symbols 基线为准。
- calls：真实工具调用、观察和附件回执；未知 model/seed 留 null。
- compositions：真实素材、矢量和文字的合成清单。
- artifacts/production（仓库根）：不可覆盖的 raw / final / preview / provenance。

其余 21 条途径继续以 pathways/<id>/direction.json 为提案来源；尚未制作根标识和 0–9 字形，不拿愚者原型复制充数。
语义正本仍在 pathways 的 card/canon，任务只引用。当前五档层级语义由 config/sequence-hierarchy.json 定义；旧四档文档不承担当前映射。
首版完成生产系统和概念试点，独立卡片可通过只读语义投影做正式门禁；人物特定事实、全套视觉资产批准与正式发行分别推进。

`compositions/fool-09-pilot-named.json` 与 `fool-09-pilot-named-collector.json` 是含必需主角姓名区的**历史契约示例**：其引用的 `foundation-paper`、`hierarchy-low` 回执已退役，compose/gate 会按依赖校验失败，不作为当前模板或新任务起点。当前愚者资产路线以 Agentic 五档分层基线为准（`python3 tools/production.py check-fool-materials`）。旧 pilot 清单同样仅作历史记录。
姓名来自 subject.spec.protagonist.name_zh；其 character/archetype 类型、名称状态和证据必须随主体任务登记。
