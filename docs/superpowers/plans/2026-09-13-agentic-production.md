# Agentic Production Implementation Plan

**Goal:** 固化三类 Agent 生图输入，并实测技能、素材登记、合成和门禁。
**Architecture:** 复用现有来源卡和 cardctl；新增独立 production task、receipt、composition 契约。合成器为独立 Swift CLI。
**Tech Stack:** Python 3.10+ 标准库；Swift / AppKit / CoreText / ImageIO；JSON；SVG。
**Spec:** ../specs/2026-09-13-agentic-production-design.md

## 执行顺序
- [x] 建立三类任务 schema、完整示例和仓库 Skill；用缺字段/越界/串位反例验证 validate_task。
- [x] 实现 compile / ingest，绑定任务与附件哈希；测试改动依赖后旧快照被阻断。
- [x] 实现 compose 和 Swift 渲染；真实解码、矩形裁切、矢量路径、文字换行及溢出错误。
- [x] 实现 gate，测试概念稿、旧摘要、未批准资产不能发布。
- [x] 使用三个 Skill 分别生成材质、层级装饰、单卡插画；登记实际结果。
- [x] 用组合 manifest 生成标准卡与收藏图；查看缩略图和全图，记录观察及剩余事实缺口。
- [x] 运行新增测试、既有 unittest、scaffold 和 diff 检查，形成交付说明。

## 验收命令
从仓库根执行：
```bash
python3 -m unittest discover -s tests -v
python3 tools/cardctl.py check --level scaffold
python3 tools/production.py --help
```
单卡生产使用 docs/production-sop.md 中的实际 CLI。新增文件与示例不修改现有客户端。
