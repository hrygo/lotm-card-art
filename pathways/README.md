# 22 成神途径与卡牌正典体系 (Canon Base)

本目录是**序列卡牌的正典事实源**：22 条成神途径的断言、配方、扮演法与限制都写在这里，供制卡使用。

它是本仓库（卡牌制作工具）内容层的唯一事实源。若《诡秘世界》产品将来要消费它，只能经 Content Pack 单向读取，不得反向写入或改动卡牌契约（归属见 `docs/DECISIONS.md` D24）。

---

## 目录与卡位结构

- **途径索引**：工作 ID 详见 [`catalog/pathways.json`](../catalog/pathways.json)（涵盖占卜家、学徒、偷盗者、水手、观众等 22 条完整神之途径）。
- **序列卡槽基线**：22 途径 × 10 序列（序列 9 到序列 0）构成了 **220 个基础序列卡槽**。
  > 220 是序列槽位基线（下限），不是卡牌上限。同一序列可容纳多位不同人物的身份卡（如克莱恩、格尔曼·斯帕罗、夏洛克·莫里亚蒂等），同一人物亦可跨多个序列存在独立形象卡。
- **单卡目录约定**：
  ```text
  pathways/<pathway_id>/
  ├── direction.json            # 该途径原创视觉提案
  ├── canon.json                # 该途径已核验的正典断言库（魔药、仪式、能力、扮演守则）
  └── sequences/
      └── <09..00>/
          └── card.json         # 单卡唯一六维结构化设计方案与正典数据源
  ```

---

## 核心设计与内容契约

1. **六维语义契约**：
   每张序列卡必须严格覆盖六大维度：**身份 (Identity) — 扮演 (Acting) — 能力 (Abilities) — 魔药 (Potion) — 晋升 (Advancement) — 限制 (Limitation)**。
   - 误读阻断、载体规范与转译标准详见 👉 [六维语义契约 (design/semantic-contract.md)](../design/semantic-contract.md)。
2. **事实与创作分离**：
   - `canon`：有中文底本支持的原著事实断言；
   - `knowledge_gap`：诚实记录资料缺口，绝不用模型臆测或二手内容填补；
   - `direction`：原创视觉与意象提案，不反推为正典设定。
3. **层级标签系统**：
   严格从 [`config/sequence-hierarchy.json`](../config/sequence-hierarchy.json) 读取低序列 (9–8)、中序列 (7–5)、半神/圣者 (4–3)、天使 (2–1)、天使之王与序列 0 真神定义。

---

## 生产与验证工具链

卡牌内容的检验、任务编译与状态查询工具位于 [`tools/`](../tools/)，纯 Python 3.10+ 标准库实现，零第三方依赖：

```bash
# 验证 22 条途径与 220 序列卡槽骨架完整性
python3 tools/cardctl.py check --level scaffold

# 查看全局 22 途径正典制作状态总览
python3 tools/cardctl.py status

# 编译单卡任务单（以愚者途径序列 9 为例）
python3 tools/cardctl.py brief --card fool:09 --draft

# 视觉出图与分层合成门禁
python3 tools/production.py check-fool-materials
python3 tools/production.py check-fool-cards
```

卡牌视觉分层制作（SOP v3、原生画布、五档边框套件）详见 👉 [分层生产系统 (production/AGENTS.md)](../production/AGENTS.md) 与 [docs/production-sop-v3.md](../docs/production-sop-v3.md)。
