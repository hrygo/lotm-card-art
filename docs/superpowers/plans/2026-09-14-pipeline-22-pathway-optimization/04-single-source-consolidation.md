# 04 · 单一来源去重（五档映射 / 几何 / App 登记表）

> **状态**：Agent 生成提案（非约束、非批准）。父文档：`00-master.md`。优先级 **P1**。依赖：`01`、`02`。

## Goal

消除三类**同一事实存在两份**的重复真相，避免 22 途径下必然发生的漂移。

## 现状证据（三处重复）

### 4.1 五档映射重复
- `production.py:547-553` 内联：`expected_mapping = {low:[9,8], mid:[7,6,5], saint:[4,3], angel:[2,1], true-god:[0]}`
- 而 root `AGENTS.md` 明确：**`config/sequence-hierarchy.json` 是层级标签唯一来源**。
- 判定：单一来源被复制 → 必然漂移。

### 4.2 几何跨语言重复
- `production.py:239-325`：Fool 几何/载体常量（dock 矩形、`pathway_mark`、`pathway_crown`、protected regions…）
- `foolpipeline5.swift`：同一份几何的另一套实现。
- 判定：改一处必漏另一处；22 途径下不可接受。

### 4.3 App 登记表 ↔ 资源目录双真相
- `production.py` 内**硬编码**的卡登记表（card_id / narrative / audio_manifest / audio_root / voice_profile_id / 卡图名）。
- `apps/LotmCardStudio/Resources/{CardArt,Audio}/` 的**实际文件**。
- 判定：两者必须手工人为保持一致；新增卡时是主要出错点（本会话早期 6 例 `App CardArt whitelist` 失败即此面）。

## Must Do

- [ ] **T1 五档映射**：删除 `production.py:547-553`，改为从 `config/sequence-hierarchy.json` 读取并派生 `expected_mapping`；保留「非双射即失败」的断言。
- [x] **T2 几何单一来源**：把 Fool 几何收敛为**合同数据一处**（途径合同或 `templates/` 接口合同），`production.py` 与 `foolpipeline5.swift` 都从该处读取（与 `01-T4` 协同）。
  **实施结果（2026-09-15，ADR-005 选项 C）**：载体合同 `production/symbols/fool-carrier-execution-v1.json` 成为唯一几何声明源并纳入 pin（113 条）；渲染器 13 个几何常量**全部**被合同覆盖并逐项 fail-closed 断言（补入 `illustration_window`、`numeral_exclusion`、`rank_numeral_visible_height_design` 三个锚点 + schema 扩展 + 2 条覆盖用例）；`production.py` 删除重复数值，改结构校验 + 关系不变量。A（渲染器派生 + 渲染前校验 pin）与 B（几何改以接口模板为家，须先修正其陈旧 `gem_slot`）作为可选升级保留在 ADR-005。
- [ ] **T3 登记表消歧**：明确**唯一真相**（建议：登记表仍是声明源），并让门禁校验「登记表 ↔ 资源目录」双向一致：
  - 登记表里每条必须在 `Resources/` 实际存在（已有语义）；
  - `Resources/` 不得出现**未登记**的卡图/音频（新增断言，防止「偷偷加卡绕过门禁」）。
- [ ] **T4 反例测试**：分别构造「映射与 config 不一致」「几何两处不一致」「目录多一个未登记文件」三种反例，断言必须失败。

## Must Not Do

- 不让「以目录为准自动生成登记表」——那会把门禁的声明源变成副作用，等于取消审核入口。
- 不在本任务内改动五档语义本身（`low/mid/saint/angel/true-god` 与 09..00 的绑定不变）。
- 不触碰 `artifacts/**` 与已批准资产。

## 验收标准

- [ ] 删除内联映射后，`check-fool-materials` / `check-fool-cards` / 全套单测**结果不变**。
- [x] 几何改一处 → 渲染器与 Python 校验同步生效（由反例测试证明「两处一致」是被强制的）。
  **措辞修订（ADR-005 选项 C）**：实际达成的是「几何改一处 → 必须同步重封 pin，且渲染器与 Python 的期望被强制一致，不一致即拒绝渲染／门禁失败」——**不是**静默跟随。实测反例：把 `pathway_crown.rect_design[0]` 改成 351 → `pin_seal --check` **rc=1** 并点名该路径与新旧哈希；渲染器侧由 `requireRect`/`requirePoint` 逐项断言同一合同。若要「改一处即生效」，需采用 ADR-005 的 A；其前置（放宽 schema 值级 `const`、修正接口模板陈旧 `gem_slot`）已在该 ADR 列明。
- [ ] 在 `Resources/` 放一个未登记文件 → 门禁**失败**并点名该文件。
- [ ] `python3 tools/cardctl.py check --level scaffold` → `errors: []`。

## 风险与回退

- **风险**：T3 的新断言可能立刻暴露并行写入者的在途卡（未登记资源）→ 会在工作区报错，属**其真实状态**而非回归，需与其协调登记时机。
- **回退**：T1/T2/T3 相互独立，可分别 revert。

## 工作量估计

**小到中**：T1 小；T2 中（跨语言收敛，依赖 01）；T3 中（门禁 + 测试）。