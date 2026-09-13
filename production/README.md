# 分层资产与运行合同

公共物料库与精细合成的最新入口： [library/README.md](library/README.md)，实物与缺口清单为 `library/catalog.json`。v2当前仅作物料试装，不替代v1正式单卡门禁。

从 [SOP](../docs/production-sop.md) 开始。任务类型 foundation / hierarchy / subject 分别由仓库 .agents/skills 中三个 Skill 执行。
schemas 是编辑器契约，tools/production.py 执行同一契约所用的 JSON Schema 子集和跨文件业务门禁。

- tasks：三类完整概念任务示例，可以复制成独立 task_id/revision。
- assets/tiers：四档真实可编辑矢量骨架，status=proposed。
- assets/fool：愚者 0–9 原创复合印记的矢量原型，待视觉批准。
- calls：真实工具调用、观察和附件回执；未知 model/seed 留 null。
- compositions：真实素材、矢量和文字的合成清单。
- artifacts/production（仓库根）：不可覆盖的 raw / final / preview / provenance。

其余 21 条途径继续以 pathways/<id>/direction.json 为提案来源；尚未制作根标识和 0–9 字形，不拿愚者原型复制充数。
语义正本仍在 pathways 的 card/canon，任务只引用。四档层级语义仍由 config/sequence-hierarchy.json 定义。
首版完成生产系统和概念试点，独立卡片可通过只读语义投影做正式门禁；人物特定事实、全套视觉资产批准与正式发行分别推进。

当前模板使用 compositions/fool-09-pilot-named.json 和 fool-09-pilot-named-collector.json：包含必需主角姓名区。旧 pilot 清单保留为历史记录，不符合新增姓名门禁，不作为新任务模板。
姓名来自 subject.spec.protagonist.name_zh；其 character/archetype 类型、名称状态和证据必须随主体任务登记。
