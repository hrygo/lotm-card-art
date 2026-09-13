---
name: lotm-hierarchy
description: 为诡秘之主卡牌生产低/中/高/真神层级装饰、边框材质及留白，读取 kind=hierarchy 的结构化任务，经实际生图、观察、登记交给合成器。
---

# 低/中/高/真神层级装饰、边框材质及留白
以当前仓库为根。先读取 docs/production-sop.md、production/schemas/task.schema.json 和当前任务；仅处理 kind=hierarchy。
任务身份、revision、mode、output、references、limits 以及 spec 必须齐全；先运行 tools/production.py compile。
用 tier、geometry、clear_regions 控制层级。图像只提供材质/装饰，核心边界和复合标记保留为矢量。留白、alpha 和背景必须实测；生成棋盘格不算透明。
执行者是当前 Agent；使用已安装 imagegen Skill 的内置图像工具。读取编译 prompt.txt，将每张 reference 作为真实附件传递并注明角色。模型不暴露 seed/model 时记录 null。
观察实际产物，记录观察而非自动评分。需要修复时指出单个缺陷，保持其他不变量；attempt 不超过 limits.max_attempts。编译器不联网、不代替工具执行。
将真实调用参数保存到版本目录；按 production/schemas/call.schema.json 记录 tool/model/seed/created_at/attempt/attachments/observation。
运行 ingest，把真实 PNG 和调用记录保存为不可覆盖的新 run。素材保持 pending，最终批准由用户提供。
最后用 compose 合成并 gate；输出实际路径、原始/最终像素、变换记录、观察结果和剩余门禁。不要把编译成功当作生图成功。

