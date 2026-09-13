---
name: lotm-subject
description: 为诡秘之主卡牌生产单卡人物或非人格主事件插画，读取 kind=subject 的结构化任务，经实际生图、观察、登记交给合成器。
---

# 单卡人物或非人格主事件插画
主角姓名是必填核心输入：读取 spec.protagonist 的 kind/name_zh/name_status/evidence_refs，与 character_id 核对。明确角色保持稳定身份；原型不得擅自改名为原著人物。合成器从此身份生成必需姓名区，不让模型画最终姓名；实际看图要确认姓名、脸部和当前身份一致。
以当前仓库为根。先读取 docs/production-sop.md、production/schemas/task.schema.json 和当前任务；仅处理 kind=subject。
任务身份、revision、mode、output、references、limits 以及 spec 必须齐全；先运行 tools/production.py compile。
先读取 semantic_source、当前途径 AGENTS/canon/direction 与六维设计文档。card_id 与 slot_id 分离；人物跨卡保持 character_id，不能把角色外力或高序列能力提前画入。concept 只交付概念研究样图。production 先通过 cardctl design。
执行者是当前 Agent；使用已安装 imagegen Skill 的内置图像工具。读取编译 prompt.txt，将每张 reference 作为真实附件传递并注明角色。模型不暴露 seed/model 时记录 null。
观察实际产物，记录观察而非自动评分。需要修复时指出单个缺陷，保持其他不变量；attempt 不超过 limits.max_attempts。编译器不联网、不代替工具执行。
将真实调用参数保存到版本目录；按 production/schemas/call.schema.json 记录 tool/model/seed/created_at/attempt/attachments/observation。
运行 ingest，把真实 PNG 和调用记录保存为不可覆盖的新 run。素材保持 pending，最终批准由用户提供。
最后用 compose 合成并 gate；输出实际路径、原始/最终像素、变换记录、观察结果和剩余门禁。不要把编译成功当作生图成功。
