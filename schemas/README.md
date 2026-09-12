# 数据契约

card/canon/review采用JSON Schema 2020-12，供编辑器或独立Schema工具检查。
核心运行工具仅用标准库，实施关键结构与跨文件业务规则，并非通用JSON Schema实现。
Schema允许脚手架中的空内容；design/release的事实、语义和图像门槛更严格。
不能把Schema验证成功当作原著核验或艺术审核。

## 单卡字段
semantics是六维唯一表达计划，carrier_ids引用同卡cues；不要在生成的task.md手工维护第二份方案。
claim_refs指向本途径canon.json，断言通过sequences与work_scope限制适用范围。
name_status=verified仍需匹配sequence_name与pathway_name证据；标签不能自行放行。

## 图像与审核
production.artifact含path与sha256；generation记录实际工具、原始图和处理链。
review_file指向按review模板建立的真实审核文件，摘要由fingerprint命令取得。
审核设计摘要排除production流程字段；图像另用SHA256绑定，避免状态更新造成无意义循环。
