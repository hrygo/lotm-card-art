# Symbol Art Rebuild Implementation Plan

**Goal:** 实际生成22个高精美途径标识，重做愚者数字/融合与四级装饰样板。
**Architecture:** 沿用production编译/ingest与materialctl合成，不改旧程序快照。新增lotm-symbols Skill处理精雕金属基础物料；层级继续lotm-hierarchy。
**Spec:** production/symbols/art-direction.md；当前用户已明确授权实施。

- [x] 核对22途径目录与视觉候选，保存逐项差异brief及结构化task。
- [x] 编译并逐个调用imagegen，实际观察、记录、ingest 22个emblem。
- [ ] 愚者0–9独立艺术数字已完成；9/7/4/0融合造型已生成，但原稿和一次返修均无真实alpha，透明交付未完成。
- [x] 低中高神四个装饰框分别生图，透明度/安全区实測；原要求的大矩形窗口未完全满足，已记录缺陷。
- [x] 途径总览、数字/融合对照及四档空框/姓名试装；可用候选与失败诊断分开登记，原图和接入清单保存。
- [x] 测试、scaffold、技能检查与视觉缺陷报告；不自动批准、不替换正典、不提交或推送。

当前为部分交付：36个真实透明候选，4个融合概念各2次失败记录。详见reports/symbol-art-v1.md；不宣称全部要求通过。
