# Material Library Implementation Plan

> **For agentic workers:** Use executing-plans to implement this plan task-by-task. 当前用户已授权执行，直接在本会话按检查点推进。

**Goal:** 建立可消费的公共物料包和经过真实图像验证的精细合成入口。

**Architecture:** v1文件不变，新增物料研究合成入口复用其资产验证。原图、可编辑结构、配方和诊断分开保存，以摘要关联。

**Tech Stack:** Python标准库、Swift/AppKit/CoreText/ImageIO/CoreImage、内置imagegen。

**Spec:** docs/superpowers/specs/2026-09-13-material-library-design.md

## Global Constraints

- 1000×1500设计坐标；PNG/sRGB；标准2048×3072，收藏4096×6144。
- 不覆写旧输出，不批准美术，不修改客户端或正典。
- 输出material-study不能release；本轮不批量扩展22途径。

## Task 1 — 物料输入与真实资产

Files: production/tasks/material-*.json、production/calls/material-*.json、production/library/。
Consumes: production.compile_task / ingest；Produces: 自包含receipt。
- [x] 编写4个kind=foundation/hierarchy任务，max_attempts=2，明确材质与无字约束。
- [x] `python3 tools/production.py compile ... --out generated/production/...`，读取prompt，经Skill实际调用，观察后ingest；不以文件存在冒充透明合格。

## Task 2 — 有约束的物料接口

Files: tools/materialctl.py、tests/test_materials.py、production/library/README.md。
Consumes: check_asset(root, rel)、validate_shape；Produces: compile_recipe(root, recipe) -> (request, dependencies)。
- [x] 先写反例：`with self.assertRaises(Invalid): compile_recipe(ROOT, invalid_recipe)`，覆盖越界、未知字段、无效锚点、混合及姓名保护。
- [x] `python3 -m unittest discover -s tests -p test_materials.py -v`，确认RED。
- [x] 实现recipe/interface验证、引用摘要、布局解算、render/gate CLI；再运行同命令至GREEN。

## Task 3 — 原生精细渲染

Files: tools/render/materials.swift、tests/test_materials_native.py。
Consumes: 已验证request有序nodes；Produces: final/preview/renderer含alpha诊断。
- [x] 写真实像素测试：中心孔洞露底、羽化部分alpha、multiply结果、矢量前后遮挡、溢出失败。
- [x] 运行测试确认RED；实现遮罩、孔洞、羽化、混合、明暗调整、阴影、文本保护并确认GREEN。
- [x] 不改旧Swift，旧单元测试继续覆盖旧输出。

## Task 4 — 公共组件与四档样板

Files: production/library/components/*.json、production/library/recipes/*.json、production/library/catalog.json（直接列举CLI任务，不新增调度脚本）。
Consumes: 真实receipt/四档结构/十个愚者mark；Produces: 有摘要清单与独立试装输出。
- [x] 设计公共窗口/边带/姓名底座遮罩与四档途径结构，不只增加亮度。
- [x] 生成黑白彩底测试、旧新处理对照、四档独立研究板；主角名仍从现有subject receipt读取。
- [x] 实际观察图像，报告可见缺陷及未验收项，不自动填approved。

## Task 5 — 回归与交付

- [x] `python3 tools/cardctl.py check --level scaffold`
- [x] `python3 -m unittest discover -s tests -v`
- [x] 每个新输出运行material gate；release须失败；旧production gate仍通过。
- [x] `git diff --check`；完成reports/material-library-v1.md与清单。无用户请求，不提交或推送。
