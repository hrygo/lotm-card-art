# 数据契约

card/canon/review采用JSON Schema 2020-12，供编辑器或独立Schema工具检查。
核心运行工具仅用标准库，实施关键结构与跨文件业务规则，并非通用JSON Schema实现。
Schema允许脚手架中的空内容；design/release的事实、语义和图像门槛更严格。
不能把Schema验证成功当作原著核验或艺术审核。

跨途径层级标签统一来自 `config/sequence-hierarchy.json`，结构由 `schemas/sequence-hierarchy.schema.json` 约束。其中 `sequence_levels` 描述当前默认时代的
序列范围，`state_labels` 描述半神、圣者、天使、天使之王等非序列标签；消费者不得把天使之王当作
`sequence=1` 的无条件同义词。

`sequence_zero_card_policy` 明确序列0卡是正式 `sequence_card`，不是特殊事件；卡牌标题仍取具体途径的序列名，
例如愚者途径序列0的标题是“愚者”，二级层级标签是“真神”。

## 单卡字段
semantics是六维唯一表达计划，carrier_ids引用同卡cues；不要在生成的task.md手工维护第二份方案。
claim_refs指向本途径canon.json，断言通过sequences与work_scope限制适用范围。
name_status=verified仍需匹配sequence_name与pathway_name证据；标签不能自行放行。

## 图像与审核
production.artifact含path与sha256；generation记录实际工具、原始图和处理链。
review_file指向按review模板建立的真实审核文件，摘要由fingerprint命令取得。
审核设计摘要排除production流程字段；图像另用SHA256绑定，避免状态更新造成无意义循环。
