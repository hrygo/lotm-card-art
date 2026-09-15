# 01 · 渲染器途径化与路径校验缺陷

> **状态**：Agent 生成提案（非约束、非批准）。父文档：`00-master.md`。优先级 **P0**（22 途径头号阻塞）。

## Goal

把 `tools/render/foolpipeline5.swift`（**72 处** fool 耦合、4 个硬编码合同路径）改造为**读「途径生产合同」的通用渲染器**，并修复 `:252-255` 的路径校验缺陷。完成后：新增一条途径 = **加一份合同（数据）**，而不是新增/复制一个渲染器。

## 现状证据

| 位置 | 事实 |
|---|---|
| `foolpipeline5.swift` 全文 | 72 处 fool 引用；Fool 母版/五档/十序列几何与 carrier 名硬编码 |
| `:603` | 硬编码 `production/symbols/fool-carrier-execution-v1.json` |
| `:729` | 硬编码 `production/symbols/fool-five-tier-kit.json` |
| `:1039` | 硬编码 `production/symbols/fool-agentic-sequence-inscriptions-v2.json` |
| `:1049` | 硬编码 `production/symbols/fool-rank-numerals-v1.json` |
| `:252-255` | **缺陷**：`base` 走 `resolvingSymlinksInPath()`，`resolved` 只走 `standardizedFileURL` |
| `production.py:239-325` | 同一份 Fool 几何/载体常量在 Python 侧也有一份（跨语言重复，见 04） |

### 缺陷实测（决定性证据）

```
base      = /var/folders/…/lotm-tag/artifacts/production/        ← root=/private/var 被归一成 /var
standard  = /private/var/folders/…/lotm-tag/artifacts/production/.fool-mother-test-x/mother
hasPrefix = false      → invalid("Output must be a child of artifacts/production") → exit 1
```

同一输入、同一二进制，换成 `root=/var` + `out=/var` 则 `hasPrefix = true` 通过。**后果**：任何位于 `/var/folders`（macOS `$TMPDIR`，所有 CI/sandbox/临时 worktree 的默认位置）下的 checkout，3 例唯一覆盖原生渲染器的测试**必然失败**，且报错误导（像越权写入，实为路径形态）。主仓库在 `/Users/…` 无符号链接 → 绿；CI 无 `swiftc` → skip。**两边都掩盖了它。**

> 更正：本会话早前曾把该现象归因为「依赖被 gitignore 的 `generated/`」。**该归因错误**。输入 PNG 是被跟踪的，手工执行同一命令 `rc=0` 成功。

## Must Do

- [x] **T1 路径校验（最小修复，先做）**：`ensureNewOutput` 两侧使用同一种规范化；并改用**路径分量比较**而非字符串前缀（避免 `/…/production-evil` 之类前缀绕过）。
  ```swift
  let base = root.appendingPathComponent("artifacts/production").standardizedFileURL
  let resolved = output.standardizedFileURL
  // 或两侧都 resolvingSymlinksInPath()；二者必须同源
  ```
- [x] **T1b 反例测试**：符号链接根路径下输出**必须被接受**；`artifacts/production-evil/x` **必须被拒绝**；已存在目录**必须被拒绝**（`Output already exists`）。
- [x] **T2 合同解析层**：把 `:603/:729/:1039/:1049` 的硬编码文件名改为由 `pathway_id` 解析（合同内相对路径或 `production/symbols/<pathway>/…`）。
- [x] **T3 CLI 参数化**：新增 `--pathway`（默认 `fool`），旧调用形式保持可用。
  - 实施记录：四类输入改由「合同 `catalogs` 块声明 + sha256 核对」提供；`--pathway` 置于阶段关键字之前，省略即 `fool`。证据：母版阶段默认模式与 `--pathway fool` 的 9 个产物逐字节一致；合成途径探针用例（`RendererTests.test_pathway_flag_resolves_the_declared_pathway_contract`）断言点名失败且不回退 `fool`。`selftest` 不读合同（纯几何自检），其途径分支即由该探针用例覆盖。
- [x] ~~**T4 几何/载体常量外移**：把渲染器内的途径几何改为读合同（与 04 协同），消除与 `production.py` 的重复。~~ 按 ADR-005「已裁定（分层）」关闭：**愚者保留现状 C**（常量 + fail-closed 等值断言，不事后改造），**新途径采用派生 A**（几何只写合同、渲染器派生且派生先校验 pin、schema 仅结构约束）。

## Must Not Do

- 不改变愚者任一现有输出：`selftest` 标记、manifest、帧图哈希必须与 `v0.3.0` **逐字节一致**（golden 对比）。
- 不删除旧的 `foolpipeline5` 调用分支（历史回执依赖其可复现性）。
- 不在本任务内重画任何视觉资产。

## 验收标准

- [x] `foolpipeline5 selftest` 输出与 `v0.3.0` 一致（golden）。
- [x] `--pathway fool` 与旧命令产出完全等价（哈希比对）。
- [x] 在**符号链接路径**（如 `$TMPDIR/lotm-verify`）下 `python3 -m unittest discover -s tests` **全绿**（不再有 3 例失败）。
- [x] 构造一份最小「第二条途径」合同（可为合成测试数据）能跑通 `selftest` 的途径分支，证明「加合同即可扩展」。

## 风险与回退

- **风险**：渲染器是生产核心；任何行为漂移都会污染后续所有产物。缓解 = T1 独立成批先做、T2–T4 用 golden 保护。
- **回退**：保留旧分支与旧合同名映射；`--pathway` 默认值与旧行为一致。

## 工作量估计

T1 + T1b：**小**（1 处逻辑 + 3 条反例测试）。T2–T4：**中**（涉及渲染器 CLI 与合同读取层，需 golden 回归）。

## 实施记录（2026-09-15 回填）

- **T1/T1b（`2cc99fe`）**：输出路径改「规范化 + 路径分量比较」，弃字符串前缀；反例覆盖 `artifacts/production-evil` 前缀绕过、已存在目录（`Output already exists`）与符号链接根路径必须被接受。
- **T2/T3（`b7bdbfe`）**：四类输入不再硬编码——载体合同路径按命名空间约定解析（`fool` 历史扁平 / 其余 `production/symbols/<pathway>/carrier-execution.json`），五档套装、序列铭刻目录、序列数字目录一律读合同 `catalogs` 块声明并核对 `sha256`；新增 `--pathway <id>`（默认 `fool`，置于阶段关键字之前）。证据：默认模式与 `--pathway fool` 的母版阶段 **9 个产物逐字节一致**；合成途径探针用例断言点名失败（`Carrier catalog changed: rank_numerals`）且**不回退 `fool`**。
- **验收**：`selftest` 与 `v0.3.0` 一致（golden 30/30 逐字节）；符号链接根路径 worktree（`/var/.../T/opencode/lotm-sym-check`，`pwd -P` → `/private/var/...`）下全套件 **OK (skipped=6)**；`selftest` 不读合同，其「途径分支」由上述合成途径探针覆盖。
- **T4 保持未勾选**：按 ADR-005 选项 C 收口（渲染器保留 13 个几何常量 + fail-closed 等值断言），未改为「读合同派生」；选项 A 为可选升级，前置是放宽 schema 中 `gem_slot` 的值级 `const`。
